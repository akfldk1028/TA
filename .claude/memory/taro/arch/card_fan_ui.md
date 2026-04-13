---
name: Card Fan UI Preferences
description: 타로 카드 팬(arc) UI 디자인 — 78장 전체, 3줄, 촘촘 겹침, 수학적 radius 계산으로 절대 잘림 방지
type: feedback
---

카드 팬 UI는 **78장 전체 덱**을 보여줘야 함.

**Why:** 실제 타로 리딩처럼 전체 덱이 테이블에 펼쳐져야 몰입감이 있음. 카드가 화면 밖으로 잘리면 안 됨 — 여러 차례 수정 반복 후 수학적 계산으로 해결.

**How to apply:**
- 78장 카드, **3줄 arc** 배치
- 카드끼리 **촘촘하게 겹침** (겹침 정도 좋음)
- **양쪽 절대 잘리면 안 됨** — radius를 수학적으로 계산:
  ```dart
  final maxRadius = (availW / 2 - cardW) / sin(totalAngle / 2);
  final radius = maxRadius;
  ```
  이 공식이면 가장 바깥 카드가 화면 안에 정확히 들어옴
- `totalAngle: pi * 0.28` (적당한 곡률)
- 카드 크기: 모바일 34×51, 데스크탑 46×69
- **항상 수학적으로 계산해서 화면에 맞추기** — 하드코딩 radius 금지
- UI 배치 관련 작업 시 **항상 수학적으로 좌표를 계산**하고 하드코딩하지 말 것
