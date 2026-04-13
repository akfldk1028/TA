---
name: Always Use Math for UI Layout
description: UI 배치할 때 항상 수학적 계산으로 좌표/크기 결정. 하드코딩 금지.
type: feedback
---

UI 요소를 화면에 배치할 때 **항상 수학적으로 계산**해서 화면에 맞출 것.

**Why:** 하드코딩된 radius, offset, angle 값은 특정 화면에서만 맞고 다른 화면에서 잘리거나 넘침. 여러 차례 수정 반복하게 됨. 수학 공식으로 한 번에 해결.

**How to apply:**
- 요소가 화면 안에 들어와야 할 때: 경계 조건을 수식으로 세우고 역산
- 예: arc에서 가장 바깥 카드 x좌표 → `x = center + r * cos(angle)` → `r = (availW/2 - margin) / sin(angle/2)`
- 반응형 레이아웃: 화면 크기 기반 비율이 아니라 **제약 조건 기반 계산**
- 하드코딩 수치 (`availW * 1.2` 같은) 대신 **역산 공식** 사용
- 처음부터 수학적으로 접근하면 시행착오 없이 한 번에 맞음
