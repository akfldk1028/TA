---
name: TTS Logic Review Notes
description: 2026-03-30 로직 점검 — Gemini Live API camelCase 규칙, 원본 대조 결과
type: feedback
---

Gemini Live API raw WebSocket은 **반드시 camelCase JSON 키** 사용.

**Why:** proto3 JSON mapping 규칙. Python SDK는 내부적으로 snake_case→camelCase 변환하지만, raw WebSocket은 camelCase만 받음. 이걸 snake_case로 보내면 서버가 필드를 무시하거나 에러.

**How to apply:**
- `live_client.dart` 수정 시 모든 outgoing 메시지 키를 camelCase로 유지
- receiving은 이미 camelCase (`serverContent`, `modelTurn` 등)
- setup 메시지에서 `inputAudioTranscription`/`outputAudioTranscription`은 `generationConfig` 밖, setup 레벨에 위치
- 원본 Python 코드(client.py)는 SDK가 변환해주므로 snake_case로 작성되어 있음 — Dart에서는 직접 camelCase 사용
