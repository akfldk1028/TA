---
name: TARO 개발 Advisor 설계 (Claude Code)
description: 이 프로젝트를 개발할 때 쓰는 Claude Code subagent/advisor 체계. 런타임 AI(Qwen)와 무관.
type: project
---

## 스코프 구분 (혼동 금지)

| 계층 | 모델 | 역할 |
|------|------|------|
| **개발 시점** (에디터/CLI) | **Anthropic Claude** (Code, Opus/Sonnet/Haiku) | 코드 작성, 리뷰, 설계, 디버깅 |
| **런타임** (TARO 앱 안) | **Qwen 3.5 Flash** (DashScope) | 타로 해석, FC preflight |

이 문서는 **개발 시점 advisor만** 다룬다. 런타임 AI 파이프라인 변경은 없다.

## 1. Claude Code advisor란

사용자(우리)가 Claude Code CLI 안에서 작업할 때, 메인 어시스턴트가 특정 전문 subagent에게 위임하는 구조. 공식 패턴으로는:

- `Agent` tool + `subagent_type` — 전문 에이전트 호출
- Plugin 기반 advisor — `feature-dev:*`, `code-review-graph:*`, `superpowers:*`
- 사용자 정의 `.claude/agents/*.md` — 프로젝트 전용 advisor

advisor는 **메인 컨텍스트를 보호**하면서 깊은 조사/리뷰/설계를 병렬 수행 → 토큰 절감 + 품질 향상.

## 2. TARO 개발에 배치할 advisor 3종

### 2.1 `taro-architect` (설계 advisor)
- **호출 시점**: 새 Phase/모듈/Edge Function 도입 전
- **투입**: `overview.md`, `harness_design.md`, 해당 영역 소스
- **산출**: 변경 파일 리스트 + 영향 레이어 + 불변식 준수 검증
- **기반**: `feature-dev:code-architect`

### 2.2 `taro-reviewer` (리뷰 advisor)
- **호출 시점**: 구현 완료 직후, 커밋 전
- **투입**: 변경 diff + `harness_design.md` + `feedback/*`
- **산출**: 고신뢰 이슈만 보고 (fabric, logic bug, 불변식 위반)
- **체크 항목**:
  - Phase 직접 할당 있나 (`_setPhase` 우회)
  - AI 스트림을 `yield*` 대신 수집-재emit 했나
  - `DrawCards` 필터 깨졌나
  - UI 좌표 하드코딩 했나
  - Talker 태그 누락
  - purchases_flutter 8.x API (result는 CustomerInfo 자체)
- **기반**: `feature-dev:code-reviewer` 또는 `superpowers:code-reviewer`

### 2.3 `taro-explorer` (탐색 advisor)
- **호출 시점**: 버그 재현 경로 추적, 신규 작업자 온보딩
- **투입**: 증상 + 관련 태그
- **산출**: 로그 태그 → 파일 → 함수 → 호출 체인 맵
- **기반**: `feature-dev:code-explorer` + `harness_design.md` §6 디버깅 순서

## 3. 일상 개발 플로우에서의 advisor 호출 타이밍

```
사용자 요청
    │
    ├─ "새 기능 X 추가" ──────► taro-architect (사전 설계)
    │                                │
    │                                ▼
    │                          메인: 구현 (TDD or 직접)
    │                                │
    │                                ▼
    ├─ "구현 완료, 리뷰해줘" ──► taro-reviewer
    │                                │
    │                                ▼
    ├─ "X가 안 됨, 왜?" ──────► taro-explorer (증상 → 레이어)
    │
    └─ 커밋
```

## 4. advisor 간 경계 (섞지 말 것)

| advisor | 건드려도 되는 것 | 건드리면 안 되는 것 |
|---------|----------------|---------------------|
| architect | 설계 문서, 제안 | 직접 코드 수정 |
| reviewer | diff 분석, 이슈 보고 | 수정 코드 작성 (메인에 반환) |
| explorer | 파일 탐색, 호출 체인 매핑 | 수정, 테스트 실행 |

실제 코드 수정은 **메인 세션에서** — advisor는 판단/탐색만.

## 5. 구현 메모 (즉시 가능)

- 별도 `.claude/agents/taro-*.md` 정의 파일은 **선택 사항** — 당장은 기존 플러그인(`feature-dev:*`, `superpowers:*`, `code-review-graph:*`) 직접 호출로 충분
- 필요성 느낄 때 프로젝트 전용 advisor 파일 추가:
  - 경로: `C:/DK/TA/TA/.claude/agents/taro-reviewer.md` 등
  - frontmatter: `name`, `description`, `tools`, `model`
- 메인 세션 CLAUDE.md에 "구현 완료 시 taro-reviewer 호출" 같은 규칙을 박아두면 자동화됨

## 6. 런타임 advisor는 별도 문제

이 프로젝트의 **런타임 AI**(Qwen 해석 품질)에 advisor tool을 도입하는 건 완전히 다른 주제. 만약 나중에 필요하면:
- 별도 문서 `design/runtime_advisor.md` 생성
- 런타임 advisor는 서버단(Edge Function) 설계 이슈 → 이 문서와 혼동 금지

현재 방침: **런타임은 Qwen 단일 모델 유지**. 개발 advisor만 활용.

## 참고

- Claude Code subagent docs: https://docs.claude.com/en/docs/claude-code/sub-agents
- 사용 가능 플러그인 advisor: `feature-dev:code-architect`, `feature-dev:code-reviewer`, `feature-dev:code-explorer`, `superpowers:code-reviewer`, `code-review-graph:review-delta`, `code-review-graph:review-pr`