# TARO 핸드오프 — 2026-04-01 (세션 3)

## Goal

A2UI 기반 타로 상담 앱. 카드 뽑기 → 전부 앞면 펼치기 → AI가 한장씩 해석 + ElevenLabs TTS 자동 재생. 채팅 모드/TTS 모드/마이크 음성 입력 지원.

---

## 이번 세션에서 한 것 (세션 3)

### 1. P1 스프레드 3개 추가
- `twoPath` (두 갈래 길, 5장, decision) — 새 스프레드
- `compatibility` (궁합, 6장) — premium → free
- `fiveCard` (파이브카드, 5장) — premium → free
- `decision_prompt.dart`에 두 갈래 길 전용 AI 프롬프트
- `menu_screen.dart` — 스프레드 2개 이상이면 선택 화면으로

### 2. Gemini Live API WebSocket 연결 성공
- 모델명: `gemini-2.5-flash-native-audio-preview-12-2025` (raw WebSocket 전용)
- `responseModalities: ['AUDIO']` only — TEXT 포함하면 에러
- setup 키: `setup` (SDK의 `config`가 아님), `generationConfig` 래핑 필수
- **핵심 버그 수정**: WebSocket 응답이 `Uint8List`로 옴 → `utf8.decode(raw)` 필요 (기존 `raw as String` 캐스팅 실패)
- Python으로 검증 → Dart에서 `setupComplete` 수신 확인됨
- `tts_service.dart` — `configureLive()`, `startLiveSession()`, `stopLiveSession()`, `_pcmToWav()`, `_handleLiveEvent()`, `_flushLiveAudio()`
- `main.dart` — GEMINI_API_KEY 있으면 자동 configureLive

### 3. 마이크 버튼 + STT 추가
- `speech_to_text: ^7.0.0` 패키지 추가
- Android 권한: `RECORD_AUDIO`, `INTERNET`, `BLUETOOTH`, `BLUETOOTH_CONNECT`, `RecognitionService` query
- `chat_input_field.dart` — 텍스트 없으면 마이크 아이콘, 있으면 전송 버튼
- `consultation_screen.dart` — `_toggleMic()`: Live WebSocket 세션 + STT 동시 시작
- 마이크 탭 → 빨간 버튼(녹음) → 인식 완료 → 채팅에 텍스트 전송 → AI 응답
- 모든 phase에서 마이크 버튼 사용 가능
- **에뮬레이터 이슈**: `error_speech_timeout` — PC 마이크 미연결. `adb emu avd hostmicon` 필요. 실기기 테스트 권장.

### 4. 카드 UI 수정
- `spread_display_widget.dart` — 화면 비율 기반 카드 크기 (최대 56px, screenW 동적 계산)
- `consultation_screen.dart` — 카드 영역 30% 제한 (`ConstrainedBox`)
- 포지션 라벨 overflow 수정 (`TextOverflow.ellipsis`)

### 5. i18n
- 17개 언어 `liveMode`/`liveModeDesc`/`listening` 키 추가
- 페르소나 기반 텍스트 ("Gemini" 미노출, "오라클과 음성 대화" 등)

---

## 변경 파일 목록 (세션 3)

```
models/spread_type.dart                — twoPath 추가, compatibility/fiveCard free화
features/reading/prompts/decision_prompt.dart — 두 갈래 길 프롬프트
features/menu/pages/screens/menu_screen.dart  — 스프레드 선택 화면 분기

core/tts/tts_service.dart              — live 모드 전체 (configureLive, startLiveSession, _pcmToWav, _handleLiveEvent)
core/tts/live/live_client.dart         — 모델명 수정, AUDIO only, Uint8List→utf8.decode, setup 디버그 로그
core/tts/live/live_session.dart        — 모델명 수정

features/reading/pages/screens/consultation_screen.dart — 마이크 버튼(_toggleMic), STT, 카드 30% 제한
features/reading/pages/widgets/chat_input_field.dart    — onMicTap, isListening, 마이크/전송 토글
features/reading/pages/widgets/spread_display_widget.dart — 동적 카드 크기, ellipsis

main.dart              — configureLive(GEMINI_API_KEY)
pubspec.yaml           — speech_to_text: ^7.0.0
android/app/src/main/AndroidManifest.xml — RECORD_AUDIO, BLUETOOTH, RecognitionService query

i18n/{17 langs}/reading.json — liveMode, liveModeDesc, listening
```

---

## 현재 아키텍처

```
Flutter Client
  ├── env.json (SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY)
  ├── main.dart — TTS remote + live 자동 설정
  ├── core/tts/
  │   ├── tts_service.dart — 3모드(local/remote/live), setVoice, startLiveSession, _pcmToWav
  │   ├── tts_config.dart — 17개 locale 속도/피치
  │   ├── providers/ — local(flutter_tts), remote(Supabase→ElevenLabs)
  │   ├── remote/ — TtsRemoteClient, TtsAudioPlayer(임시파일!), TTSRequest(style지원)
  │   └── live/ — Gemini Live WebSocket (setupComplete 확인됨!)
  │       ├── live_client.dart — 모델: gemini-2.5-flash-native-audio-preview-12-2025
  │       ├── live_session.dart — 고수준 래퍼
  │       └── live_types.dart — LiveEvent, LiveConfig, ToolHandler
  ├── models/
  │   ├── tarot_card_data.dart, reading_category.dart
  │   ├── spread_type.dart — 11개 스프레드 (free 9 + pro 1 + celticCross)
  │   └── oracle_persona.dart — voiceId (matilda/river/shimmer/adam)
  ├── features/reading/
  │   ├── catalog/ — OracleMessage, TarotCard, DrawCards
  │   ├── services/ — transport.dart, ai_client.dart
  │   ├── prompts/ — base, love, career, fortune, general, decision
  │   └── pages/
  │       ├── screens/consultation_screen.dart — _toggleMic(), _initSpeech(), STT+Live
  │       ├── widgets/chat_input_field.dart — 마이크/전송 토글
  │       └── widgets/spread_display_widget.dart — 동적 크기
  └── i18n/ (17 languages)

Supabase (niagjmqffibeuetxxbxp)
  ├── Edge Function: ai-tarot (SSE, Gemini 3 Flash)
  ├── Edge Function: tts v6 (ElevenLabs, 7 voices)
  ├── DB: tarot_readings
  └── Secrets: GEMINI_API_KEY, ELEVENLABS_API_KEY
```

---

## Next Steps (우선순위)

### 1. 실기기 STT 테스트
- 에뮬레이터에서 STT `error_speech_timeout` — PC 마이크 미전달
- 실기기 USB 디버깅으로 마이크→STT→채팅→AI 응답 플로우 검증
- 에뮬레이터: `adb emu avd hostmicon` 후 재시도

### 2. Live 모드 양방향 음성 대화
- 현재: 마이크 → STT → 텍스트 전송 → AI(SSE) → ElevenLabs TTS
- 다음: 마이크 PCM → Gemini Live WebSocket → 음성 응답 직접 재생
- `record` 패키지로 마이크 PCM 캡처 → `liveSession.pushAudio()`
- Gemini 응답 오디오 → `_flushLiveAudio()` → WAV → just_audio

### 3. 앱 런칭 준비
- Android/iOS 빌드, 앱 아이콘, 스플래시

---

## 실행 방법

```bash
cd D:/Data/33_A2UI/A2UI/clone/TARO
# 에뮬레이터 마이크 활성화 (STT용)
adb emu avd hostmicon
# 앱 실행
flutter run -d emulator-5554 --dart-define-from-file=env.json
```

## 참고

- 메모리: `D:\DevCache\claude-data\projects\D--Data-33-A2UI-A2UI\memory\`
- Supabase MCP: `mcp__supabase-taro__*`
- **StreamAudioSource 쓰면 안 됨** — Android ExoPlayer Source error
- **JSON 키 `audioBase64`** — `audio` 아님
- **WebSocket 응답 `Uint8List`** — `utf8.decode()` 필수, `as String` 불가
- **responseModalities `AUDIO` only** — `TEXT` 포함 시 `1007 Cannot extract voices` 에러
- **모델명** — `gemini-2.5-flash-native-audio-preview-12-2025` (raw WS), `gemini-live-2.5-flash-preview` (JS SDK only)
- Live API 상세: `memory/taro/live/gemini_live_findings.md`
- STT 설정: `memory/taro/live/stt_setup.md`
