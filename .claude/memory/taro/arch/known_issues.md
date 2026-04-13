---
name: TARO 알려진 이슈 패턴
description: 해결/미해결 이슈 — WebSocket, STT, TTS, UI, 에뮬레이터 등
type: feedback
---

## 해결된 이슈

### TTS Remote JSON 키 불일치 (2026-03-31)
Edge Function `audioBase64` vs Dart `audio` → 수정 완료.
**How to apply:** Remote 서비스 연동 시 curl로 실제 응답 확인.

### isProcessing 고착 (2026-03-31)
SSE done:true 없이 종료 시 무한 대기 → 이중 타임아웃 (45s + 90s), finally 블록 리셋.

### WebSocket Uint8List 파싱 (2026-04-01)
`raw as String` → 실패. WebSocket 응답이 바이너리(Uint8List)로 옴.
**수정:** `utf8.decode(raw)` 사용. **절대 `as String` 캐스팅 금지.**

### WebSocket 모델명/setup 형식 (2026-04-01)
- 모델: `gemini-2.5-flash-native-audio-preview-12-2025` (raw WS 전용)
- 키: `setup` (`config` 아님), `generationConfig` 래핑 필수
- **`responseModalities: ['AUDIO']` only** — `TEXT` 포함 시 `1007 Cannot extract voices` 에러

### StreamAudioSource Android 에러 (2026-03-31)
ExoPlayer `Source error` → 임시파일 기반 재생으로 전환.

## 미해결 이슈

### 에뮬레이터 STT timeout (원인 파악 완료 2026-04-01)
`error_speech_timeout` — 호스트 마이크 라우팅이 기본 OFF (emulator v28.0.23+).
AVD 이미지는 Google Play로 확인 완료 (OK). 
**해결법**: `emulator -avd <name> -allow-host-audio` 또는 `adb emu avd hostmicon`.
Windows 마이크 권한도 확인 필요. 상세: `taro/live/stt_setup.md`

### Live 양방향 음성 미구현
WebSocket 연결+setupComplete 성공. 텍스트 전송 가능.
하지만 마이크 PCM → WebSocket 직접 전송은 아직 구현 안 됨 (`record` 패키지 필요).

### 카드 플립 레이스 컨디션
AI 처리 중 카드 탭 → `_pendingInterpretations` 큐로 대기 (기존 해결책 유지).

### 에뮬레이터 ADB 제스처 충돌
y=2200+ 영역 → 시스템 홈 제스처. ADB swipe는 y=1600 이하에서만.
