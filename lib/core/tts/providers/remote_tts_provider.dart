import 'dart:convert';

import '../remote/tts_remote_client.dart';
import '../remote/tts_remote_types.dart';
import 'tts_provider.dart';

/// Remote TTS 프로바이더 — Supabase Edge Function 경유.
///
/// ElevenLabs / Google Cloud TTS를 서버 사이드에서 호출하고
/// base64 오디오를 반환.
class RemoteTtsProvider implements TtsProvider {
  RemoteTtsProvider(this._client, {this.defaultProvider});

  final TtsRemoteClient _client;
  final TtsProviderName? defaultProvider;

  @override
  String get name => 'remote';

  @override
  Future<TtsResult> generate(String text, {TtsOptions? options}) async {
    final request = TTSRequest(
      text: text,
      provider: defaultProvider,
      voice: options?.voice,
      language: options?.language,
      speed: options?.speed,
      stability: options?.stability,
      similarityBoost: options?.similarityBoost,
      style: options?.style,
      outputFormat: options?.outputFormat,
    );

    final response = await _client.generate(request);
    final audioBytes = base64Decode(response.audioBase64);

    return TtsResult(
      audio: audioBytes,
      duration: response.duration,
      voice: response.voice,
      mimeType: response.mimeType,
      alignment: response.alignment,
    );
  }

  @override
  Future<List<VoiceInfo>> listVoices({String? language}) =>
      _client.listVoices(language: language);

  @override
  Future<bool> isAvailable() => _client.isHealthy();
}
