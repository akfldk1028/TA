---
name: TARO Code Review Log
description: TARO 1차/2차/3차 코드 리뷰 수정사항 전체 기록
type: project
---

## 1차 리뷰 수정 (구조 리팩터링 전)

| 파일 | 수정 |
|------|------|
| transport.dart | 전체 응답 대기 → JSON 블록 증분 스트리밍 (`_tryEmitNewBlocks`) |
| card_face.dart | 무의미한 `FutureBuilder`/`_imageExists` 제거 → `Image.asset` + `errorBuilder` |
| reading_summary.dart | 동작 안 하던 "New Reading" 버튼 + 미사용 필드(`dispatchEvent` 등) 제거 |
| tarot_card_data.dart | suit 심볼 전통 매핑 (Wands=♣, Swords=♠, Coins=♦) |
| tarot_session.dart | 에러 메시지 raw 노출 → `"The Oracle's vision was clouded"` |
| tarot_catalog.dart | SpreadPicker 카탈로그 등록 (dead code 해소) |
| card_picker.dart | `Random()` 지역변수 → 클래스 필드 `_rng` |
| main.dart | 중복 `mounted` 체크 제거 |

## 구조 리팩터링

- `src/` 플랫 구조 → `features/` + `models/` + `common_widgets/` + `constants/` 모듈형
- `HomeScreen`을 `main.dart`에서 `features/home/`으로 분리
- `TarotMessage`를 `tarot_session.dart`에서 `reading/models/`로 분리
- `tarot_card_data.dart`를 공유 `models/`로 이동 (역방향 의존 해소)

## 데이터 표준화

| 대상 | Before | After |
|------|--------|-------|
| Major #2 | `"The Papess/High Priestess"` | `"The High Priestess"` |
| Major #5 | `"The Pope/Hierophant"` | `"The Hierophant"` |
| Major #10 | `"The Wheel"` | `"Wheel of Fortune"` |
| Minor 56장 | `"ace of wands"` (소문자) | `"Ace of Wands"` (Title Case) |
| Suit | `"coins"` (14장) | `"pentacles"` |

→ `_majorArcana` set과 JSON 데이터 완전 일치 달성

## 2차 리뷰 수정

| 심각도 | 파일 | 수정 |
|--------|------|------|
| High | home_screen.dart | `_loadDeck()` try/catch + 에러 UI + Retry 버튼 |
| High | home_screen.dart | `_loadDeck()` 후 `mounted` 체크 |
| High | reading_screen.dart | 유저 메시지 오른쪽 정렬 + 골드 테두리로 AI와 시각 구분 |
| High | tarot_session.dart | `dispose()`에서 `isProcessing`/`conversation` 리스너 명시적 해제 |
| Medium | tarot_session.dart | 시스템 프롬프트에 `SpreadPicker` 컴포넌트 추가 |
| Medium | tarot_session.dart | 시스템 프롬프트 `Coins` → `Pentacles` 통일 |
| Medium | tarot_session.dart | 불필요한 `dart:async` import 제거 |

## 3차 리뷰 수정 (2026-03-27)

| 심각도 | 파일 | 수정 |
|--------|------|------|
| Critical | Edge Function | `detectRepetition` 정규식 backreference 누락 → `/(.)\\1{19,}/` 수정 |
| High | Edge Function | `increment_tarot_usage` user_id null → DB user_id nullable로 변경 |
| High | tarot_session.dart | `host` force-unwrap → nullable `GenUiHost?` |
| High | tarot_session.dart | `dispose()`에 `_client.dispose()` 추가 |
| High | consultation_screen.dart | `handleCardsDrawn` 중복 호출 → `_cardsSubmitted` 가드 |
| Medium | persona_selector.dart | 한국어 고정 → `context.locale` 기반 ko/en 분기 |
| Low | cache_service.dart | 미사용 응답 캐시 코드 삭제 (createKey, getResponse, putResponse, _cleanExpired) |

## 남은 알려진 이슈 (Low — 수정 안 함)

- `ConsultationScreen` 478줄 — 위젯 분리 권장
- `TarotSession`이 plain ChangeNotifier — Riverpod Provider 전환 권장
- Edge Function 실패 시 GeminiAiClient fallback 없음
- `TarotDeck.shuffled()` 매번 새 Random 생성 — 테스트 불편
