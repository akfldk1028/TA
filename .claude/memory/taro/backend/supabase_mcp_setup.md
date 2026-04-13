---
name: Supabase MCP 설정 상태
description: TARO Supabase MCP 연결 완료 상태 + Edge Function 배포 정보
type: reference
---

## 현재 상태 (2026-03-27) — 완료

MCP `supabase-taro` 인증 완료. Edge Function 배포 + 테스트 성공.

### 글로벌 MCP 상태
- `supabase` → SJ (`kfciluyxkomskyxjaeat`)
- `supabase-taro` → TARO (`niagjmqffibeuetxxbxp`) ✅ 인증됨

### TARO Supabase 정보
- Project ref: `niagjmqffibeuetxxbxp`
- URL: `https://niagjmqffibeuetxxbxp.supabase.co`
- Anon key: env.json에 저장
- Edge Function: `ai-tarot` v2 (ACTIVE)
- Secrets: `GEMINI_API_KEY` 등록 완료

**How to apply:** TARO 작업 시 `mcp__supabase-taro__*` 도구만 사용. `mcp__supabase__*`는 SJ임.
