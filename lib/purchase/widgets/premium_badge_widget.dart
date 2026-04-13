import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/purchase_provider.dart';

/// 골드 PRO 뱃지 + 남은 시간 카운트다운
class PremiumBadgeWidget extends ConsumerStatefulWidget {
  const PremiumBadgeWidget({super.key});

  @override
  ConsumerState<PremiumBadgeWidget> createState() => _PremiumBadgeWidgetState();
}

class _PremiumBadgeWidgetState extends ConsumerState<PremiumBadgeWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(purchaseNotifierProvider);
    final notifier = ref.read(purchaseNotifierProvider.notifier);
    if (!notifier.isPremium) return const SizedBox.shrink();

    final expiresAt = notifier.expiresAt;
    final remainingText = _formatRemaining(expiresAt);
    final isExpiringSoon = notifier.isExpiringSoon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          TaroColors.gold.withAlpha(40),
          TaroColors.gold.withAlpha(20),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TaroColors.gold.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 13, color: TaroColors.gold),
          const SizedBox(width: 3),
          Text('PRO', style: TextStyle(
            color: TaroColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5,
          )),
          if (remainingText != null) ...[
            const SizedBox(width: 5),
            Text(remainingText, style: TextStyle(
              color: isExpiringSoon ? Colors.redAccent.withAlpha(200) : Colors.white54,
              fontSize: 9, fontWeight: FontWeight.w500,
            )),
          ],
        ],
      ),
    );
  }

  String? _formatRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return null;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'purchase.expired'.tr();
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days >= 7) return 'purchase.remainingDays'.tr(namedArgs: {'days': '$days'});
    if (days >= 1) return 'purchase.remainingDaysHours'.tr(namedArgs: {'days': '$days', 'hours': '$hours'});
    if (hours >= 1) return 'purchase.remainingHoursMinutes'.tr(namedArgs: {'hours': '$hours', 'minutes': '$minutes'});
    return 'purchase.remainingMinutes'.tr(namedArgs: {'minutes': '$minutes'});
  }
}
