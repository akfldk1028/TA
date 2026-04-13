import '../remote/tts_remote_types.dart';

/// TTS 옵션 (프로바이더 공통)
class TtsOptions {
  const TtsOptions({
    this.voice,
    this.language,
    this.speed,
    this.stability,
    this.similarityBoost,
    this.style,
    this.outputFormat,
  });

  final String? voice;
  final String? language;
  final double? speed;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final TtsOutputFormat? outputFormat;
}

/// 모든 TTS 프로바이더가 구현하는 인터페이스.
///
/// [LocalTtsProvider] — on-device flutter_tts
/// [RemoteTtsProvider] — Supabase Edge Function → ElevenLabs/Google TTS
abstract class TtsProvider {
  String get name;

  /// 텍스트 → 오디오 생성.
  /// [LocalTtsProvider]는 audio가 비어있고 직접 재생함.
  Future<TtsResult> generate(String text, {TtsOptions? options});

  /// 사용 가능한 음성 목록.
  Future<List<VoiceInfo>> listVoices({String? language});

  /// 프로바이더 사용 가능 여부.
  Future<bool> isAvailable();
}
