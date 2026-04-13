---
name: TARO 코드 리뷰 수정사항
description: 4차~6차 리뷰 수정 기록 — 위젯 분리/Riverpod/버그 수정/DB/TTS/UI통합
type: project
---

## 6차 수정 (2026-03-31)

### BUG 1: ElevenLabs TTS 로봇 목소리 (최우선)
- **원인**: Edge Function은 `audioBase64` 키로 응답하는데 Dart는 `json['audio']`로 파싱 → null cast 에러 → catch → local fallback
- **추가 원인**: Edge Function은 `provider` 필드를 응답에 포함 안 함 → `json['provider'] as String`도 null cast
- **수정**: `tts_remote_types.dart` — `json['audio']` → `json['audioBase64']`, `provider` nullable 처리 (`?? 'elevenlabs'`)

### BUG 2: TarotCard + OracleMessage 2블록 분리
- **원인**: AI가 TarotCard + OracleMessage를 별도 surface로 보내서 각각 독립 블록으로 렌더링
- **수정 (4파일)**:
  1. `tarot_message.dart` — `componentName` 필드 추가
  2. `transport.dart` — `surfaceComponentNames` map 추가 (surfaceId → componentName 매핑)
  3. `tarot_session.dart` — `_onSurfaceAdded`에서 componentName 전달
  4. `message_list_widget.dart` — OracleMessage가 TarotCard 바로 뒤일 때만 `top:0` 간격
  5. `oracle_message.dart` — 아바타 원+테두리 제거 → 좌측 gold 라인+이탤릭 텍스트 (시각적 종속)

## 5차 수정 (2026-03-29)

### 버그 수정
1. **ai_client.dart** — SSE 스트림 45초 타임아웃, `done:true` 없이 종료 시 정상 처리, TimeoutException catch
2. **transport.dart** — 전체 요청 90초 안전 타임아웃, `isProcessing` 항상 리셋 보장
3. **consultation_screen.dart** — `_pendingInterpretations` 큐 추가, AI 처리 중 카드 탭 시 큐잉 후 순차 처리

### 새 기능
4. **supabase_service.dart** (신규) — Supabase 초기화, 익명 인증, `tarot_readings` 테이블 저장
5. **tts_service.dart** (신규) — flutter_tts 한국어 TTS, speak/stop/isPlayingId
6. **oracle_message.dart** — `_TtsButton` 위젯 추가 (텍스트 길이 > 10일 때 표시)
7. **reading_summary.dart** — `_SummaryTtsButton` 위젯 추가 ("듣기"/"중지" 레이블)
8. **tarot_session.dart** — `_saveReadingHistory()`에 SupabaseService.saveReading 추가
9. **main.dart** — SupabaseService.init() + TtsService.init() 추가
10. **pubspec.yaml** — `supabase_flutter: ^2.8.0`, `flutter_tts: ^4.2.0` 추가

## 7차 수정 (2026-04-08) — 하네스 설계 + Talker 로깅

### 하네스 설계 (Harness Design)
1. **tarot_session.dart** — `_validTransitions` 맵 + `_setPhase()` 가드, 모든 직접 `_phase =` → `_setPhase()` 교체 (startConsultation 제외)
2. **ai_client.dart** — `RetryAiClient` 래퍼 (retry 1회 → GeminiAiClient fallback), 스트리밍 보존 (`yield*`)
3. **tarot_message.dart** — `isError` 플래그 추가

### Talker 로깅 통합
4. **main.dart** — `talker_flutter` 글로벌 인스턴스 + `TalkerRiverpodObserver` (Provider 자동 로깅)
5. **tarot_session.dart, transport.dart, ai_client.dart** — `Logger`/`debugPrint`/`dart:developer log` → `talker.*` 전환, `[태그]` 형식 통일

### 코드 리뷰 발견사항
- **RetryAiClient 버퍼링 버그 수정**: 첫 시도에서 전체 응답 수집 후 yield → 스트리밍 깨짐. `yield*` 직접 사용으로 수정.
- Phase 전환 맵 전체 경로 검증 완료 (chatting→picking→reading→chatting 추가 카드 흐름 포함)

## 4차 수정 (2026-03-28, commit 2dd5277)

### 크래시/행 방지
1. **ai_client.dart** — 30초 HTTP 타임아웃, SSE catch 에러 로깅, _isCancelled 스트림 취소
2. **transport.dart** — _disposed 플래그, StreamController .add() 가드
3. **tarot_session.dart** — interpretCard try/finally로 상태 리셋 보장

### 아키텍처
4. **app_router.dart** — @Riverpod(keepAlive:true)
5. **consultation_screen.dart** — _PulsingDot 별도 위젯
6. **위젯 분리** — 555줄 → 320줄 (card_fan, spread_display, message_list)
7. **Riverpod 전환** — ChangeNotifierProvider.autoDispose, ConsumerStatefulWidget
