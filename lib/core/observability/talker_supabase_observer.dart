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
    if (_recentMs.length >= _maxPerMinute) return true;
    _recentMs.add(now);
    return false;
  }

  String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  @override
  void onError(TalkerError err) {
    if (_throttled()) return;
    unawaited(
      SupabaseService.instance.logError(
        severity: 'error',
        tag: err.title ?? 'Error',
        message: err.message ?? err.displayMessage,
        stack: err.stackTrace?.toString(),
        appVersion: appVersion,
        platform: _platform(),
      ),
    );
  }

  @override
  void onException(TalkerException err) {
    if (_throttled()) return;
    unawaited(
      SupabaseService.instance.logError(
        severity: 'error',
        tag: err.title ?? 'Exception',
        message: err.message ?? err.displayMessage,
        stack: err.stackTrace?.toString(),
        appVersion: appVersion,
        platform: _platform(),
      ),
    );
  }
}
