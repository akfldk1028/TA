import 'dart:typed_data';

/// Gemini Live API 이벤트 타입
enum LiveEventType {
  audio,
  inputTranscript,
  outputTranscript,
  text,
  toolCall,
}

/// Live API 이벤트 (콜백으로 전달)
class LiveEvent {
  const LiveEvent({
    required this.type,
    this.text,
    this.audioData,
    this.toolCall,
  });

  final LiveEventType type;
  final String? text;
  final Uint8List? audioData;
  final ToolCallInfo? toolCall;
}

/// Function calling 결과 정보
class ToolCallInfo {
  const ToolCallInfo({
    required this.name,
    required this.args,
    required this.result,
  });

  final String name;
  final Map<String, dynamic> args;
  final Map<String, dynamic> result;

  Map<String, dynamic> toJson() => {
        'name': name,
        'args': args,
        'result': result,
      };
}

/// Tool 선언 (모델에게 노출할 함수 정보)
class ToolDeclaration {
  const ToolDeclaration({
    required this.name,
    required this.description,
    this.parameters,
  });

  final String name;
  final String description;
  final Map<String, dynamic>? parameters;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (parameters != null) 'parameters': parameters,
      };
}

/// Live 세션 설정
class LiveConfig {
  const LiveConfig({
    this.voice = 'Aoede',
    this.systemInstruction = '',
    this.tools = const [],
    this.audioSampleRate = 16000,
  });

  final String voice;
  final String systemInstruction;
  final List<ToolDeclaration> tools;
  final int audioSampleRate;
}

/// Tool 핸들러 타입: args → result
typedef ToolHandler = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> args);
