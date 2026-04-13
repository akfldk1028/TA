import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/tarot_card_data.dart';

class CardFanWidget extends StatelessWidget {
  const CardFanWidget({
    super.key,
    required this.shuffledCards,
    required this.cardCount,
    required this.selectedIndices,
    required this.requiredCount,
    required this.hoveredIndex,
    required this.fanAnimation,
    required this.onCardSelected,
    required this.onHoverChanged,
    required this.isMobile,
  });

  final List<TarotCardData> shuffledCards;
  final int cardCount;
  final List<int> selectedIndices;
  final int requiredCount;
  final int hoveredIndex;
  final Animation<double> fanAnimation;
  final ValueChanged<int> onCardSelected;
  final ValueChanged<int> onHoverChanged;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (cardCount == 0) {
      return const Center(child: CircularProgressIndicator(color: TaroColors.gold));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final availH = constraints.maxHeight;
      final availW = constraints.maxWidth;
      final cardW = isMobile ? 34.0 : 46.0;
      final cardH = cardW * 1.5;
      final perRow = (cardCount / 3).ceil();
      final row1Count = perRow.clamp(0, cardCount);
      final row2Count = perRow.clamp(0, cardCount - row1Count);
      final row3Count = (cardCount - row1Count - row2Count).clamp(0, cardCount);
      final totalAngle = pi * 0.28;
      final maxRadius = (availW / 2 - cardW) / sin(totalAngle / 2);
      final radius = maxRadius;
      final centerX = availW / 2;
      final startAngle = -pi / 2 - totalAngle / 2;
      final row1CenterY = availH * 0.25 + radius;
      final row2CenterY = availH * 0.50 + radius;
      final row3CenterY = availH * 0.75 + radius;

      return AnimatedBuilder(
        animation: fanAnimation,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(fanAnimation.value.clamp(0.0, 1.0));
          return Stack(
            children: [
              ...List.generate(row1Count, (i) => _buildFanCard(
                index: i, localIndex: i, centerX: centerX,
                centerY: row1CenterY, radius: radius,
                startAngle: startAngle, totalAngle: totalAngle,
                rowCardCount: row1Count, cardW: cardW, cardH: cardH, progress: progress)),
              ...List.generate(row2Count, (i) => _buildFanCard(
                index: row1Count + i, localIndex: i, centerX: centerX,
                centerY: row2CenterY, radius: radius,
                startAngle: startAngle, totalAngle: totalAngle,
                rowCardCount: row2Count, cardW: cardW, cardH: cardH, progress: progress)),
              ...List.generate(row3Count, (i) => _buildFanCard(
                index: row1Count + row2Count + i, localIndex: i, centerX: centerX,
                centerY: row3CenterY, radius: radius,
                startAngle: startAngle, totalAngle: totalAngle,
                rowCardCount: row3Count, cardW: cardW, cardH: cardH, progress: progress)),
            ],
          );
        },
      );
    });
  }

  Widget _buildFanCard({
    required int index, required int localIndex,
    required double centerX, required double centerY,
    required double radius, required double startAngle,
    required double totalAngle, required int rowCardCount,
    required double cardW, required double cardH, required double progress,
  }) {
    final selected = selectedIndices.contains(index);
    final hovered = hoveredIndex == index;
    final t = rowCardCount > 1 ? localIndex / (rowCardCount - 1) : 0.5;
    final angle = startAngle + totalAngle * t;
    final x = centerX + radius * cos(angle) * progress;
    final y = centerY + radius * sin(angle) * progress;
    final rotation = (angle + pi / 2) * progress;
    final liftY = selected ? -20.0 : hovered ? -10.0 : 0.0;

    return Positioned(
      left: x - cardW / 2, top: y - cardH / 2 + liftY,
      child: Transform.rotate(
        angle: rotation,
        child: MouseRegion(
          onEnter: (_) => onHoverChanged(index),
          onExit: (_) => onHoverChanged(-1),
          child: GestureDetector(
            onTap: () => onCardSelected(index),
            child: AnimatedScale(
              scale: hovered && !selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedOpacity(
                opacity: selected ? 0.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: cardW, height: cardH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [hovered ? const Color(0xFF5A3DBF) : const Color(0xFF3D2B79), const Color(0xFF1A0A2E)],
                    ),
                    border: Border.all(
                      color: hovered ? TaroColors.gold : TaroColors.gold.withAlpha(80),
                      width: hovered ? 1.5 : 0.8),
                    boxShadow: [BoxShadow(color: TaroColors.gold.withAlpha(hovered ? 60 : 8), blurRadius: hovered ? 12 : 3)],
                  ),
                  child: Center(child: Icon(Icons.auto_awesome,
                    color: TaroColors.gold.withAlpha(hovered ? 180 : 40), size: cardW * 0.35)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}