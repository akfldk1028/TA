import 'dart:io' show Platform;

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show talker;
import 'purchase_config.dart';

/// RevenueCat 초기화 및 핵심 메서드 (Singleton)
class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _initialized && _available;

  Future<void> initialize() async {
    if (_initialized) return;

    final apiKey = Platform.isIOS
        ? PurchaseConfig.revenueCatApiKeyIos
        : PurchaseConfig.revenueCatApiKeyAndroid;

    if (apiKey.isEmpty || apiKey.startsWith('appl_xxx') || apiKey.startsWith('goog_xxx')) {
      _initialized = true;
      _available = false;
      talker.info('[Purchase] API 키 미설정 → IAP 비활성화');
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      _initialized = true;
      _available = true;
      talker.info('[Purchase] RevenueCat 초기화 완료 (userId: $userId)');
    } catch (e) {
      _initialized = true;
      _available = false;
      talker.error('[Purchase] RevenueCat 초기화 실패', e);
    }
  }

  Future<void> syncUserId() async {
    if (!_available) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final info = await Purchases.getCustomerInfo();
      final currentId = info.originalAppUserId;
      if (!currentId.startsWith('\$RCAnonymousID')) return;

      await Purchases.logIn(userId);
      talker.info('[Purchase] syncUserId: $currentId → $userId');
    } catch (e) {
      talker.warning('[Purchase] syncUserId 실패: $e');
    }
  }
}
