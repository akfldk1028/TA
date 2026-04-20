import 'dart:convert';

import 'package:http/http.dart' as http;

import 'tts_remote_types.dart';

/// Remote TTS 클라이언트 — Supabase Edge Function 호출.
///
/// YTB-tts-server의 TTSClient + Express 엔드포인트를 Dart화.
/// - POST /api/generate → sync TTS 생성
/// - POST /api/generate/async → async job
/// - GET /api/voices → 음성 목록
/// - GET /health → 헬스체크
class TtsRemoteClient {
  TtsRemoteClient({
    required this.baseUrl,
    this.authToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String? authToken;
  final http.Client _http;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// Sync TTS 생성. Provider 실패 시 서버가 자동 fallback.
  /// 30초 타임아웃 — Fish Audio가 장문에서 20s+ 걸릴 수 있어 여유 있게.
  /// 타임아웃 시 TtsRemoteException throw → speak() 가 catch 해서 isSpeaking 리셋.
  Future<TTSResponse> generate(TTSRequest request) async {
    final uri = Uri.parse('$baseUrl/api/generate');
    final response = await _http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TtsRemoteException(
            'TTS generate timed out after 30s',
            statusCode: 0,
          ),
        );

    if (response.statusCode != 200) {
      throw TtsRemoteException(
        'TTS generate failed: ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return TTSResponse.fromJson(jsonDecode(response.body));
  }

  /// Async TTS 생성 — job ID 반환.
  Future<String> generateAsync(TTSRequest request) async {
    final uri = Uri.parse('$baseUrl/api/generate/async');
    final response = await _http.post(
      uri,
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 202) {
      throw TtsRemoteException(
        'TTS async generate failed: ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['jobId'] as String;
  }

  /// Job 상태 조회.
  Future<TtsJob> getJobStatus(String jobId) async {
    final uri = Uri.parse('$baseUrl/api/status/$jobId');
    final response = await _http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw TtsRemoteException(
        'Job status failed: ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return TtsJob.fromJson(jsonDecode(response.body));
  }

  /// 음성 목록 조회.
  Future<List<VoiceInfo>> listVoices({
    String? provider,
    String? language,
  }) async {
    final path = provider != null
        ? '/api/voices/$provider'
        : '/api/voices';
    final queryParams = <String, String>{};
    if (language != null) queryParams['language'] = language;

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final response = await _http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      return [];
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => VoiceInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 헬스 체크.
  Future<bool> isHealthy() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await _http.get(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _http.close();
  }
}

/// Remote TTS 오류.
class TtsRemoteException implements Exception {
  const TtsRemoteException(this.message, {this.statusCode, this.body});
  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'TtsRemoteException: $message';
}
