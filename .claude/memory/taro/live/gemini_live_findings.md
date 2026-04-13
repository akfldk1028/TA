---
name: Gemini Live API WebSocket 연결 핵심 사항
description: Gemini Live API raw WebSocket 연결 시 발견한 핵심 제약사항 및 올바른 설정
type: project
---

## Gemini Live API WebSocket 연결 — 2026-04-01

### 올바른 모델명
- **`gemini-2.5-flash-native-audio-preview-12-2025`** (raw WebSocket용)
- `gemini-live-2.5-flash-preview` — JS SDK 전용, WebSocket에서 `1008 model not found`
- `gemini-2.5-flash-preview-native-audio-dialog` — 존재하지 않음

### 올바른 setup 메시지
```json
{
  "setup": {
    "model": "models/gemini-2.5-flash-native-audio-preview-12-2025",
    "generationConfig": {
      "responseModalities": ["AUDIO"],
      "speechConfig": {
        "voiceConfig": {
          "prebuiltVoiceConfig": {"voiceName": "Aoede"}
        }
      }
    }
  }
}
```

### 핵심 제약사항
1. **`responseModalities`에 `TEXT` 포함 금지** → `1007 Cannot extract voices from a non-audio request`
2. **`AUDIO`만 단독 사용** → `setupComplete` 수신 확인됨
3. **WebSocket 응답은 `Uint8List`** → `raw as String` 캐스팅 안 됨, `utf8.decode(raw)` 필요
4. **setup 키는 `setup`** (SDK의 `config`가 아님) → `Unknown name "config"` 에러
5. **`generationConfig` 래핑 필수** — responseModalities는 generationConfig 안에

### WebSocket 엔드포인트
`wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=API_KEY`

### Python 검증 (2026-04-01 성공)
```python
s = {'setup': {'model': f'models/{MODEL}', 'generationConfig': {'responseModalities': ['AUDIO']}}}
await ws.send(json.dumps(s))
r = await ws.recv()  # → {'setupComplete': ...}
```

### Dart 검증 (2026-04-01 성공)
- PID 15955: `[LiveClient] Received keys: [setupComplete]`
- `_handleMessage`에서 `Uint8List` → `utf8.decode` 변환 필수

**Why:** raw WebSocket은 SDK와 프로토콜이 다름. 모델명, 키 이름, modality, 응답 타입 모두 다름.
**How to apply:** LiveClient 수정 시 항상 이 문서 참고.
