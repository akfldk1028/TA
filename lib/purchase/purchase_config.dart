/// In-App Purchase 설정 상수
///
/// RevenueCat 대시보드에서 발급받은 API 키 및
/// 상품/Entitlement ID 정의
abstract class PurchaseConfig {
  // ── RevenueCat API Keys (대시보드에서 발급) ──
  static const String revenueCatApiKeyAndroid = 'goog_xxx_taro';
  static const String revenueCatApiKeyIos = 'appl_xxx_taro';

  // ── Entitlements ──
  static const String entitlementPremium = 'premium';

  // ── Product IDs ──
  /// 1일 이용권 (소모성, 24시간)
  static const String productDayPass = 'taro_day_pass';

  /// 1주일 이용권 (소모성, 7일)
  static const String productWeekPass = 'taro_week_pass';

  /// 월간 구독 (자동 갱신)
  static const String productMonthly = 'taro_monthly';

  // ── Quota ──
  static const int premiumDailyQuota = 1000000000; // 무제한
  static const int freeDailyReadings = 3;
}
