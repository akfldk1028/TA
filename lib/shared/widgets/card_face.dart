import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/tarot_card_data.dart';

/// Renders the front face of a tarot card.
/// Loads image from Supabase Storage with caching, falls back to styled text.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.card,
    this.isReversed = false,
    this.size = const Size(100, 150),
  });

  final TarotCardData card;
  final bool isReversed;
  final Size size;

  Color get _suitColor => switch (card.suit) {
    'wands' => Colors.orange.shade300,
    'cups' => Colors.blue.shade300,
    'swords' => Colors.grey.shade300,
    'pentacles' || 'coins' => Colors.green.shade300,
    'major' => TaroColors.gold,
    _ => Colors.white70,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1E1E2E),
        border: Border.all(
          color: card.isMajorArcana ? TaroColors.gold : _suitColor,
          width: card.isMajorArcana ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _suitColor.withAlpha(30),
            blurRadius: 8,
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: isReversed ? 2 : 0,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: CachedNetworkImage(
        imageUrl: card.imageUrl,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        placeholder: (_, __) => _buildLoading(),
        errorWidget: (_, __, ___) => _buildFallback(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: size.width * 0.3,
        height: size.width * 0.3,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: TaroColors.gold.withAlpha(120),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: rank/suit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.isMajorArcana ? '${card.rank}' : _rankLabel(),
                style: TextStyle(
                  color: _suitColor,
                  fontSize: size.width * 0.12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                card.suitSymbol,
                style: TextStyle(
                  color: _suitColor,
                  fontSize: size.width * 0.14,
                ),
              ),
            ],
          ),
          // Center: name
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  card.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          // Bottom: suit symbol
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: _suitColor.withAlpha(100),
              fontSize: size.width * 0.18,
            ),
          ),
        ],
      ),
    );
  }

  String _rankLabel() {
    return switch (card.rank) {
      1 => 'A',
      11 => 'Pg',
      12 => 'Kn',
      13 => 'Q',
      14 => 'K',
      _ => '${card.rank}',
    };
  }
}
