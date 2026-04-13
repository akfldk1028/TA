---
name: TARO Backend Setup
description: Edge Function ai-tarot v4 (Qwen+FC preflight) + DB 테이블 + Flutter 연동
type: reference
---

## Edge Function: `ai-tarot` v4 (version 11)

- URL: `https://niagjmqffibeuetxxbxp.supabase.co/functions/v1/ai-tarot`
- `verify_jwt: false`
- **모델**: Qwen 3.5 Flash (DashScope 싱가포르)
- **FC preflight**: non-streaming으로 tool_calls 해결 → SSE 스트리밍 반환
- **도구**: get_card_knowledge, get_combination_rules
- 반복 출력 감지 (SJ v36), paragraph repetition check (SJ v105)
- 비용 기록 via `increment_tarot_usage` RPC

## SSE 프로토콜 (변경 없음)

```
data: {"text": "...", "done": false}
data: {"text": "", "done": true, "usage": {"prompt_tokens": N, "completion_tokens": N}}
```

## Edge Function: `seed-knowledge` (일회용 유틸)

- 78장 카드 + 4규칙 DB 삽입용
- POST body: `{ cards: [...], rules: [...] }`
- 사용 후 삭제 가능

## DB 테이블

| 테이블 | 용도 | 비고 |
|--------|------|------|
| `tarot_readings` | 리딩 세션 | RLS: user_id = auth.uid() |
| `tarot_messages` | 채팅 메시지 | FK → tarot_readings |
| `tarot_daily_usage` | 일일 토큰/비용 | UNIQUE user_id+date |
| `tarot_cards` | 78장 카드 지식 (data JSONB) | name으로 조회 |
| `tarot_rules` | 4개 조합 규칙 (slug PK) | slug으로 조회 |

## Supabase Secrets

- `QWEN_API_KEY` — DashScope API 키
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` — 자동 주입

## Flutter 연동

- **패키지**: `supabase_flutter: ^2.8.0`
- **모델**: `ai_config.dart` → `defaultModel = 'qwen3.5-flash'`
- **서비스**: `lib/core/services/supabase_service.dart`
