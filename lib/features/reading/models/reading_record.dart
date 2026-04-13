import '../../../models/tarot_card_data.dart';

/// A saved reading session for history.
class ReadingRecord {
  ReadingRecord({
    required this.question,
    required this.cards,
    required this.persona,
    required this.timestamp,
  });

  final String question;
  final List<DrawnCard> cards;
  final String persona;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
    'question': question,
    'persona': persona,
    'timestamp': timestamp.toIso8601String(),
    'cards': cards.map((c) => {
      'name': c.card.name,
      'position': c.position,
      'isReversed': c.isReversed,
    }).toList(),
  };
}
