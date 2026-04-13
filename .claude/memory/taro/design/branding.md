---
name: TARO → ORACLE 브랜딩
description: 앱 이름 ORACLE, 로고(골드 O + 타이포), Nano Banana 생성, 아이콘 규격 완료
type: project
---

## 브랜딩 (2026-04-08)

- **앱 이름**: ORACLE (TARO에서 변경)
- **로고 스타일**: 타이포그래피 — 거대한 골드 "O" + 하단 "ORACLE" 세리프
- **색상**: 골드 (#D4AF37) on 블랙 (#181816)
- **생성 도구**: Nano Banana (Google Gemini Image)
- **원본**: `clone/SJ/frontend/assets/Gemini_Generated_Image_atr5uwatr5uwatr5.png`

### 로고 파일 (assets/logo/)

| 파일 | 용도 |
|------|------|
| `oracle_logo_transparent.png` | 투명 배경 (마케팅, 스플래시, 오버레이) |
| `oracle_logo_ios.png` | iOS용 불투명 |
| `icon_1024.png` | App Store 제출 (불투명 필수) |
| `icon_512.png` | Play Store |
| `icon_192/144/96/72/48.png` | Android dpi별 |
| `ic_launcher_foreground.png` | Android adaptive icon 전경 (투명) |

### 처리 스크립트

`scripts/oracle_logo_prepare.py` — 워터마크 제거, 배경색 샘플링, 둥근 모서리 마스크, 규격별 리사이즈

### 앱 스토어 규칙

- iOS: 1024x1024, 불투명 필수 (투명 → 리젝)
- Android: adaptive icon = 전경(투명) + 배경색(XML)

**Why:** 앱 이름을 ORACLE로 변경하여 글로벌 브랜딩 강화.
**How to apply:** 로고 변경 시 원본 교체 후 `oracle_logo_prepare.py` 재실행.
