import 'dart:typed_data';

/// TTS 프로바이더 이름
enum TtsProviderName { elevenlabs, google }

/// TTS 출력 포맷
enum TtsOutputFormat { mp3, wav, pcm }

/// Remote TTS 요청 (YTB-tts-server 호환)
class TTSRequest {
  const TTSRequest({
    required this.text,
    this.provider,
    this.voice,
    this.language,
    this.speed,
    this.stability,
    this.similarityBoost,
    this.style,
    this.outputFormat,
  });

  final String text;
  final TtsProviderName? provider;
  final String? voice;
  final String? language;
  final double? speed;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final TtsOutputFormat? outputFormat;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (provider != null) 'provider': provider!.name,
        if (voice != null) 'voice': voice,
        if (language != null) 'language': language,
        if (speed != null) 'speed': speed,
        if (stability != null) 'stability': stability,
        if (similarityBoost != null) 'similarity_boost': similarityBoost,
        if (style != null) 'style': style,
        if (outputFormat != null) 'outputFormat': outputFormat!.name,
      };
}

/// Character-level alignment (ElevenLabs)
class TtsAlignment {
  const TtsAlignment({
    required this.characters,
    required this.startTimes,
    required this.endTimes,
  });

  final List<String> characters;
  final List<double> startTimes;
  final List<double> endTimes;

  factory TtsAlignment.fromJson(Map<String, dynamic> json) => TtsAlignment(
        characters: List<String>.from(json['characters']),
        startTimes: List<double>.from(
            (json['startTimes'] as List).map((e) => (e as num).toDouble())),
        endTimes: List<double>.from(
            (json['endTimes'] as List).map((e) => (e as num).toDouble())),
      );
}

/// Remote TTS 응답
class TTSResponse {
  const TTSResponse({
    required this.audioBase64,
    required this.duration,
    required this.voice,
    required this.provider,
    required this.mimeType,
    this.alignment,
  });

  final String audioBase64;
  final double duration;
  final String voice;
  final String provider;
  final String mimeType;
  final TtsAlignment? alignment;

  factory TTSResponse.fromJson(Map<String, dynamic> json) => TTSResponse(
        audioBase64: json['audioBase64'] as String,
        duration: (json['duration'] as num).toDouble(),
        voice: json['voice'] as String,
        provider: (json['provider'] as String?) ?? 'elevenlabs',
        mimeType: json['mimeType'] as String,
        alignment: json['alignment'] != null
            ? TtsAlignment.fromJson(json['alignment'])
            : null,
      );
}

/// 음성 정보
class VoiceInfo {
  const VoiceInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.language,
    required this.gender,
    this.description,
    this.previewUrl,
  });

  final String id;
  final String name;
  final String provider;
  final String language;
  final String gender;
  final String? description;
  final String? previewUrl;

  factory VoiceInfo.fromJson(Map<String, dynamic> json) => VoiceInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String,
        language: json['language'] as String,
        gender: json['gender'] as String,
        description: json['description'] as String?,
        previewUrl: json['previewUrl'] as String?,
      );
}

/// TTS 생성 결과 (프로바이더 공통)
class TtsResult {
  const TtsResult({
    required this.audio,
    required this.duration,
    required this.voice,
    required this.mimeType,
    this.alignment,
  });

  final Uint8List audio;
  final double duration;
  final String voice;
  final String mimeType;
  final TtsAlignment? alignment;
}

/// 비동기 Job 상태
enum JobStatus { queued, processing, completed, failed }

/// 비동기 Job
class TtsJob {
  const TtsJob({
    required this.id,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.result,
    this.error,
  });

  final String id;
  final JobStatus status;
  final int createdAt;
  final int? completedAt;
  final TTSResponse? result;
  final String? error;

  factory TtsJob.fromJson(Map<String, dynamic> json) => TtsJob(
        id: json['id'] as String,
        status: JobStatus.values.byName(json['status'] as String),
        createdAt: json['createdAt'] as int,
        completedAt: json['completedAt'] as int?,
        result: json['result'] != null
            ? TTSResponse.fromJson(json['result'])
            : null,
        error: json['error'] as String?,
      );
}
