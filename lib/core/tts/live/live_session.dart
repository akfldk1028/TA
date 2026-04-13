import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'live_client.dart';
import 'live_types.dart';

/// 고수준 음성 세션 래퍼 (Python session.py Dart화).
///
/// mic → LiveClient → speaker 루프를 관리.
/// 이벤트 콜백을 base64/JSON으로 인코딩하여 프론트엔드 호환.
///
/// 사용법:
/// ```dart
/// final session = LiveSession(apiKey: 'KEY');
/// await session.start(
///   sendEvent: (event) async => handleEvent(event),
///   config: LiveConfig(
///     voice: 'Aoede',
///     systemInstruction: '한국어로 대답하세요.',
///   ),
/// );
/// await session.pushText('안녕');
/// await session.pushAudio(micPcmBytes);
/// await session.stop();
/// ```
class LiveSession {
  LiveSession({
    required String apiKey,
    String model = 'gemini-2.5-flash-native-audio-preview-12-2025',
  }) : client = LiveClient(apiKey: apiKey, model: model);

  final LiveClient client;

  /// 세션 시작.
  ///
  /// [sendEvent] — 프론트엔드로 이벤트 푸시:
  ///   - `{"type": "audio", "data": "<base64 PCM 24kHz>"}`
  ///   - `{"type": "inputTranscript", "text": "..."}`
  ///   - `{"type": "outputTranscript", "text": "..."}`
  ///   - `{"type": "text", "text": "..."}`
  ///   - `{"type": "toolCall", "name": "...", "args": {...}, "result": {...}}`
  Future<void> start({
    required Future<void> Function(Map<String, dynamic> event) sendEvent,
    LiveConfig config = const LiveConfig(),
    List<ToolRegistration>? tools,
  }) async {
    if (tools != null) {
      for (final t in tools) {
        client.registerTool(t.name, t.description, t.handler,
            parameters: t.parameters);
      }
    }

    await client.start(
      onAudio: (audioBytes) {
        sendEvent({
          'type': 'audio',
          'data': base64Encode(audioBytes),
        });
      },
      onText: (event) {
        sendEvent({
          'type': event.type.name,
          'text': event.text ?? '',
        });
      },
      onToolCall: (event) {
        if (event.toolCall != null) {
          sendEvent({
            'type': 'toolCall',
            ...event.toolCall!.toJson(),
          });
        }
      },
      config: config,
    );

    debugPrint('[LiveSession] Started (voice: ${config.voice})');
  }

  /// 마이크 PCM 오디오 전송 (16kHz, 16-bit, mono).
  Future<void> pushAudio(Uint8List audioBytes) =>
      client.sendAudio(audioBytes);

  /// Base64 인코딩된 PCM 오디오 전송.
  Future<void> pushAudioBase64(String b64) =>
      client.sendAudio(base64Decode(b64));

  /// 텍스트 메시지 전송.
  Future<void> pushText(String text) => client.sendText(text);

  /// 사용자 음성 종료 신호 — 캐시된 오디오 플러시.
  Future<void> userStoppedSpeaking() => client.signalAudioEnd();

  /// 세션 정지.
  Future<void> stop() async {
    await client.stop();
    debugPrint('[LiveSession] Stopped');
  }

  bool get isActive => client.active;

  void dispose() {
    client.dispose();
  }
}

/// Tool 등록 정보 묶음.
class ToolRegistration {
  const ToolRegistration({
    required this.name,
    required this.description,
    required this.handler,
    this.parameters,
  });

  final String name;
  final String description;
  final ToolHandler handler;
  final Map<String, dynamic>? parameters;
}
