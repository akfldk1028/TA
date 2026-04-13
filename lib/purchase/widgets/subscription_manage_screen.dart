import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/purchase_provider.dart';
import 'restore_button_widget.dart';

class SubscriptionManageScreen extends ConsumerStatefulWidget {
  const SubscriptionManageScreen({super.key});

  @override
  ConsumerState<SubscriptionManageScreen> createState() => _SubscriptionManageScreenState();
}

class _SubscriptionManageScreenState extends ConsumerState<SubscriptionManageScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    final isPremium = notifier.isPremium;
    final planName = notifier.activePlanName;
    final expiresAt = notifier.expiresAt;
    final isExpiringSoon = notifier.isExpiringSoon;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      appBar: AppBar(
        title: Text('purchase.subscriptionManage'.tr(), style: TextStyle(color: TaroColors.gold.withAlpha(220))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: TaroColors.gold.withAlpha(180)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TaroColors.gold.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Icon(
                    isPremium ? Icons.workspace_premium : Icons.lock_outline,
                    size: 48,
                    color: isPremium ? (isExpiringSoon ? Colors.orange : TaroColors.gold) : Colors.white30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPremium ? 'purchase.premiumActive'.tr() : 'purchase.freePlan'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (planName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: TaroColors.gold.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(planName, style: TextStyle(color: TaroColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 남은 시간
            if (isPremium && expiresAt != null) ...[
              _buildTimeCard(expiresAt, isExpiringSoon),
              const SizedBox(height: 20),
            ],

            // 만료 경고
            if (isExpiringSoon) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withAlpha(60)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text('purchase.expiryWarningMessage'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12))),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            const RestoreButtonWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(DateTime expiresAt, bool isExpiringSoon) {
    var remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) remaining = Duration.zero;
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    String text;
    if (days > 0) {
      text = '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      text = '${hours}h ${minutes}m';
    } else {
      text = '${minutes}m';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TaroColors.gold.withAlpha(40)),
      ),
      child: Column(children: [
        Icon(Icons.timer_outlined, color: isExpiringSoon ? Colors.redAccent : TaroColors.gold, size: 28),
        const SizedBox(height: 10),
        Text(text, style: TextStyle(
          color: isExpiringSoon ? Colors.redAccent : Colors.white,
          fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
