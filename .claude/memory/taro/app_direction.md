---
name: TARO App Direction
description: TARO 앱 방향성 — 메인 페이지 역할, 향후 다른 앱 모듈 추가 예정, A2UI 앱 번들 전략
type: project
---

TARO는 A2UI 기반 앱 번들의 메인(첫 번째) 앱.

**Why:** 사용자가 여러 A2UI 앱을 모듈로 만들 예정이며, TARO가 첫 번째 완성 앱.

**How to apply:**
- TARO의 현재 구조(features/ 모듈형)를 다른 앱 모듈의 기본 패턴으로 참고
- A2UI SDK(genui)는 pub.dev 의존(^0.7.0)으로 유지 — 로컬 path 의존 불필요
- 향후 다른 앱이 추가될 때 같은 features/ 패턴 적용
- env.json + --dart-define-from-file로 API 키 관리 (gitignored)
