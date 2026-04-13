import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/reading_category.dart';
import 'dramatic_text.dart';

class QuestionPhase extends StatelessWidget {
  const QuestionPhase({
    super.key,
    required this.onChipTap,
    required this.category,
  });

  final ValueChanged<String> onChipTap;
  final ReadingCategory category;

  String get _greetingKey => switch (category) {
    ReadingCategory.fortune  => 'reading.fortuneGreeting',
    ReadingCategory.love     => 'reading.loveGreeting',
    ReadingCategory.career   => 'reading.careerGreeting',
    ReadingCategory.general  => 'reading.generalGreeting',
    ReadingCategory.decision => 'reading.decisionGreeting',
  };

  String get _subtitleKey => switch (category) {
    ReadingCategory.fortune  => 'reading.fortuneGreetingSub',
    ReadingCategory.love     => 'reading.loveGreetingSub',
    ReadingCategory.career   => 'reading.careerGreetingSub',
    ReadingCategory.general  => 'reading.generalGreetingSub',
    ReadingCategory.decision => 'reading.decisionGreetingSub',
  };

  String _chipPrefix() => switch (category) {
    ReadingCategory.fortune  => 'reading.fortuneChip',
    ReadingCategory.love     => 'reading.loveChip',
    ReadingCategory.career   => 'reading.careerChip',
    ReadingCategory.general  => 'reading.generalChip',
    ReadingCategory.decision => 'reading.decisionChip',
  };

  static const _chipIcons = <ReadingCategory, List<IconData>>{
    ReadingCategory.fortune: [Icons.calendar_month, Icons.wb_sunny_outlined, Icons.star_outline, Icons.access_time],
    ReadingCategory.love: [Icons.psychology_outlined, Icons.favorite_border, Icons.lock_outline, Icons.people_outline],
    ReadingCategory.career: [Icons.swap_horiz, Icons.trending_up, Icons.explore_outlined, Icons.rocket_launch_outlined],
    ReadingCategory.general: [Icons.remove_red_eye_outlined, Icons.navigation_outlined, Icons.visibility_off_outlined, Icons.psychology_outlined],
    ReadingCategory.decision: [Icons.call_split, Icons.thumbs_up_down, Icons.timer_outlined, Icons.help_outline],
  };

  @override
  Widget build(BuildContext context) {
    final prefix = _chipPrefix();
    final icons = _chipIcons[category]!;
    final chips = List.generate(4, (i) => (
      label: '$prefix${i + 1}'.tr(),
      icon: icons[i],
    ));

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeIn(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TaroColors.gold.withAlpha(25),
                            TaroColors.violet.withAlpha(10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Icon(category.icon, color: TaroColors.gold.withAlpha(200), size: 36),
                    ),
                  ),
                  const SizedBox(height: 44),
                  DramaticText(
                    text: _greetingKey.tr(),
                    fontSize: 32,
                    delay: const Duration(milliseconds: 400),
                  ),
                  const SizedBox(height: 24),
                  DramaticText(
                    text: _subtitleKey.tr(),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: TaroColors.violet.withAlpha(140),
                    delay: const Duration(milliseconds: 900),
                    letterSpacing: 0.8,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Category-specific suggestion chips
        FadeIn(
          delay: const Duration(milliseconds: 1200),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onChipTap(chip.label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: TaroColors.surface.withAlpha(160),
                      border: Border.all(color: TaroColors.gold.withAlpha(35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chip.icon, size: 15, color: TaroColors.gold.withAlpha(140)),
                        const SizedBox(width: 8),
                        Text(chip.label, style: TextStyle(
                          color: TaroColors.gold.withAlpha(200),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        )),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
