---
name: TARO 카테고리별 스프레드 설계
description: 5개 카테고리, P0 7개 스프레드, 모듈형 프롬프트, DrawCards A2UI 자동 트리거
type: project
---

## 설계 확정 (2026-03-29)

스펙: `docs/superpowers/specs/2026-03-29-category-spreads-design.md`

### 카테고리 (5개)
fortune(운세), love(연애), career(진로), general(일반), decision(선택)

### P0 스프레드 (7개)
| 스프레드 | 카드 | 위치 | 카테고리 |
|---------|------|------|---------|
| dailyOne | 1 | 오늘의 메시지 | fortune |
| monthlyForecast | 4 | 테마/도전/기회/조언 | fortune |
| loveThree | 3 | 나/상대/관계 | love |
| hiddenFeelings | 3 | 보여주는 모습/숨기는 마음/진짜 의도 | love |
| careerThree | 3 | 현재/장애물/나아갈 길 | career |
| threeCard | 3 | 과거/현재/미래 | general |
| yesNo | 1 | 답 | decision |

### 핵심 아키텍처
- `ReadingCategory` + `SpreadType` enum 분리 (category → spreads 관계)
- `PromptBuilder`: base + persona + category_ctx + spread_ctx 조립
- `DrawCards` A2UI 컴포넌트: AI가 대화 맥락 파악 → 자동 카드 뽑기 트리거 (1~3장)
- `prompts/` 모듈: 카테고리별 해석 컨텍스트 파일 분리
- 메뉴 → 카테고리 → 스프레드 선택 → 상담 (2depth 네비게이션)
