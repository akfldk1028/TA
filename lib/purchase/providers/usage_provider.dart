import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/supabase_service.dart';
import '../../main.dart' show talker;
import '../purchase_config.dart';
import 'purchase_provider.dart';

part 'usage_provider.g.dart';

/// 오늘 남은 무료 리딩 횟수.
/// 프리미엄이면 null (무제한), 무료면 0~3.
@riverpod
Future<int?> dailyUsage(Ref ref) async {
  final purchaseState = ref.watch(purchaseNotifierProvider);
  final notifier = purchaseState.valueOrNull != null
      ? ref.read(purchaseNotifierProvider.notifier)
      : null;

  if (notifier?.isPremium == true) {
    talker.info('[Usage] 프리미엄 → 무제한');
    return null;
  }

  final count = await SupabaseService.instance.getTodayReadingCount();
  final remaining = PurchaseConfig.freeDailyReadings - count;
  talker.info('[Usage] 오늘 사용: $count/${PurchaseConfig.freeDailyReadings}, 남은: $remaining');
  return remaining;
}
