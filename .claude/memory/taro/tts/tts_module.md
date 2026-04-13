---
name: TTS Module Structure
description: core/tts/ — local/remote/live 3모드, ElevenLabs 임시파일 재생, 페르소나별 음성
type: project
---

2026-03-31 TTS 3단계 BUG 수정 + 페르소나별 음성 매핑

## 핵심 로직

1. `main.dart` → `configureRemote(baseUrl)` → `setMode(TtsMode.remote)`
2. `tarot_session.confirmPersona()` → `TtsService.setVoice(persona.voiceId)`
3. `speak()` → `TtsOptions(voice: _voice, stability: 0.3, similarityBoost: 0.8, style: 0.3)`
4. `RemoteTtsProvider.generate()` → HTTP POST → `TTSResponse.fromJson(json['audioBase64'])`
5. `TtsAudioPlayer._playFromTempFile()` → `writeAsBytes` → `setFilePath` → `play()`

## 절대 하면 안 되는 것

- **StreamAudioSource 쓰지 마라**: Android ExoPlayer "(0) Source error". 임시파일만 사용
- **JSON 키 `audio`로 읽지 마라**: Edge Function은 `audioBase64` 반환
- **`similarityBoost` camelCase로 보내지 마라**: Edge Function은 `similarity_boost` (snake_case) 읽음

## 페르소나별 음성 (여2 남1 중성1)

| 페르소나 | voiceId | ElevenLabs ID | 성별 |
|---------|---------|---------------|------|
| 신비 현자 | matilda | XrExE9yKIg1WjnnlVkGX | 여성 |
| 분석가 | river | SAz9YHcvj6GT2YYXdXww | 중성 |
| 친구 | shimmer | N2lVS1w4EtoT3dr4eOWO | 여성 |
| 직설가 | adam | pNInz6obpgDQGcFmaJgB | 남성 |

## Edge Function (Supabase) v6

- `tts` (verify_jwt=false)
- POST `/functions/v1/tts/api/generate`
- Model: `eleven_multilingual_v2` (17개 언어 자동 감지)
- 기본값: stability=0.3, similarity_boost=0.8, style=0.3, use_speaker_boost=true
- 기본 음성: river
- Presets: sarah, matilda, shimmer, river, adam, george, roger

## 의존성

- `just_audio: ^0.9.40`, `path_provider: ^2.1.0`, `http: ^1.2.0`

## 다음: Gemini Live API

- `core/tts/live/` 구조 있음 (live_client, live_session, live_types)
- WebSocket 양방향 실시간 음성 대화
- 모델: `gemini-2.5-flash-preview-native-audio-dialog`
- camelCase JSON 필수 (proto3 매핑)
