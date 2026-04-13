import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'live_types.dart';

/// Gemini Live API 양방향 WebSocket 클라이언트.
///
/// 프로토콜 (공식 문서 기준):
/// - JSON camelCase keys (proto3 JSON mapping)
/// - Input audio: 16-bit PCM, 16kHz, mono → base64
/// - Output audio: 16-bit PCM, 24kHz, mono ← base64
///
/// 사용법:
/// ```dart
/// final client = LiveClient(apiKey: 'KEY');
/// await client.start(
///   onAudio: (bytes) => playPcm24k(bytes),
///   onText: (event) => print(event.text),
///   config: LiveConfig(voice: 'Aoede'),
/// );
/// await client.sendText('안녕하세요');
/// await client.sendAudio(micPcmBytes);
/// await client.stop();
/// ```
class LiveClient {
  LiveClient({
    required this.apiKey,
    this.model = 'gemini-2.5-flash-native-audio-preview-12-2025',
    this.audioSampleRate = 16000,
  });

  final String apiKey;
  final String model;
  final int audioSampleRate;

  static const _wsBase =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool active = false;
  Completer<void>? _setupCompleter;

  // Function calling
  final List<Map<String, dynamic>> _toolDecls = [];
  final Map<String, ToolHandler> _toolHandlers = {};

  // Callbacks
  void Function(Uint8List)? _onAudio;
  void Function(LiveEvent)? _onText;
  void Function(LiveEvent)? _onToolCall;

  /// Tool 등록.
  void registerTool(
    String name,
    String description,
    ToolHandler handler, {
    Map<String, dynamic>? parameters,
  }) {
    final decl = <String, dynamic>{
      'name': name,
      'description': description,
    };
    if (parameters != null) decl['parameters'] = parameters;
    _toolDecls.add(decl);
    _toolHandlers[name] = handler;
  }

  /// 세션 시작 — WebSocket 연결 + setup 메시지 전송.
  Future<void> start({
    void Function(Uint8List)? onAudio,
    void Function(LiveEvent)? onText,
    void Function(LiveEvent)? onToolCall,
    LiveConfig config = const LiveConfig(),
  }) async {
    _onAudio = onAudio;
    _onText = onText;
    _onToolCall = onToolCall;

    final uri = Uri.parse('$_wsBase?key=$apiKey');
    debugPrint('[LiveClient] Connecting to: ${uri.replace(queryParameters: {'key': '***'})}');
    debugPrint('[LiveClient] Model: $model');
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;
    active = true;
    debugPrint('[LiveClient] WebSocket connected');

    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: (error) {
        debugPrint('[LiveClient] WebSocket error: $error');
        active = false;
      },
      onDone: () {
        final code = _channel?.closeCode;
        final reason = _channel?.closeReason;
        debugPrint('[LiveClient] WebSocket closed (code=$code, reason=$reason)');
        active = false;
      },
    );

    // Fresh completer for each connection
    _setupCompleter = Completer<void>();
    _sendSetup(config);

    await _setupCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[LiveClient] Setup timeout — proceeding anyway');
      },
    );
  }

  void _sendSetup(LiveConfig config) {
    // 공식 WebSocket 문서 기준 최소 setup
    final setupMsg = <String, dynamic>{
      'model': 'models/$model',
      'generationConfig': {
        'responseModalities': ['AUDIO'],
      },
    };

    if (config.voice.isNotEmpty) {
      setupMsg['generationConfig'] = {
        ...setupMsg['generationConfig'] as Map<String, dynamic>,
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': config.voice},
          },
        },
      };
    }

    if (config.systemInstruction.isNotEmpty) {
      setupMsg['systemInstruction'] = {
        'parts': [
          {'text': config.systemInstruction}
        ],
      };
    }

    if (_toolDecls.isNotEmpty) {
      setupMsg['tools'] = [
        {'functionDeclarations': _toolDecls}
      ];
    }

    final payload = {'setup': setupMsg};
    final jsonStr = jsonEncode(payload);
    debugPrint('[LiveClient] Sending setup (${jsonStr.length} bytes): ${jsonStr.substring(0, jsonStr.length.clamp(0, 300))}');
    _send(payload);
  }

  /// PCM 오디오 전송 (마이크 → 모델).
  Future<void> sendAudio(Uint8List data) async {
    if (!active || _channel == null) return;
    _send({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(data),
          'mimeType': 'audio/pcm;rate=$audioSampleRate',
        },
      },
    });
  }

  /// 텍스트 메시지 전송.
  Future<void> sendText(String text) async {
    if (!active || _channel == null) return;
    _send({
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text}
            ],
          }
        ],
        'turnComplete': true,
      },
    });
  }

  /// 사용자 음성 종료 신호 — 캐시된 오디오 플러시.
  Future<void> signalAudioEnd() async {
    if (!active || _channel == null) return;
    _send({
      'realtimeInput': {'audioStreamEnd': true},
    });
  }

  /// VAD 힌트: 사용자 활동 시작.
  Future<void> signalActivityStart() async {
    if (!active || _channel == null) return;
    _send({
      'realtimeInput': {'activityStart': {}},
    });
  }

  /// VAD 힌트: 사용자 활동 종료.
  Future<void> signalActivityEnd() async {
    if (!active || _channel == null) return;
    _send({
      'realtimeInput': {'activityEnd': {}},
    });
  }

  /// 세션 정지.
  Future<void> stop() async {
    active = false;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    debugPrint('[LiveClient] Session stopped');
  }

  void _send(Map<String, dynamic> message) {
    if (_channel == null) {
      debugPrint('[LiveClient] _send: channel is null!');
      return;
    }
    final encoded = jsonEncode(message);
    debugPrint('[LiveClient] _send: ${encoded.length} bytes, channel open=$active');
    _channel!.sink.add(encoded);
  }

  /// WebSocket 메시지 디스패치.
  void _handleMessage(dynamic raw) {
    try {
      // WebSocket 응답이 String 또는 Uint8List로 올 수 있음
      final String text;
      if (raw is String) {
        text = raw;
      } else if (raw is Uint8List) {
        text = utf8.decode(raw);
      } else {
        debugPrint('[LiveClient] Unknown message type: ${raw.runtimeType}');
        return;
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      debugPrint('[LiveClient] Received keys: ${json.keys.toList()}');

      // setupComplete
      if (json.containsKey('setupComplete')) {
        debugPrint('[LiveClient] Setup complete');
        if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
          _setupCompleter!.complete();
        }
        return;
      }

      // serverContent
      final sc = json['serverContent'] as Map<String, dynamic>?;
      if (sc != null) {
        _handleServerContent(sc);
        return;
      }

      // toolCall
      final tc = json['toolCall'] as Map<String, dynamic>?;
      if (tc != null) {
        _handleToolCall(tc);
        return;
      }
    } catch (e, st) {
      debugPrint('[LiveClient] Message parse error: $e\n$st');
    }
  }

  void _handleServerContent(Map<String, dynamic> sc) {
    // Input transcript (user speech → text)
    final it = sc['inputTranscription'] as Map<String, dynamic>?;
    if (it != null && it['text'] != null) {
      _onText?.call(LiveEvent(
        type: LiveEventType.inputTranscript,
        text: it['text'] as String,
      ));
    }

    // Output transcript (model speech → text)
    final ot = sc['outputTranscription'] as Map<String, dynamic>?;
    if (ot != null && ot['text'] != null) {
      _onText?.call(LiveEvent(
        type: LiveEventType.outputTranscript,
        text: ot['text'] as String,
      ));
    }

    // Model turn (audio + text parts)
    final mt = sc['modelTurn'] as Map<String, dynamic>?;
    if (mt != null) {
      final parts = mt['parts'] as List?;
      if (parts != null) {
        for (final part in parts) {
          final p = part as Map<String, dynamic>;

          // Audio data
          final inlineData = p['inlineData'] as Map<String, dynamic>?;
          if (inlineData != null && inlineData['data'] != null) {
            final audioBytes = base64Decode(inlineData['data'] as String);
            _onAudio?.call(Uint8List.fromList(audioBytes));
          }

          // Text
          final text = p['text'] as String?;
          if (text != null) {
            _onText?.call(LiveEvent(
              type: LiveEventType.text,
              text: text,
            ));
          }
        }
      }
    }
  }

  Future<void> _handleToolCall(Map<String, dynamic> tc) async {
    final calls = tc['functionCalls'] as List?;
    if (calls == null) return;

    final responses = <Map<String, dynamic>>[];

    for (final call in calls) {
      final c = call as Map<String, dynamic>;
      final name = c['name'] as String;
      final id = c['id'] as String?;
      final args = (c['args'] as Map<String, dynamic>?) ?? {};

      final handler = _toolHandlers[name];
      Map<String, dynamic> result;

      if (handler != null) {
        try {
          result = await handler(args);
        } catch (e) {
          result = {'error': e.toString()};
        }
      } else {
        result = {'error': 'Unknown tool: $name'};
      }

      final entry = <String, dynamic>{
        'name': name,
        'response': result,
      };
      if (id != null) entry['id'] = id;
      responses.add(entry);

      _onToolCall?.call(LiveEvent(
        type: LiveEventType.toolCall,
        toolCall: ToolCallInfo(name: name, args: args, result: result),
      ));
    }

    _send({
      'toolResponse': {'functionResponses': responses},
    });
  }

  void dispose() {
    stop();
  }
}
