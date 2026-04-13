import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/purchase_provider.dart';

class RestoreButtonWidget extends ConsumerWidget {
  const RestoreButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _handleRestore(context, ref),
      child: Text(
        'purchase.restore'.tr(),
        style: TextStyle(
          color: TaroColors.gold.withAlpha(120),
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: TaroColors.gold.withAlpha(120),
        ),
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    await ref.read(purchaseNotifierProvider.notifier).restore();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('purchase.restoreSuccess'.tr())),
      );
    }
  }
}
