---
name: TARO Data & API Notes
description: tarot_data.json / tarot_api.json 데이터 구조, 표준화 상태, 주의사항
type: reference
---

## 데이터 파일

### `assets/tarot_data.json` (사용 중)
- 출처: Mark McElroy's _A Guide to Tarot Meanings_
- 78장: 22 major (`suit: "major"`) + 56 minor (wands/cups/swords/pentacles)
- 필드: `name`, `suit`, `rank`, `keywords`, `meanings.light[]`, `meanings.shadow[]`, `fortune_telling[]`
- rank: 숫자(1-10) 또는 문자열(`"page"`, `"knight"`, `"queen"`, `"king"`)
- 2026-03-24 표준화 완료: Title Case 이름, pentacles 통일, Major 이름 RWS 표준

### `assets/tarot_api.json` (미사용)
- 출처: A.E. Waite 원전 설명
- 78장: `name`, `type`, `value_int`, `meaning_up`, `meaning_rev`, `desc` (상세 이미지 설명)
- 이름 차이: `"Fortitude"` (= Strength), `"The Last Judgment"` (= Judgement), `"Wheel Of Fortune"`
- `desc` 필드에 RWS 카드 이미지의 상세 설명이 있어 AI 해석 품질 향상에 활용 가능

## 카드 이미지
- `assets/cards/` — Wikimedia rate limit으로 15/78장만 다운로드
- fallback UI: `card_face.dart`에서 suit 심볼 + 카드 이름으로 대체 렌더링
- 다운로드 스크립트: `tools/download_cards.py`
