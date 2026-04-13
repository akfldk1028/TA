---
name: TARO 결제 시스템 (IAP)
description: RevenueCat 기반 IAP — 폴더 구조, 상품, Supabase subscriptions, SJ 참조
type: project
---

## 결제 모듈 구현 완료 (2026-04-08)

SJ(만톡) `purchase/` 모듈을 참조하여 TARO에 적응.

### 폴더 구조

```
lib/purchase/
├── purchase.dart              — barrel export
├── purchase_config.dart       — RevenueCat 키, taro_* 상품 ID
├── purchase_service.dart      — Singleton 초기화 + Talker 로깅
├── providers/
│   └── purchase_provider.dart — PurchaseNotifier (@Riverpod, codegen 필요)
├── data/
│   ├── purchase_data.dart
│   ├── queries/purchase_queries.dart
│   └── mutations/purchase_mutations.dart
└── widgets/
    ├── paywall_screen.dart           — 다크/골드 테마 상품 카드
    ├── premium_badge_widget.dart     — 골드 PRO 뱃지 + 카운트다운
    ├── restore_button_widget.dart    — 구매 복원
    └── subscription_manage_screen.dart
```

### 상품 ID

| 상품 | ID | 유형 |
|------|-----|------|
| 1일 이용권 | `taro_day_pass` | 소모성 (24h) |
| 1주 이용권 | `taro_week_pass` | 소모성 (7d) |
| 월간 구독 | `taro_monthly` | 자동갱신 |

### 무료 제한

- `freeDailyReadings = 3` (무료 일일 리딩 3회)

### SJ vs TARO 차이

| 항목 | SJ | TARO |
|------|-----|------|
| 테마 | shadcn_ui + AppThemeExtension | TaroColors (다크/골드) |
| 로깅 | debugPrint + ErrorLoggingService | Talker |
| Product ID | sadam_* | taro_* |
| 광고 | AdMob + Unity | 없음 |

### Supabase

- `subscriptions` 테이블 생성 완료 (RLS: user별 SELECT/INSERT/UPDATE)
- `tarot_daily_usage` 테이블 기존 존재 (86 rows)

### 라우터

- `/premium` → PaywallScreen
- `/subscription` → SubscriptionManageScreen

### i18n

- 17개 언어 `purchase.json` 생성 완료

### 남은 작업

- [ ] RevenueCat 대시보드에서 TARO 앱 생성 → API 키 발급
- [ ] `purchase_config.dart` API 키 업데이트
- [ ] `dart run build_runner build` (purchase_provider.g.dart 생성)
- [ ] Google Play / App Store Connect 상품 등록

**Why:** 수익화 필수. SJ 검증된 패턴 재사용.
**How to apply:** SJ `purchase/` 구조 동일, Talker 로깅 + TaroColors 테마 적용.
