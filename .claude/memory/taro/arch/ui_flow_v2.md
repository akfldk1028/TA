---
name: TARO UI Flow v2
description: 2026-04-08 — 5-Phase UI, 큰 텍스트 중심, 모듈 위젯, CachedNetworkImage 카드
type: project
---

## UI 플로우 (v2 — 2026-04-08 확정)

1. **Question Phase** — 큰 세리프 텍스트 "그대가 찾고자 하는 지혜의 빛은 무엇인가" + 추천 칩. AI 호출 없음.
2. **PersonaPick Phase** — 사용자 질문 큰 따옴표 + 페르소나 선택 + "카드 뽑기 시작" 버튼. AI 호출 없음.
3. **Picking Phase** — 78장 3줄 카드 팬, 동적 크기 (screenW 기준)
4. **Reading Phase** — SpreadDisplay(상단 30%) + 모드 선택(auto/manual) + 카드별 AI 해석
5. **Chatting Phase** — SpreadDisplay + 자유 대화 + 추가 카드/새 주제 가능

## 위젯 구조

```
lib/features/reading/pages/
├── screens/consultation_screen.dart  — 메인 오케스트레이션 (567줄)
└── widgets/
    ├── question_phase.dart           — 질문 입력
    ├── persona_pick_phase.dart       — 페르소나 선택
    ├── card_fan_widget.dart          — 78장 팬 UI
    ├── spread_display_widget.dart    — 뽑힌 카드 표시 (2행+추가행)
    ├── message_list_widget.dart      — AI 메시지 리스트
    ├── chat_input_field.dart         — 입력 + 마이크
    ├── dramatic_text.dart            — fade+slide 텍스트
    └── persona_selector.dart         — 페르소나 그리드

lib/shared/widgets/
├── card_face.dart      — CachedNetworkImage (Supabase Storage) + fallback
└── flip_card.dart      — 3D 카드 뒤집기 애니메이션
```

## 카드 이미지

- Supabase Storage `tarot-cards` 버킷 (78장 완료)
- `CachedNetworkImage` + loading spinner + 텍스트 fallback
- URL: `{storageBase}/{suit}_{rank:02d}.png`

## 폰트
- NotoSerifKR (세리프, 로컬 번들)

**Why:** AI 호출은 reading phase에서만 — 질문/페르소나는 정적 텍스트로 즉시 반응.
