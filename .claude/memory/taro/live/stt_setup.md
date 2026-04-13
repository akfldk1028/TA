---
name: Speech-to-Text 설정 및 에뮬레이터 이슈
description: speech_to_text 패키지 설정, 권한, 에뮬레이터 마이크 문제
type: project
---

## Speech-to-Text (speech_to_text 패키지) — 2026-04-01

### 패키지
- `speech_to_text: ^7.0.0` in pubspec.yaml

### Android 권한 (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<queries>
    <intent><action android:name="android.speech.RecognitionService" /></intent>
</queries>
```

### 에뮬레이터 마이크 설정 (공식 문서 확인 2026-04-01)

**증상**: `initialize()` → `true`, `listen()` → `listening`, 하지만 `error_speech_timeout` 반복

**원인 2가지:**
1. **호스트 마이크 라우팅 기본 OFF** — emulator v28.0.23부터 비활성화됨. `hw.audioInput=yes`는 가상 장치 존재 여부일 뿐, 실제 호스트 오디오 연결과 별개.
2. **시스템 이미지 타입** — `SpeechRecognizer`는 Google 앱 필요. "Google Play" 이미지만 작동 ("Google APIs"는 안 됨).

**현재 AVD**: `Medium_Phone_API_36.0` — `google_apis_playstore` (Google Play) → 이미지는 OK

**호스트 마이크 활성화 방법 (3가지):**
1. 실행 시 플래그 (세션 유지): `emulator -avd <name> -allow-host-audio`
2. 실행 후 명령 (재시작 시 리셋): `adb emu avd hostmicon`
3. Extended Controls > Microphone > "Virtual microphone uses host audio input" ON (재시작 시 리셋)

**추가 체크:**
- Windows 설정 > 개인정보 > 마이크 > 에뮬레이터/Android Studio 접근 허용
- `config.ini`에 `hw.audioInput=yes` 확인 (기본값 yes)
- 인터넷 연결 필요 (기본 STT는 클라우드 기반)

### 코드 위치
- `consultation_screen.dart` — `_toggleMic()`, `_initSpeech()`, `_sendSpeechText()`
- 마이크 버튼: `chat_input_field.dart` — `onMicTap`, `isListening`

**Why:** 에뮬레이터 기본 설정이 마이크 OFF. 이미지 타입도 중요.
**How to apply:** 에뮬레이터 시작 시 `-allow-host-audio` 플래그 사용. 또는 시작 후 `adb emu avd hostmicon` 실행.
