import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../main.dart' show talker;
import '../../router/routes.dart';
import '../providers/usage_provider.dart';
import '../purchase_config.dart';

/// 무료 횟수 체크 → 초과 시 결제 유도 다이얼로그.
/// 어디서든 `PurchaseGate.check(context, ref, onAllowed: () { ... })` 호출.
abstract class PurchaseGate {
  static void check(BuildContext context, WidgetRef ref, {required VoidCallback onAllowed}) {
    final remaining = ref.read(dailyUsageProvider).valueOrNull;

    // 프리미엄(null) 또는 남은 횟수 있음
    if (remaining == null || remaining > 0) {
      talker.info('[Gate] 허용 (remaining=$remaining)');
      onAllowed();
      return;
    }

    // 무료 횟수 소진
    talker.info('[Gate] 차단 — 무료 횟수 소진 (remaining=$remaining)');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.auto_awesome, color: TaroColors.gold, size: 22),
          const SizedBox(width: 8),
          Text('purchase.dailyLimitTitle'.tr(),
            style: TextStyle(color: TaroColors.gold, fontFamily: 'NotoSerifKR', fontSize: 18)),
        ]),
        content: Text(
          'purchase.dailyLimitMessage'.tr(namedArgs: {'count': '${PurchaseConfig.freeDailyReadings}'}),
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('purchase.later'.tr(), style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(Routes.paywall);
            },
            child: Text('purchase.goPremium'.tr(),
              style: TextStyle(color: TaroColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
