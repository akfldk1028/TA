import 'dart:typed_data';

import '../remote/tts_remote_types.dart';
import '../tts_service.dart';
import 'tts_provider.dart';

/// On-device TTS 프로바이더 (flutter_tts 래핑).
///
/// [generate]는 직접 스피커로 재생하며, [TtsResult.audio]는 빈 바이트.
/// (flutter_tts는 오디오 버퍼를 반환하지 않으므로)
class LocalTtsProvider implements TtsProvider {
  LocalTtsProvider(this._service);

  final TtsService _service;

  @override
  String get name => 'local';

  @override
  Future<TtsResult> generate(String text, {TtsOptions? options}) async {
    if (options?.language != null) {
      await _service.setLocale(options!.language!);
    }
    await _service.speak(text);
    return TtsResult(
      audio: Uint8List(0),
      duration: 0,
      voice: 'device',
      mimeType: '',
    );
  }

  @override
  Future<List<VoiceInfo>> listVoices({String? language}) async {
    return [
      VoiceInfo(
        id: 'device',
        name: 'Device TTS',
        provider: 'local',
        language: _service.currentLocale,
        gender: 'neutral',
        description: 'On-device text-to-speech',
      ),
    ];
  }

  @override
  Future<bool> isAvailable() async => true;
}
