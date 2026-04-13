import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based caching for AI responses and reading history.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const String _readingHistoryBox = 'reading_history';
  static const int _maxHistory = 20;

  late Box<Map<dynamic, dynamic>> _history;

  Future<void> init() async {
    _history = await Hive.openBox<Map<dynamic, dynamic>>(_readingHistoryBox);
  }

  // ──── Reading History ────

  /// Save a completed reading.
  Future<void> saveReading({
    required String question,
    required List<Map<String, dynamic>> cards,
    required String persona,
    required DateTime timestamp,
  }) async {
    await _history.add({
      'question': question,
      'cards': cards,
      'persona': persona,
      'timestamp': timestamp.toIso8601String(),
    });

    // Trim to max history
    while (_history.length > _maxHistory) {
      await _history.deleteAt(0);
    }
  }

  /// Get all reading history, most recent first.
  List<Map<String, dynamic>> getHistory() {
    return _history.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        .reversed
        .toList();
  }

  Future<void> clearAll() async {
    await _history.clear();
  }
}
