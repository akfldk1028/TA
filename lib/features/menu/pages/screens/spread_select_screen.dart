import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/reading_category.dart';
import '../../../../models/spread_type.dart';
import '../../../../router/routes.dart';
import '../../../../shared/widgets/mystical_background.dart';

class SpreadSelectScreen extends StatelessWidget {
  const SpreadSelectScreen({super.key, required this.category});
  final ReadingCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spreads = SpreadType.forCategory(category);

    return Scaffold(
      body: MysticalBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(context, theme),
              // Spread list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  itemCount: spreads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final spread = spreads[index];
                    return _SpreadTile(
                      spread: spread,
                      category: category,
                      onTap: () {
                        context.push(Routes.consultation, extra: {
                          'category': category,
                          'spreadType': spread,
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TaroColors.gold.withAlpha(15)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: TaroColors.gold.withAlpha(180),
            onPressed: () => context.pop(),
          ),
          Icon(category.icon, color: TaroColors.gold.withAlpha(180), size: 20),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'NotoSerifKR',
              color: TaroColors.gold.withAlpha(220),
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpreadTile extends StatelessWidget {
  const _SpreadTile({
    required this.spread,
    required this.category,
    required this.onTap,
  });

  final SpreadType spread;
  final ReadingCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TaroColors.gold.withAlpha(35)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1035), Color(0xFF140B28)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spread.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'NotoSerifKR',
                        fontWeight: FontWeight.w500,
                        color: TaroColors.gold.withAlpha(230),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TaroColors.gold.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TaroColors.gold.withAlpha(40)),
                    ),
                    child: Text(
                      'card_selection.cardCount'.tr(namedArgs: {'count': '${spread.cardCount}'}),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: TaroColors.gold.withAlpha(200),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                spread.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(120),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                spread.positions.join(' \u00b7 '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: TaroColors.gold.withAlpha(100),
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
