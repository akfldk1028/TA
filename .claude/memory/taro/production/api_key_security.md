---
name: env.json / API Key 관리 — commit 시 diff 확인이 주 조치
description: env.json gitignored. rotate/restriction 보류. push 전 AIzaSy 검색 습관 유지
type: production
---

# API Key 관리 방침

## 원칙

- `env.json` 은 `.gitignore` 1행에 등록되어 저장소 유출 차단됨.
- **push 전 diff 확인이 유일한 필수 조치**.
- 코드/문서/메모리에 키 값 하드코딩 금지 (이름만 기록).
- Supabase `service_role` key 는 클라이언트 어디에도 넣지 말 것. anon key 만 사용 (RLS 로 보호).

## 2026-04-16 GEMINI_API_KEY 이슈 (해결: 조치 없음)

- `env.json` selection 으로 대화에 노출 → Claude Code 세션 로그 `~/.claude/projects/<slug>/*.jsonl` 4개에 평문 저장.
- 저장소/git/메모리 파일엔 값 없음.
- 실제 외부 유출 경로 없음 → **rotate/restriction 보류**.
- 재발 시에도 같은 기준 적용.

## push 전 체크 (3초)

```bash
git diff --cached | grep -i "AIzaSy\|sk-\|Bearer " | head
```

매치 나오면 언스테이지 + 원인 파일 gitignore 확인.

## rotate 가 실제 필요한 시점

- public repo/PR/Issue 에 키 노출 흔적 발견.
- Cloud Console 에서 비정상 호출 감지.
- 외부 제3자 서비스 로그로 흘러간 정황.

그때 절차: aistudio.google.com → 새 키 + Android restriction(`com.clickaround.oracle`) → `env.json` 교체(에디터 직접) → 구 키 Delete.

## 하지 말 것

- rotate 자동반사 — 실제 유출 경로 평가 후 결정.
- debug SHA-1 매번 얻어오기 — Android restriction 을 현재 안 쓰는 이유.
- Supabase `service_role` key 를 `env.json` 에 넣기 — 넣는 순간 클라 빌드에 포함됨.
