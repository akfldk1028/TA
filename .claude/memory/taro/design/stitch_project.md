---
name: ORACLE Stitch 디자인 프로젝트
description: Stitch MCP 프로젝트 ID, 디자인 시스템 ID, 생성된/미생성 화면 목록
type: reference
---

## Stitch 프로젝트

- **프로젝트 ID**: `1152837382881615120`
- **프로젝트명**: ORACLE - AI Tarot Reading App
- **디자인 시스템**: `assets/12570569722888906626` (ORACLE Dark Gold)

## 디자인 시스템 설정

- colorMode: DARK
- headlineFont: EB_GARAMOND (세리프)
- bodyFont: INTER
- customColor: #D4AF37 (골드)
- secondary: #2D1B69, tertiary: #4A1B3D, neutral: #1A0A2E
- roundness: ROUND_TWELVE
- colorVariant: FIDELITY

## 화면 상태

| 화면 | 상태 | Screen ID |
|------|------|-----------|
| Splash | ✅ 완료 | `527ed8b23988402fa8c4ed7d9a192269` |
| Main Menu | ❌ 미생성 (서버 타임아웃) | — |
| Paywall (결제) | ❌ 미생성 (서버 타임아웃) | — |
| Card Reading | ❌ 미생성 | — |
| Question Phase | ❌ 미생성 | — |
| Persona Pick | ❌ 미생성 | — |

## 재시도 시 프롬프트

**Main Menu:**
Home screen with 5 category cards for ORACLE tarot app. Dark theme, gold accents, hero card for daily reading, PRO badge.

**Paywall:**
Premium paywall with 3 product cards (day/week/monthly). Dark bg, gold buttons, Popular/Best Value badges.

**Card Reading:**
Tarot card spread display with flipped/unflipped cards, AI interpretation messages, dark mystical theme.

**How to apply:** `mcp__stitch__generate_screen_from_text` 호출 시 projectId=1152837382881615120 사용.
