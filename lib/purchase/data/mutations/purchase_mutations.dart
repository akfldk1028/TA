import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart' show talker;
import '../../purchase_config.dart';

/// Supabase 구매 이벤트 기록
abstract class PurchaseMutations {
  PurchaseMutations._();

  static Future<void> recordPurchase(CustomerInfo customerInfo) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final premium = customerInfo.entitlements.all[PurchaseConfig.entitlementPremium];
      if (premium?.isActive != true) return;

      String? expiresAt = premium!.expirationDate;

      // 시간제 상품은 구매일+기간으로 계산
      if (expiresAt == null) {
        final pid = premium.productIdentifier;
        final purchaseDate = DateTime.tryParse(premium.latestPurchaseDate);
        if (purchaseDate != null) {
          Duration? duration;
          if (pid == PurchaseConfig.productDayPass) duration = const Duration(hours: 24);
          if (pid == PurchaseConfig.productWeekPass) duration = const Duration(days: 7);
          if (duration != null) expiresAt = purchaseDate.add(duration).toIso8601String();
        }
      }

      await Supabase.instance.client.from('subscriptions').upsert(
        {
          'user_id': userId,
          'product_id': premium.productIdentifier,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'status': 'active',
          'is_lifetime': false,
          'expires_at': expiresAt,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,product_id',
      );
    } catch (e) {
      talker.warning('[PurchaseMutations] 구매 기록 실패: $e');
    }
  }
}
