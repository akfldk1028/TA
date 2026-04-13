import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'live/live_session.dart';
import 'live/live_types.dart';
import 'providers/remote_tts_provider.dart';
import 'providers/tts_provider.dart';
import 'remote/tts_audio_player.dart';
import 'remote/tts_remote_client.dart';
import 'remote/tts_remote_types.dart';
import 'tts_config.dart';

/// TTS 동작 모드
enum TtsMode {
  /// On-device flutter_tts (기본)
  local,
  /// Remote: Supabase Edge Function → ElevenLabs/Google TTS
  remote,
  /// Gemini Live API 양방향 음성
  live,
}

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  String? _currentId;
  String _currentLocale = 'en';
  VoidCallback? _onComplete;

  // Provider 시스템
  TtsMode _mode = TtsMode.local;
  RemoteTtsProvider? _remoteProvider;
  TtsAudioPlayer? _audioPlayer;
  LiveSession? _liveSession;
  String? _voice;

  TtsMode get mode => _mode;

  /// 현재 ElevenLabs 음성 프리셋 설정 (e.g. 'river', 'shimmer', 'adam').
  void setVoice(String voice) => _voice = voice;

  Future<void> init() async {
    await setLocale('en');
    _tts.setStartHandler(() => isSpeaking.value = true);
    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
      _currentId = null;
      _onComplete?.call();
      _onComplete = null;
    });
    _tts.setCancelHandler(() {
      isSpeaking.value = false;
      _currentId = null;
    });
    _tts.setErrorHandler((_) {
      isSpeaking.value = false;
      _currentId = null;
    });
  }

  /// TTS 모드 전환.
  Future<void> setMode(TtsMode mode) async {
    if (_mode == mode) return;
    await stop();
    _mode = mode;
  }

  /// Remote TTS 설정 (Supabase Edge Function URL + 인증).
  void configureRemote({
    required String baseUrl,
    String? authToken,
    TtsProviderName? defaultProvider,
  }) {
    final client = TtsRemoteClient(baseUrl: baseUrl, authToken: authToken);
    _remoteProvider = RemoteTtsProvider(client, defaultProvider: defaultProvider);
    if (_audioPlayer == null) {
      _audioPlayer = TtsAudioPlayer();
      // audioPlayer 상태 → TtsService.isSpeaking 동기화
      _audioPlayer!.isPlaying.addListener(_syncAudioPlayerState);
    }
  }

  void _syncAudioPlayerState() {
    final playing = _audioPlayer?.isPlaying.value ?? false;
    if (!playing && (_mode == TtsMode.remote || _mode == TtsMode.live)) {
      isSpeaking.value = false;
      _currentId = null;
      _onComplete?.call();
      _onComplete = null;
      _completeLiveSpeak();
    }
  }

  // Live 모드 설정
  String? _liveApiKey;
  String _liveModel = 'gemini-2.5-flash-native-audio-preview-12-2025';
  String _liveVoice = 'Aoede';
  String _liveSystemInstruction = '';
  Completer<void>? _liveSpeakCompleter;
  final List<int> _liveAudioBuffer = [];

  /// Live 모드 콜백: 모델이 보내는 텍스트 transcript
  void Function(String text)? onLiveTranscript;

  /// Live 세션 설정 (Gemini API key).
  void configureLive({
    required String apiKey,
    String model = 'gemini-2.5-flash-native-audio-preview-12-2025',
    String voice = 'Aoede',
    String systemInstruction = '',
  }) {
    _liveApiKey = apiKey;
    _liveModel = model;
    _liveVoice = voice;
    _liveSystemInstruction = systemInstruction;
  }

  /// Live 세션 시작 — WebSocket 연결.
  Future<void> startLiveSession({String? systemInstruction}) async {
    if (_liveApiKey == null) {
      debugPrint('[TtsService] Live API key not configured');
      return;
    }
    await _liveSession?.stop();
    _liveSession = LiveSession(apiKey: _liveApiKey!, model: _liveModel);

    if (_audioPlayer == null) {
      _audioPlayer = TtsAudioPlayer();
      _audioPlayer!.isPlaying.addListener(_syncAudioPlayerState);
    }

    await _liveSession!.start(
      sendEvent: _handleLiveEvent,
      config: LiveConfig(
        voice: _liveVoice,
        systemInstruction: systemInstruction ?? _liveSystemInstruction,
      ),
    );
    debugPrint('[TtsService] Live session started (voice: $_liveVoice)');
  }

  /// Live 세션 정지.
  Future<void> stopLiveSession() async {
    await _liveSession?.stop();
    _liveSession = null;
    _liveAudioBuffer.clear();
    _completeLiveSpeak();
  }

  Future<void> _handleLiveEvent(Map<String, dynamic> event) async {
    final type = event['type'] as String?;

    switch (type) {
      case 'audio':
        // PCM 24kHz mono 16-bit — base64 encoded (from LiveSession)
        final b64 = event['data'] as String?;
        if (b64 != null && b64.isNotEmpty) {
          try {
            final bytes = base64Decode(b64);
            _liveAudioBuffer.addAll(bytes);
            isSpeaking.value = true;
          } catch (e) {
            debugPrint('[TtsService] Failed to decode live audio: $e');
          }
        }

      case 'outputTranscript':
        final text = event['text'] as String? ?? '';
        if (text.isNotEmpty) onLiveTranscript?.call(text);

      case 'inputTranscript':
        // 사용자 음성 transcript — 필요 시 콜백 추가
        break;

      case 'text':
        // 모델 텍스트 응답 (비음성)
        final text = event['text'] as String? ?? '';
        if (text.isNotEmpty) onLiveTranscript?.call(text);
    }
  }

  /// 버퍼에 쌓인 PCM 오디오를 WAV로 변환 후 재생.
  Future<void> _flushLiveAudio() async {
    if (_liveAudioBuffer.isEmpty) return;

    final pcmBytes = Uint8List.fromList(_liveAudioBuffer);
    _liveAudioBuffer.clear();

    // PCM 24kHz, 16-bit, mono → WAV
    final wavBytes = _pcmToWav(pcmBytes, sampleRate: 24000);
    await _audioPlayer!.playBytes(wavBytes, 'audio/wav', id: 'live-tts');
  }

  void _completeLiveSpeak() {
    if (_liveSpeakCompleter != null && !_liveSpeakCompleter!.isCompleted) {
      _liveSpeakCompleter!.complete();
    }
    _liveSpeakCompleter = null;
  }

  /// PCM raw bytes → WAV file bytes (little-endian header).
  static Uint8List _pcmToWav(Uint8List pcmData, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setAll(0, header.buffer.asUint8List());
    wav.setAll(44, pcmData);
    return wav;
  }

  /// 현재 locale에 맞게 TTS 언어/속도/피치 설정.
  Future<void> setLocale(String languageCode) async {
    if (_currentLocale == languageCode) return;
    _currentLocale = languageCode;
    final config = TtsLocaleConfig.forLocale(languageCode);
    await _tts.setLanguage(config.ttsLanguage);
    await _tts.setSpeechRate(config.speechRate);
    await _tts.setPitch(config.pitch);
  }

  String get currentLocale => _currentLocale;

  /// Speak text. 현재 모드에 따라 local/remote/live로 분기.
  /// [onComplete] is called when speech finishes (local mode only for now).
  Future<void> speak(String text, {String? id, VoidCallback? onComplete}) async {
    if (_currentId == id && isSpeaking.value) {
      await stop();
      return;
    }
    await stop();
    _currentId = id;
    _onComplete = onComplete;

    switch (_mode) {
      case TtsMode.local:
        await _tts.speak(text);

      case TtsMode.remote:
        if (_remoteProvider == null || _audioPlayer == null) {
          debugPrint('[TtsService] Remote not configured (provider=$_remoteProvider, player=$_audioPlayer), falling back to local');
          await _tts.speak(text);
          return;
        }
        try {
          debugPrint('[TtsService] Remote TTS generating... (${text.length} chars)');
          isSpeaking.value = true;
          final result = await _remoteProvider!.generate(
            text,
            options: TtsOptions(
              voice: _voice,
              language: _currentLocale,
              stability: 0.3,
              similarityBoost: 0.8,
              style: 0.3,
            ),
          );
          debugPrint('[TtsService] Remote TTS got ${result.audio.length} bytes, mime=${result.mimeType}');
          if (result.audio.isNotEmpty) {
            await _audioPlayer!.playBytes(result.audio, result.mimeType, id: id);
          } else {
            debugPrint('[TtsService] Remote TTS returned empty audio, falling back to local');
            await _tts.speak(text);
          }
        } catch (e) {
          debugPrint('[TtsService] Remote TTS failed: $e, falling back to local');
          await _tts.speak(text);
        }

      case TtsMode.live:
        if (_liveSession == null || !_liveSession!.isActive) {
          debugPrint('[TtsService] Live session not active, falling back to remote');
          if (_remoteProvider != null && _audioPlayer != null) {
            try {
              isSpeaking.value = true;
              final result = await _remoteProvider!.generate(
                text,
                options: TtsOptions(voice: _voice, language: _currentLocale, stability: 0.3, similarityBoost: 0.8, style: 0.3),
              );
              if (result.audio.isNotEmpty) {
                await _audioPlayer!.playBytes(result.audio, result.mimeType, id: id);
                return;
              }
            } catch (_) {}
          }
          await _tts.speak(text);
          return;
        }
        try {
          isSpeaking.value = true;
          _liveAudioBuffer.clear();
          _liveSpeakCompleter = Completer<void>();

          await _liveSession!.pushText(text);

          // Wait for audio chunks to arrive (with timeout)
          // Gemini streams audio chunks, then a brief pause signals turn end
          await Future.delayed(const Duration(milliseconds: 500));
          // Poll for audio completion: wait until no new chunks for 800ms
          var silentMs = 0;
          var lastBufferSize = _liveAudioBuffer.length;
          while (silentMs < 800 && _liveAudioBuffer.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (_liveAudioBuffer.length == lastBufferSize) {
              silentMs += 200;
            } else {
              silentMs = 0;
              lastBufferSize = _liveAudioBuffer.length;
            }
            // Safety: max 30 seconds wait
            if (silentMs > 30000) break;
          }

          if (_liveAudioBuffer.isNotEmpty) {
            await _flushLiveAudio();
          } else {
            isSpeaking.value = false;
          }
        } catch (e) {
          debugPrint('[TtsService] Live TTS error: $e, falling back to local');
          isSpeaking.value = false;
          await _tts.speak(text);
        }
    }
  }

  Future<void> stop() async {
    _onComplete = null;
    await _tts.stop();
    _audioPlayer?.stop();
    isSpeaking.value = false;
    _currentId = null;
  }

  bool isPlayingId(String id) => _currentId == id && isSpeaking.value;

  LiveSession? get liveSession => _liveSession;

  void dispose() {
    _tts.stop();
    _audioPlayer?.isPlaying.removeListener(_syncAudioPlayerState);
    _audioPlayer?.dispose();
    _liveSession?.dispose();
    isSpeaking.dispose();
  }
}
