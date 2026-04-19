import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/ai_config.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final _log = Logger('SupabaseService');
  bool _initialized = false;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    if (_initialized) return;
    if (!AiConfig.useEdgeFunction) {
      _log.info('Supabase not configured — skipping init');
      return;
    }
    await Supabase.initialize(
      url: AiConfig.supabaseUrl,
      anonKey: AiConfig.supabaseAnonKey,
    );
    _initialized = true;
    _log.info('Supabase initialized');
    await _ensureAnonAuth();
  }

  Future<void> _ensureAnonAuth() async {
    final session = client.auth.currentSession;
    if (session == null) {
      try {
        await client.auth.signInAnonymously();
        _log.info('Anonymous auth success');
      } catch (e) {
        _log.warning('Anonymous auth failed: $e');
      }
    }
  }

  String? get userId => client.auth.currentUser?.id;

  /// Get today's reading count for the current user.
  Future<int> getTodayReadingCount() async {
    if (!_initialized || userId == null) return 0;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final row = await client
          .from('tarot_daily_usage')
          .select('reading_count')
          .eq('user_id', userId!)
          .eq('usage_date', today)
          .maybeSingle();
      return (row?['reading_count'] as int?) ?? 0;
    } catch (e) {
      _log.warning('Failed to get daily usage: $e');
      return 0;
    }
  }

  /// Save a completed reading to Supabase.
  Future<void> saveReading({
    required String question,
    required List<Map<String, dynamic>> cards,
    required String persona,
    required String? spreadType,
    String locale = 'en',
  }) async {
    if (!_initialized || userId == null) return;

    try {
      await client.from('tarot_readings').insert({
        'user_id': userId,
        'question': question,
        'spread_type': spreadType,
        'cards': cards,
        'persona': persona,
        'locale': locale,
      });
      _log.info('Reading saved to Supabase');
    } catch (e) {
      _log.warning('Failed to save reading: $e');
    }
  }

  /// Send an error log to Supabase via `log_app_error` RPC.
  /// Fail-silent: network/RLS failures never propagate to the caller.
  Future<void> logError({
    required String severity,
    required String tag,
    required String message,
    String? stack,
    Map<String, dynamic>? context,
    String? appVersion,
    String? platform,
  }) async {
    if (!_initialized) return;
    try {
      await client.rpc('log_app_error', params: {
        'p_severity': severity,
        'p_tag': tag,
        'p_message': message,
        'p_stack': stack,
        'p_context': context,
        'p_app_version': appVersion,
        'p_platform': platform,
      });
    } catch (e) {
      _log.warning('logError RPC failed: $e');
    }
  }
}
