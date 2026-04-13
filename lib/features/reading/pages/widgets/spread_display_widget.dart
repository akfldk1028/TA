import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/tarot_card_data.dart';
import '../../../../shared/widgets/card_face.dart';
import '../../../../shared/widgets/flip_card.dart';

class SpreadDisplayWidget extends StatelessWidget {
  const SpreadDisplayWidget({
    super.key,
    required this.drawnCards,
    required this.activeCardIndex,
    required this.revealedCards,
    required this.onCardTap,
    required this.isMobile,
    this.initialCardCount,
  });

  final List<DrawnCard> drawnCards;
  final int activeCardIndex;
  final Set<int> revealedCards;
  final ValueChanged<int>? onCardTap;
  final bool isMobile;
  final int? initialCardCount;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final hasAdditional = initialCardCount != null && initialCardCount! < drawnCards.length;
    final mainCards = hasAdditional ? drawnCards.sublist(0, initialCardCount!) : drawnCards;
    final extraCards = hasAdditional ? drawnCards.sublist(initialCardCount!) : <DrawnCard>[];

    final twoRows = mainCards.length > 5;
    final row1 = twoRows ? mainCards.sublist(0, (mainCards.length + 1) ~/ 2) : mainCards;
    final row2 = twoRows ? mainCards.sublist((mainCards.length + 1) ~/ 2) : <DrawnCard>[];

    // 카드 크기: 화면 너비 기준 동적 계산, 최소 36 최대 56
    final maxPerRow = max(1, twoRows ? (mainCards.length + 1) ~/ 2 : mainCards.length);
    final padding = 16.0 + (maxPerRow * 8.0); // container + inter-card
    final cardW = ((screenW - padding) / maxPerRow).clamp(36.0, 56.0);
    final cardH = cardW * 1.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0520), Color(0xFF1A0A2E)]),
        border: Border(bottom: BorderSide(color: Color(0x30D4AF37))),
      ),
      child: Column(
        children: [
          _buildCardRow(row1, 0, cardW, cardH),
          if (row2.isNotEmpty) ...[const SizedBox(height: 4), _buildCardRow(row2, row1.length, cardW, cardH)],
          if (extraCards.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Expanded(child: Divider(color: Color(0x40D4AF37), thickness: 0.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('+', style: TextStyle(color: const Color(0xAAD4AF37), fontSize: 10)),
                ),
                const Expanded(child: Divider(color: Color(0x40D4AF37), thickness: 0.5)),
              ]),
            ),
            _buildCardRow(extraCards, initialCardCount!, cardW, cardH),
          ],
        ],
      ),
    );
  }

  Widget _buildCardRow(List<DrawnCard> cards, int startIndex, double cardW, double cardH) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cards.length, (i) {
        final idx = startIndex + i;
        final drawn = cards[i];
        final isRevealed = revealedCards.contains(idx);
        final isActive = idx == activeCardIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            width: cardW + 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive ? TaroColors.gold.withAlpha(60) : TaroColors.gold.withAlpha(15),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(drawn.position,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: isActive ? TaroColors.gold : TaroColors.gold.withAlpha(100),
                      fontSize: 7, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isActive ? [BoxShadow(color: TaroColors.gold.withAlpha(80), blurRadius: 10)] : null),
                  child: FlipCard(
                    isFlipped: isRevealed,
                    onFlip: onCardTap != null ? () => onCardTap!(idx) : null,
                    size: Size(cardW, cardH),
                    front: CardFace(card: drawn.card, isReversed: drawn.isReversed, size: Size(cardW, cardH)),
                  ),
                ),
                if (isRevealed) ...[
                  const SizedBox(height: 2),
                  Text(drawn.card.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: drawn.isReversed ? Colors.redAccent.shade100 : Colors.white60,
                      fontSize: 7, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
