import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../purchase_config.dart';
import '../providers/purchase_provider.dart';
import 'restore_button_widget.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _productOrder = [
    PurchaseConfig.productDayPass,
    PurchaseConfig.productWeekPass,
    PurchaseConfig.productMonthly,
  ];

  static final _productMeta = {
    PurchaseConfig.productDayPass: (icon: Icons.bolt, badge: null, highlight: false),
    PurchaseConfig.productWeekPass: (icon: Icons.star, badge: 'purchase.badgePopular', highlight: true),
    PurchaseConfig.productMonthly: (icon: Icons.diamond_outlined, badge: 'purchase.badgeBest', highlight: false),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final isLoading = purchaseState is AsyncLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      appBar: AppBar(
        title: Text('purchase.title'.tr(), style: TextStyle(color: TaroColors.gold.withAlpha(220))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: TaroColors.gold.withAlpha(180)),
      ),
      body: offeringsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: TaroColors.gold)),
        error: (e, _) => Center(child: Text('purchase.errorLoadProducts'.tr(), style: const TextStyle(color: Colors.white54))),
        data: (offerings) {
          if (offerings?.current == null) {
            return Center(child: Text('purchase.productsLoading'.tr(), style: const TextStyle(color: Colors.white54)));
          }

          final packages = List<Package>.from(offerings!.current!.availablePackages)
            ..sort((a, b) {
              final ai = _productOrder.indexWhere((p) => a.storeProduct.identifier.startsWith(p));
              final bi = _productOrder.indexWhere((p) => b.storeProduct.identifier.startsWith(p));
              return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
            });

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.auto_awesome, size: 48, color: TaroColors.gold),
                const SizedBox(height: 12),
                Text('purchase.premiumPass'.tr(),
                  style: TextStyle(color: TaroColors.gold, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NotoSerifKR'),
                  textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('purchase.premiumSubtitle'.tr(),
                  style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),

                ...packages.map((pkg) {
                  final id = pkg.storeProduct.identifier;
                  final meta = _productMeta.entries
                      .where((e) => id.startsWith(e.key))
                      .map((e) => e.value)
                      .firstOrNull ?? (icon: Icons.shopping_bag, badge: null, highlight: false);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildProductCard(context, ref, pkg, meta, isLoading),
                  );
                }),

                const SizedBox(height: 16),
                const RestoreButtonWidget(),
                const SizedBox(height: 24),
                Text('purchase.termsAutoRenew'.tr(),
                  style: TextStyle(color: Colors.white30, fontSize: 11), textAlign: TextAlign.center),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, WidgetRef ref, Package pkg,
    ({IconData icon, String? badge, bool highlight}) meta, bool isLoading,
  ) {
    final product = pkg.storeProduct;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A2E),
            border: Border.all(
              color: meta.highlight ? TaroColors.gold : TaroColors.gold.withAlpha(40),
              width: meta.highlight ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    TaroColors.gold.withAlpha(100),
                    TaroColors.gold,
                    TaroColors.gold.withAlpha(100),
                  ]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(meta.icon, color: TaroColors.gold, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        product.title.replaceAll(RegExp(r'\s*\(.*\)'), ''),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Text(product.priceString,
                      style: TextStyle(color: TaroColors.gold, fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _handlePurchase(context, ref, pkg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaroColors.gold,
                          foregroundColor: const Color(0xFF0D0520),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                pkg.packageType == PackageType.monthly ? 'purchase.subscribe'.tr() : 'purchase.purchase'.tr(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (meta.badge != null)
          Positioned(
            top: 0, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: TaroColors.gold,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              ),
              child: Text(meta.badge!.tr(),
                style: const TextStyle(color: Color(0xFF0D0520), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Future<void> _handlePurchase(BuildContext context, WidgetRef ref, Package package) async {
    await ref.read(purchaseNotifierProvider.notifier).purchasePackage(package);
    if (!context.mounted) return;
    final notifier = ref.read(purchaseNotifierProvider.notifier);
    if (notifier.isPremium && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
