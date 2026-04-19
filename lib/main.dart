import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'app.dart';
import 'core/config/ai_config.dart';
import 'core/observability/talker_supabase_observer.dart';
import 'core/services/cache_service.dart';
import 'core/services/supabase_service.dart';
import 'core/tts/tts_service.dart';
import 'i18n/multi_file_asset_loader.dart';
import 'purchase/purchase_service.dart';

/// Keep in sync with pubspec.yaml `version:`. Stamped into error_logs rows.
const String kAppVersion = '1.0.0+1';

/// Global Talker instance — import from main.dart to use anywhere.
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    useConsoleLogs: true,
    maxHistoryItems: 500,
  ),
);

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Route framework + platform errors through talker so the Supabase
    // observer can forward them to error_logs.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      talker.handle(details.exception, details.stack, 'FlutterError');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      talker.handle(error, stack, 'PlatformDispatcher');
      return true;
    };

    await Hive.initFlutter();
    await CacheService.instance.init();
    await SupabaseService.instance.init();
    await TtsService.instance.init();

    // Hook Supabase error sink after SupabaseService.init() — needs the client.
    talker.configure(
      observer: TalkerSupabaseObserver(appVersion: kAppVersion),
    );

    // Fish Audio TTS via Supabase Edge Function (Phase 1: replaces ElevenLabs).
    if (AiConfig.supabaseUrl.isNotEmpty) {
      final ttsUrl = '${AiConfig.supabaseUrl}/functions/v1/tts';
      debugPrint('[TTS] Configuring remote: $ttsUrl');
      TtsService.instance.configureRemote(baseUrl: ttsUrl);
      await TtsService.instance.setMode(TtsMode.remote);
      debugPrint('[TTS] Mode set to: ${TtsService.instance.mode}');
    } else {
      debugPrint('[TTS] No Supabase URL, using local TTS');
    }

    // Configure Gemini Live API (available when GEMINI_API_KEY is set)
    const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (geminiKey.isNotEmpty) {
      TtsService.instance.configureLive(apiKey: geminiKey);
      debugPrint('[TTS] Gemini Live API configured');
    }
    await PurchaseService.instance.initialize();
    await EasyLocalization.ensureInitialized();

    talker.info('App initialized');

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
          Locale('ja'),
          Locale('zh'),
          Locale('vi'),
          Locale('th'),
          Locale('id'),
          Locale('ms'),
          Locale('my'),
          Locale('fr'),
          Locale('de'),
          Locale('es'),
          Locale('pt'),
          Locale('it'),
          Locale('hi'),
          Locale('ar'),
          Locale('ru'),
        ],
        fallbackLocale: const Locale('en'),
        path: 'lib/i18n',
        assetLoader: MultiFileAssetLoader(),
        child: ProviderScope(
          observers: [
            TalkerRiverpodObserver(talker: talker),
          ],
          child: const TaroApp(),
        ),
      ),
    );
  }, (error, stack) {
    talker.handle(error, stack, 'ZoneUncaught');
  });
}
