---
name: AI 모델 + Tool Calling 설정
description: Qwen 3.5 Flash (DashScope) + FC preflight + tarot-tools (get_card_knowledge, get_combination_rules)
type: reference
---

## AI 모델: Qwen 3.5 Flash

- **모델명**: `qwen3.5-flash`
- **API**: DashScope OpenAI-compatible (싱가포르)
- **Base URL**: `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
- **Secret**: `QWEN_API_KEY` (Supabase Edge Function Secret)
- **가격**: input $0.10/1M, output $0.40/1M
- **변경 이력**: gemini-3-flash → gemini-2.5-flash-lite → **qwen3.5-flash** (2026-04-08)

## Edge Function: ai-tarot v4 (version 11)

**SJ ai-gemini v78 FC preflight 패턴 적용:**

```
1. FC preflight (non-streaming, 최대 5회 루프)
   → tool_choice: "auto"
   → tool_calls 감지 → DB 쿼리 → 결과 주입 → Qwen 재호출
   → 최종 텍스트 답변 확보
2. SSE 스트리밍 반환
   → preflight 답변 있으면 → 50자 청크 SSE 변환
   → 없으면 → 도구 없이 일반 스트리밍
```

## tarot-tools (2개)

| 도구 | 설명 | DB 테이블 |
|------|------|-----------|
| `get_card_knowledge(card_name)` | 카드 상세 해석 (키워드, 상징, 5카테고리 해석) | `tarot_cards` WHERE name |
| `get_combination_rules(rule_type)` | 카드 조합 규칙 (원소 상성, 패턴, 내러티브) | `tarot_rules` WHERE slug |

## Flutter 설정

- `ai_config.dart`: `defaultModel = 'qwen3.5-flash'`
- `ai_client.dart:61`: Edge Function 호출 시 model 파라미터로 전달
- SSE 프로토콜 변경 없음: `data: {"text":"...","done":false}`

## SJ 참조 패턴

- `ref/supabase/functions/ai-gemini/saju-tools/index.ts` — tool 선언 + 실행 패턴
- `ref/supabase/functions/ai-gemini/index.ts:266-379` — FC preflight 핸들링
- `ref/supabase/functions/ai-openai/index.ts:112-114` — DashScope URL + API Key

**Why:** AI가 카드별 정확한 Rider-Waite 의미/상징 참조 → 리딩 품질 대폭 향상
**How to apply:** Edge Function은 supabase-taro MCP로 배포. Flutter 측 변경 불필요 (동일 SSE 프로토콜).
