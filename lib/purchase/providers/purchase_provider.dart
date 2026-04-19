import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../main.dart' show talker;
import '../data/mutations/purchase_mutations.dart';
import '../purchase_config.dart';
import '../purchase_service.dart';

part 'purchase_provider.g.dart';

@Riverpod(keepAlive: true)
class PurchaseNotifier extends _$PurchaseNotifier {
  bool _forcePremium = false;
  String? _forcePremiumProductId;
  DateTime? _forcePremiumActivatedAt;

  @override
  Future<CustomerInfo> build() async {
    if (!PurchaseService.instance.isAvailable) {
      talker.info('[Purchase] IAP 비활성화 → isPremium=false');
      throw Exception('IAP not available');
    }

    Purchases.addCustomerInfoUpdateListener((info) {
      talker.info('[Purchase] CustomerInfo 실시간 업데이트');
      state = AsyncData(info);
    });

    final info = await Purchases.getCustomerInfo();
    talker.info('[Purchase] build() 초기 로드 — entitlements: ${info.entitlements.all.keys.toList()}, subs: ${info.activeSubscriptions}');
    return info;
  }

  bool get isPremium => _checkPremium().$1;

  (bool, String) _checkPremium() {
    final info = state.valueOrNull;
    if (info == null) return (_forcePremium, 'forcePremium=$_forcePremium (no info)');

    // 1차: entitlement (구독만 신뢰)
    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true) {
      final pid = entitlement!.productIdentifier;
      final isTimeLimited = pid == PurchaseConfig.productDayPass ||
          pid == PurchaseConfig.productWeekPass;
      if (!isTimeLimited) return (true, 'entitlement:$pid');
    }

    // 2차: 활성 구독
    if (info.activeSubscriptions.contains(PurchaseConfig.productMonthly)) {
      return (true, 'activeSub:monthly');
    }

    // 3차: 비구독 상품 (시간 기반)
    final now = DateTime.now();
    for (final tx in info.nonSubscriptionTransactions) {
      final purchaseDate = DateTime.tryParse(tx.purchaseDate);
      if (purchaseDate == null) continue;

      Duration? duration;
      if (tx.productIdentifier == PurchaseConfig.productDayPass) duration = const Duration(hours: 24);
      if (tx.productIdentifier == PurchaseConfig.productWeekPass) duration = const Duration(days: 7);

      if (duration != null && now.isBefore(purchaseDate.add(duration))) {
        return (true, 'timeBased:${tx.productIdentifier}');
      }
    }

    // 4차: forcePremium fallback
    if (_forcePremium && _forcePremiumActivatedAt != null) {
      Duration? duration;
      if (_forcePremiumProductId == PurchaseConfig.productDayPass) duration = const Duration(hours: 24);
      if (_forcePremiumProductId == PurchaseConfig.productWeekPass) duration = const Duration(days: 7);
      if (_forcePremiumProductId == PurchaseConfig.productMonthly) duration = const Duration(days: 35);
      if (duration != null && DateTime.now().isAfter(_forcePremiumActivatedAt!.add(duration))) {
        _forcePremium = false;
        return (false, 'forcePremium expired');
      }
      return (true, 'forcePremium:$_forcePremiumProductId');
    }
    return (false, 'free');
  }

  DateTime? get expiresAt {
    final info = state.valueOrNull;
    if (info == null) return null;

    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true && entitlement!.expirationDate != null) {
      final pid = entitlement.productIdentifier;
      final isTimeLimited = pid == PurchaseConfig.productDayPass || pid == PurchaseConfig.productWeekPass;
      if (!isTimeLimited) return DateTime.tryParse(entitlement.expirationDate!);
    }

    DateTime? latestExpiry;
    for (final tx in info.nonSubscriptionTransactions) {
      final purchaseDate = DateTime.tryParse(tx.purchaseDate);
      if (purchaseDate == null) continue;
      Duration? duration;
      if (tx.productIdentifier == PurchaseConfig.productDayPass) duration = const Duration(hours: 24);
      if (tx.productIdentifier == PurchaseConfig.productWeekPass) duration = const Duration(days: 7);
      if (duration != null) {
        final expiry = purchaseDate.add(duration);
        if (latestExpiry == null || expiry.isAfter(latestExpiry)) latestExpiry = expiry;
      }
    }
    return latestExpiry;
  }

  String? get activePlanName {
    if (!isPremium) return null;
    final info = state.valueOrNull;
    if (info == null) return null;

    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true) {
      final pid = entitlement!.productIdentifier;
      if (pid == PurchaseConfig.productMonthly) return 'purchase.planMonthly'.tr();
      if (pid == PurchaseConfig.productWeekPass) return 'purchase.planWeekPass'.tr();
      if (pid == PurchaseConfig.productDayPass) return 'purchase.planDayPass'.tr();
    }
    return 'purchase.planPremium'.tr();
  }

  bool get isExpiringSoon {
    final expiry = expiresAt;
    if (expiry == null) return false;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return false;
    return remaining.inHours < 24;
  }

  int get dailyQuota => isPremium ? PurchaseConfig.premiumDailyQuota : PurchaseConfig.freeDailyReadings;
  bool get showAds => !isPremium;

  Future<void> purchasePackage(Package package) async {
    state = const AsyncLoading();
    try {
      final result = await Purchases.purchasePackage(package);
      state = AsyncData(result);
      await PurchaseMutations.recordPurchase(result);
      final (premium, reason) = _checkPremium();
      talker.info('[Purchase] 구매 완료: ${package.storeProduct.identifier} → isPremium=$premium ($reason)');

      // entitlement 미반영 시 재시도
      if (result.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive != true) {
        for (int i = 1; i <= 3; i++) {
          await Future.delayed(Duration(seconds: i));
          final latest = await Purchases.getCustomerInfo();
          if (latest.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive == true) {
            state = AsyncData(latest);
            return;
          }
        }
        // 3회 실패 → forcePremium
        _forcePremium = true;
        _forcePremiumProductId = package.storeProduct.identifier;
        _forcePremiumActivatedAt = DateTime.now();
        talker.warning('[Purchase] entitlement 미반영 → forcePremium');
      }
    } on PlatformException catch (e, st) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        _forcePremium = true;
        _forcePremiumProductId = package.storeProduct.identifier;
        _forcePremiumActivatedAt = DateTime.now();
        try {
          state = AsyncData(await Purchases.restorePurchases());
        } catch (_) {
          state = AsyncData(await Purchases.getCustomerInfo());
        }
      } else if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        state = AsyncData(await Purchases.getCustomerInfo());
      } else {
        talker.error('[Purchase] 구매 실패', e, st);
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> restore() async {
    final previous = state.valueOrNull;
    try {
      state = AsyncData(await Purchases.restorePurchases());
      talker.info('[Purchase] 구매 복원 완료');
    } catch (e, st) {
      talker.error('[Purchase] 복원 실패', e, st);
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> refresh() async {
    if (!PurchaseService.instance.isAvailable) return;
    final previous = state.valueOrNull;
    try {
      state = AsyncData(await Purchases.getCustomerInfo());
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  bool get isIapAvailable => PurchaseService.instance.isAvailable;
}

@riverpod
Future<Offerings?> offerings(Ref ref) async {
  if (!PurchaseService.instance.isAvailable) return null;
  try {
    return await Purchases.getOfferings();
  } catch (e) {
    talker.warning('[Purchase] offerings 조회 실패: $e');
    return null;
  }
}
