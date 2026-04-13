import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class TarotCardData {
  const TarotCardData({
    required this.name,
    required this.suit,
    required this.rank,
    required this.keywords,
    required this.uprightMeanings,
    required this.reversedMeanings,
  });

  final String name;
  final String suit; // "major", "wands", "cups", "swords", "pentacles"
  final int rank;
  final List<String> keywords;
  final List<String> uprightMeanings;
  final List<String> reversedMeanings;

  bool get isMajorArcana => suit == 'major';

  static const String _storageBase =
      'https://niagjmqffibeuetxxbxp.supabase.co/storage/v1/object/public/tarot-cards';

  String get imageUrl =>
      '$_storageBase/${suit}_${rank.toString().padLeft(2, '0')}.png';

  String get suitSymbol {
    return switch (suit) {
      'wands' => '\u2663',
      'cups' => '\u2665',
      'swords' => '\u2660',
      'pentacles' || 'coins' => '\u2666',
      'major' => '\u2726',
      _ => '\u2605',
    };
  }

  static int _parseRank(Object? value) {
    if (value is int) return value;
    return switch (value) {
      'page' => 11,
      'knight' => 12,
      'queen' => 13,
      'king' => 14,
      _ => int.tryParse(value.toString()) ?? 0,
    };
  }

  factory TarotCardData.fromJson(Map<String, dynamic> json) {
    final meanings = json['meanings'] as Map<String, dynamic>;
    return TarotCardData(
      name: json['name'] as String,
      suit: json['suit'] as String,
      rank: _parseRank(json['rank']),
      keywords: (json['keywords'] as List).cast<String>(),
      uprightMeanings: (meanings['light'] as List).cast<String>(),
      reversedMeanings: (meanings['shadow'] as List).cast<String>(),
    );
  }
}

class DrawnCard {
  const DrawnCard({
    required this.card,
    required this.position,
    required this.isReversed,
  });

  final TarotCardData card;
  final String position; // "Past", "Present", "Future", etc.
  final bool isReversed;
}

class TarotDeck {
  TarotDeck(this.cards);

  final List<TarotCardData> cards;

  List<TarotCardData> shuffled() {
    final copy = List<TarotCardData>.from(cards);
    copy.shuffle(Random());
    return copy;
  }

  /// Find card by name (case-insensitive).
  TarotCardData? findByName(String name) {
    final lower = name.toLowerCase().trim();
    return cards.cast<TarotCardData?>().firstWhere(
      (c) => c!.name.toLowerCase() == lower,
      orElse: () => null,
    );
  }

  /// Singleton for lookups after first load.
  static TarotDeck? _instance;
  static TarotDeck? get instance => _instance;

  static Future<TarotDeck> load() async {
    final jsonStr = await rootBundle.loadString('assets/tarot_data.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final interpretations = data['tarot_interpretations'] as List;
    final cards = interpretations
        .map((e) => TarotCardData.fromJson(e as Map<String, dynamic>))
        .toList();
    final deck = TarotDeck(cards);
    _instance = deck;
    return deck;
  }
}
