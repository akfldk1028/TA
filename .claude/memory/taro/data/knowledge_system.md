---
name: 타로 지식 시스템
description: 78장+4규칙 DB 삽입 완료, ai-tarot v4 FC preflight tool calling으로 AI 연동
type: reference
---

## 지식 파일 (로컬)

```
clone/TARO/knowledge/tarot/
├── major/     22장 (00_fool ~ 21_world)
├── wands/     14장 (01_ace ~ 14_king) — Fire
├── cups/      14장 (01_ace ~ 14_king) — Water
├── swords/    14장 (01_ace ~ 14_king) — Air
├── pentacles/ 14장 (01_ace ~ 14_king) — Earth
└── rules/     4파일 (elemental_dignities, combination_patterns, narrative_flow, suit_overview)
```

## DB (Supabase tarot_cards / tarot_rules)

- `tarot_cards`: 78장 전부 `data` JSONB 컬럼에 삽입 완료
  - 기존 테이블(id int, name, suit, rank, image_url 등)에 `data` JSONB + `card_id` TEXT 추가
  - name으로 조회 (예: `WHERE name = 'The Fool'`)
  - **주의**: pentacles는 DB에서 원래 "Coins"였으나 "Pentacles"로 수정됨
- `tarot_rules`: 4개 규칙 slug 기반 조회

## AI Tool Calling 연동

ai-tarot Edge Function v4 (version 11)에서 FC preflight 방식으로 연동:

1. Qwen이 카드 해석 시 `get_card_knowledge(card_name)` tool_call 발생
2. Edge Function이 DB에서 조회하여 결과 반환
3. Qwen이 지식 참고하여 최종 답변 생성
4. SSE 스트리밍으로 클라이언트에 전달

**도구 2개:**
- `get_card_knowledge(card_name)` — tarot_cards WHERE name 조회
- `get_combination_rules(rule_type)` — tarot_rules WHERE slug 조회

**Why:** AI가 카드별 상세 의미/상징/해석을 정확하게 참조하여 리딩 품질 향상
**How to apply:** Edge Function은 supabase-taro MCP로 배포. DB 데이터 갱신 시 seed-knowledge 함수 활용.
