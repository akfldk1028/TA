---
name: TARO 하네스 + Talker 로그 태그 맵
description: 하네스 구현 + 전체 Talker 로그 태그 정리 — 디버깅/추적 시 이 파일 참조
type: reference
---

## 하네스 설계 (Harness Design)

Anthropic, OpenAI, Martin Fowler 등이 정립한 AI 에이전트 오케스트레이션 인프라.

### 구현 완료 (2026-04-08)

- [x] Phase 전환 가드: `_setPhase()` + `_validTransitions` 맵
- [x] AI retry + fallback: `RetryAiClient` (yield* 스트리밍 보존)
- [x] 에러 메시지 `isError` 플래그
- [x] Talker 글로벌 인스턴스 + TalkerRiverpodObserver

## Talker 로그 태그 맵

디버깅/추적 시 태그로 필터링:

### 상담 플로우 (하네스)

| 태그 | 파일 | 추적 내용 |
|------|------|----------|
| `[TarotSession]` | providers/tarot_session.dart | Phase 전환 (`→`), 무효 전환 경고, AI 에러 |
| `[Transport]` | services/transport.dart | A2UI JSON 파싱, 컴포넌트 emit/drop, 90s 타임아웃 |
| `[EdgeFunction]` | services/ai_client.dart | SSE 파싱 실패, 45s 스트림 타임아웃 |
| `[RetryAiClient]` | services/ai_client.dart | retry 시도, fallback 전환 |

### 결제 시스템

| 태그 | 파일 | 추적 내용 |
|------|------|----------|
| `[Purchase]` | purchase_service.dart, purchase_provider.dart | 초기화, 구매 완료/실패, 복원, entitlement 판정 근거, forcePremium |
| `[PurchaseQueries]` | data/queries/ | Supabase 구독 조회 실패 |
| `[PurchaseMutations]` | data/mutations/ | Supabase 구매 기록 실패 |
| `[Usage]` | providers/usage_provider.dart | 오늘 사용량/남은 횟수, 프리미엄 무제한 |
| `[Gate]` | widgets/purchase_gate.dart | 허용/차단 판정 (remaining 값 포함) |

### 자동 (TalkerRiverpodObserver)

모든 Riverpod Provider의 생성/해제/상태변경 자동 로깅 (main.dart에서 등록).

## 로그 활용 예시

- **결제 문제**: `[Purchase]` 필터 → 구매 시도 → entitlement 판정 근거 → forcePremium 여부
- **무료 횟수 문제**: `[Usage]` + `[Gate]` → 사용량 조회 → 차단/허용 판정
- **AI 응답 문제**: `[Transport]` + `[EdgeFunction]` → JSON 파싱 → 타임아웃
- **Phase 전환 문제**: `[TarotSession]` → 유효/무효 전환 로그
- **retry/fallback**: `[RetryAiClient]` → primary 실패 → retry → fallback 전환

## isPremium 판정 로직 (purchase_provider.dart)

`_checkPremium()` → `(bool, String reason)` 반환:
1. entitlement (구독만 신뢰, 시간제 제외) → `entitlement:{pid}`
2. activeSubscriptions (monthly) → `activeSub:monthly`
3. nonSubscriptionTransactions (시간 기반) → `timeBased:{pid}`
4. forcePremium fallback → `forcePremium:{pid}`
5. 없음 → `free`

**How to apply:** 로그 추적 시 이 태그 맵 참조. 새 모듈 추가 시 `[태그]` 형식으로 talker 로그 추가할 것.
