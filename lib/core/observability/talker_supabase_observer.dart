import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../services/supabase_service.dart';

/// Pipes Talker errors/exceptions to the Supabase `error_logs` table
/// via the `log_app_error` RPC. Fail-silent and throttled.
class TalkerSupabaseObserver extends TalkerObserver {
  TalkerSupabaseObserver({required this.appVersion});

  final String appVersion;

  static const int _maxPerMinute = 20;
  final List<int> _recentMs = [];

  bool _throttled() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _recentMs.removeWhere((t) => now - t > 60000);
    return _recentMs.length >= _maxPerMinute;
  }

  // Only record the timestamp after a successful RPC — if the call fails
  // (offline, 5xx), the slot stays free so the next error still has a chance.
  void _markSent() {
    _recentMs.add(DateTime.now().millisecondsSinceEpoch);
  }

  String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  Future<void> _send({
    required String tag,
    required String message,
    String? stack,
  }) async {
    try {
      await SupabaseService.instance.logError(
        severity: 'error',
        tag: tag,
        message: message,
        stack: stack,
        appVersion: appVersion,
        platform: _platform(),
      );
      _markSent();
    } catch (_) {
      // Fail-silent: offline/5xx does not consume a throttle slot.
    }
  }

  @override
  void onError(TalkerError err) {
    if (_throttled()) return;
    unawaited(_send(
      tag: err.title ?? 'Error',
      message: err.message ?? err.displayMessage,
      stack: err.stackTrace?.toString(),
    ));
  }

  @override
  void onException(TalkerException err) {
    if (_throttled()) return;
    unawaited(_send(
      tag: err.title ?? 'Exception',
      message: err.message ?? err.displayMessage,
      stack: err.stackTrace?.toString(),
    ));
  }
}
