# ORACLE (taro_a2ui) — AI Tarot Reading App

## Quick Start

```bash
flutter pub get
flutter run -d <device> --dart-define-from-file=env.json
```

`env.json` (gitignored — 반드시 프로젝트 루트에 생성):
```json
{
  "GEMINI_API_KEY": "<your-gemini-api-key>",
  "SUPABASE_URL": "https://niagjmqffibeuetxxbxp.supabase.co",
  "SUPABASE_ANON_KEY": "<your-supabase-anon-key>"
}
```

Flutter SDK `^3.11.3` 필요. Supabase 백엔드는 클라우드에 배포 완료 — 키만 넣으면 동작.

---

## Deep Context

이 프로젝트를 처음 작업할 때 `.claude/memory/` 디렉토리의 파일들을 읽어야 전체 맥락을 이해할 수 있다.

**필수 우선 읽기:**
- `.claude/memory/taro/overview.md` — 전체 아키텍처, 기술 스택, 실행 방법
- `.claude/memory/taro/arch/consultation_flow.md` — 5-Phase 상태 머신 + FC preflight + 추가카드/새주제 전체 플로우
- `.claude/memory/taro/arch/harness_design.md` — 하네스 설계 + Talker 로그 태그 맵 (디버깅 필독)
- `.claude/memory/taro/arch/known_issues.md` — 해결/미해결 이슈 패턴

**영역별 참조:**
- Backend: `.claude/memory/taro/backend/` — Edge Function, DB, Supabase MCP 규칙
- TTS: `.claude/memory/taro/tts/` — 3모드 TTS 구조, 절대 하면 안 되는 것
- Live API: `.claude/memory/taro/live/` — Gemini Live WebSocket 제약사항
- Design: `.claude/memory/taro/design/` — AI 모델, 브랜딩, 카드 이미지, 스프레드
- Purchase: `.claude/memory/taro/purchase/` — RevenueCat IAP 모듈
- Data: `.claude/memory/taro/data/` — 카드 지식 DB, tarot_data.json 구조
- Review: `.claude/memory/taro/review/` — 코드 리뷰 수정 히스토리
- Feedback: `.claude/memory/feedback/` — 코딩 규칙 (수학적 레이아웃, DrawCards 미표시)

---

## Architecture

A2UI(GenUI 0.7.0) 기반 Flutter 타로 상담 앱. 하이브리드 아키텍처 — 카드 UI는 네이티브 Flutter, AI 해석은 A2UI.

### 5-Phase 상태 머신

```
question → personaPick → picking → reading → chatting
                                    ↑          │
                          (additional) ←── picking ←┘
                                    ↑          │
                          (new_topic) → question ←┘
```

- **question**: 큰 세리프 텍스트 + 추천 칩. AI 호출 없음.
- **personaPick**: 사용자 질문 표시 + 페르소나 선택. AI 호출 없음.
- **picking**: 78장 3줄 카드 팬. AI 호출 없음.
- **reading**: SpreadDisplay + 카드별 AI 해석 (OracleMessage + TarotCard)
- **chatting**: SpreadDisplay + 자유 대화 + 추가 카드/새 주제

**Phase 전환은 반드시 `_setPhase()` 경유.** `_validTransitions` 맵으로 유효한 전환만 허용. 직접 `_phase =` 할당 금지.

### AI 호출 경로

```
TarotSession._sendToAi()
  → TaroContentGenerator.sendRequest()
    → RetryAiClient.sendStream()
      → EdgeFunctionAiClient → ai-tarot Edge Function v4
        [서버 내부]
        1. FC preflight (non-streaming, 최대 5회)
           → Qwen tool_call: get_card_knowledge("The Fool") → DB 조회
           → Qwen tool_call: get_combination_rules("elemental_dignities") → DB 조회
           → 최종 텍스트 답변 확보
        2. SSE 스트리밍 반환 (50자 청크)
      → [실패 시] retry 1회 (동일 primary 재호출)
    → JSON 파싱: A2UI 블록 증분 emit
    → DrawCards/ReadingSummary 컴포넌트 필터링
```

### 기술 스택

| 분류 | 기술 |
|------|------|
| AI 모델 | Qwen 3.5 Flash (DashScope, $0.10/$0.40 per 1M) |
| AI 연동 | Edge Function FC preflight → tool calling → SSE |
| 지식 DB | tarot_cards (78장 JSONB) + tarot_rules (4규칙) |
| State | Riverpod (ChangeNotifierProvider.autoDispose) |
| Routing | go_router |
| i18n | easy_localization (17개 언어) |
| TTS | flutter_tts(local) + Fish Audio S2(remote) + Gemini Live(live) |
| IAP | purchases_flutter (RevenueCat) — placeholder 키, 아직 미연동 |
| Image | CachedNetworkImage (Supabase Storage) |
| Logging | talker_flutter + TalkerRiverpodObserver + TalkerSupabaseObserver (error_logs RPC) |

---

## Key Rules (절대 규칙)

### 코딩 규칙
- **UI 배치는 수학적 계산** — 하드코딩 금지. 경계 조건 → 역산 공식 사용. 예: `maxRadius = (availW / 2 - cardW) / sin(totalAngle / 2)`
- **DrawCards 컴포넌트 UI 미표시** — AI가 생성해도 채팅에 안 보여줌. transport.dart에서 콜백만 처리. 카드+해석만 표시.
- **Phase 전환은 `_setPhase()` 경유** — 직접 `_phase =` 할당 금지. `_validTransitions` 맵 참조.
- **AI 호출은 `RetryAiClient` 경유** — primary 1회 retry. Gemini fallback 제거됨(Phase 2 대기). 스트리밍 보존 (`yield*`).

### TTS 규칙
- **StreamAudioSource 쓰지 마라** — Android ExoPlayer `Source error`. 임시파일(`writeAsBytes → setFilePath → play`) 방식만 사용.
- **JSON 키 `audioBase64`** — `audio` 아님. Edge Function 응답 키 불일치 주의.
- **Fish Audio `reference_id`는 Secret 주입** — 코드에 voice ID 하드코딩 금지. `FISH_AUDIO_VOICE_*` env 경유.

### Gemini Live API 규칙
- **WebSocket 응답 `Uint8List`** — `utf8.decode(raw)` 필수. `raw as String` 캐스팅 절대 금지.
- **`responseModalities: ['AUDIO']` only** — `TEXT` 포함 시 `1007 Cannot extract voices` 에러.
- **모델명**: `gemini-2.5-flash-native-audio-preview-12-2025` (raw WebSocket). `gemini-live-*`은 JS SDK 전용.
- **setup 키는 `setup`** — SDK의 `config` 아님. `generationConfig` 래핑 필수.
- **camelCase JSON만** — raw WebSocket은 proto3 매핑. snake_case 보내면 서버가 무시.

### Supabase 규칙
- **MCP**: `mcp__supabase-taro__*` 전용. 다른 Supabase MCP 혼용 금지.
- **Project ref**: `niagjmqffibeuetxxbxp`

---

## Supabase Backend

폴더 구조와 마이그레이션 규칙은 `supabase/README.md` 참조.

### Edge Functions (supabase/functions/)

| Function | 역할 |
|----------|------|
| `ai-tarot` | Qwen 3.5 Flash + FC preflight tool calling + SSE streaming |
| `tts` | Fish Audio S2 (reference_id env-driven, MP3 base64 반환) |
| `seed-knowledge` | 78장+4규칙 DB 삽입 유틸 (일회용) |

### DB Tables (supabase/schema/tables/)

| Table | 용도 |
|-------|------|
| `tarot_cards` | 78장 카드 지식 (data JSONB, name으로 조회) |
| `tarot_rules` | 4개 조합 규칙 (slug PK) |
| `tarot_readings` | 리딩 세션 (RLS: user_id) |
| `tarot_messages` | 리딩 중 대화 (role/content, reading_id FK) |
| `tarot_daily_usage` | 일일 토큰/비용 (UNIQUE user_id+date) |
| `subscriptions` | IAP 구독 (UNIQUE user_id+product_id) |
| `user_profiles` | 앱 사용자 프로필 (auth.users 트리거 자동 생성) |
| `error_logs` | 앱 오류 원격 추적 (log_app_error RPC 로만 INSERT) |

### RPC
- `increment_tarot_usage(p_user_id, p_reading_count, p_token_count, p_gemini_cost)` — UPSERT 패턴
- `log_app_error(p_severity, p_tag, p_message, p_stack?, p_context?, p_app_version?, p_platform?)` — SECURITY DEFINER. 클라이언트는 `TalkerSupabaseObserver` 경유 호출.

### Secrets (Dashboard > Settings > Edge Functions)
- `QWEN_API_KEY` — DashScope Qwen 3.5 Flash
- `FISH_AUDIO_API_KEY` — Fish Audio S2
- `FISH_AUDIO_VOICE_MATILDA` / `_RIVER` / `_SHIMMER` / `_ADAM` — 페르소나별 reference_id
- (legacy) `ELEVENLABS_API_KEY` — 롤백 대비 유지, 삭제 금지

### Storage
- `tarot-cards` 버킷 (public) — 78장 PNG. URL: `{storageBase}/{suit}_{rank:02d}.png`

---

## File Structure

```
lib/
├── main.dart                     — 앱 진입점, TTS/Supabase 초기화, Talker 글로벌
├── core/
│   ├── config/ai_config.dart     — API 키, defaultModel: qwen3.5-flash
│   ├── services/supabase_service.dart — Supabase 초기화, 익명 인증, DB 저장
│   ├── observability/
│   │   └── talker_supabase_observer.dart — Talker → error_logs RPC (throttled, fail-silent)
│   └── tts/                      — 3모드 TTS
│       ├── tts_service.dart      — setVoice, speak, startLiveSession, 모드 전환
│       ├── tts_config.dart       — 17개 locale 속도/피치
│       ├── providers/            — local(flutter_tts), remote(Supabase→Fish Audio)
│       ├── remote/               — TtsRemoteClient, TtsAudioPlayer(임시파일!)
│       └── live/                 — Gemini Live WebSocket
├── models/
│   ├── tarot_card_data.dart      — 78장 카드 데이터 + imageUrl getter
│   ├── spread_type.dart          — 11개 스프레드 (free 9 + pro 1 + celticCross)
│   ├── reading_category.dart     — 5개 카테고리
│   └── oracle_persona.dart       — 4 페르소나 + voiceId 매핑
├── features/
│   ├── menu/pages/screens/       — 메뉴, 스프레드 선택
│   └── reading/
│       ├── catalog/              — OracleMessage, TarotCard, DrawCards A2UI 컴포넌트
│       ├── models/tarot_message.dart — 메시지 모델 (componentName, isError)
│       ├── services/
│       │   ├── transport.dart    — ContentGenerator, A2UI JSON 증분 파싱
│       │   └── ai_client.dart    — EdgeFunction/Gemini/RetryAiClient
│       ├── prompts/              — base, love, career, fortune, general, decision
│       └── pages/
│           ├── providers/tarot_session.dart — 핵심: Phase 상태 머신 + _setPhase() 가드
│           ├── screens/consultation_screen.dart — UI 오케스트레이션 + STT
│           └── widgets/          — card_fan, spread_display, chat_input, persona_selector 등
├── purchase/                     — RevenueCat IAP (placeholder 키)
├── shared/widgets/               — card_face(CachedNetworkImage), flip_card
└── i18n/                         — 17개 언어 JSON

knowledge/tarot/                  — 78장 카드 + 4규칙 JSON (AI 지식 DB 소스)
assets/cards/generated/           — 78장 카와이 동물 카드 이미지
supabase/functions/               — Edge Function 소스 (ai-tarot, tts, seed-knowledge)
supabase/migrations/              — 버전 마이그레이션 (NNNN_*.sql, append-only)
supabase/schema/                  — 리소스별 현재 정의 (tables/, rpc/, triggers/, policies/)
supabase/queries/                 — 대시보드/분석 쿼리
supabase/schema.sql               — [DEPRECATED] legacy 스냅샷 (수정 금지)
```

---

## Talker Log Tags (디버깅)

| Tag | File | What |
|-----|------|------|
| `[TarotSession]` | tarot_session.dart | Phase 전환 (`→`), 무효 전환 경고, AI 에러 |
| `[Transport]` | transport.dart | A2UI JSON 파싱, 컴포넌트 emit/drop, 90s 타임아웃 |
| `[EdgeFunction]` | ai_client.dart | SSE 파싱 실패, 45s 스트림 타임아웃 |
| `[RetryAiClient]` | ai_client.dart | retry 시도, fallback 전환 |
| `[Purchase]` | purchase_service.dart | 초기화, 구매 완료/실패, entitlement 판정 |
| `[Usage]` | usage_provider.dart | 오늘 사용량/남은 횟수, 프리미엄 무제한 |
| `[Gate]` | purchase_gate.dart | 허용/차단 판정 (remaining 값) |
| `[FlutterError]` / `[PlatformDispatcher]` / `[ZoneUncaught]` | main.dart | 전역 에러 핸들러 — TalkerSupabaseObserver 경유 error_logs 로 전송 |

---

## Persona & Voice 매핑

voice reference_id 는 **Supabase Secret 주입** (`FISH_AUDIO_VOICE_*`). 코드에 하드코딩 금지.

| 페르소나 | voiceId preset | 성별 | Secret env |
|---------|---------|------|-----------|
| 신비 현자 | matilda | 여성 | FISH_AUDIO_VOICE_MATILDA |
| 분석가 | river | 중성 | FISH_AUDIO_VOICE_RIVER |
| 친구 | shimmer | 여성 | FISH_AUDIO_VOICE_SHIMMER |
| 직설가 | adam | 남성 | FISH_AUDIO_VOICE_ADAM |

---

## 알려진 미해결 이슈

- **에뮬레이터 STT timeout** — 호스트 마이크 OFF가 기본. `emulator -avd <name> -allow-host-audio` 또는 `adb emu avd hostmicon`
- **Live 양방향 음성 미구현** — WebSocket 연결 성공, 텍스트 전송 가능. 마이크 PCM → WebSocket 직접 전송은 `record` 패키지 필요 (Phase 2).
- **RevenueCat 미연동** — placeholder 키 (`xxx` prefix → IAP 비활성화)
- **Release keystore 미생성** — `android/key.properties` + `upload-keystore.jks` 생성 필요. 없으면 `build.gradle.kts` 가 debug 서명으로 폴백.

---

## 남은 작업

1. `FISH_AUDIO_API_KEY` + 4 voice reference_id Supabase Secret 주입 (Dashboard > Edge Functions > Secrets)
2. 실기기 STT/TTS 테스트 + Fish Audio 한국어 청음 품질 확인
3. RevenueCat 대시보드 앱 생성 → API 키 → placeholder 교체
4. `dart run build_runner build` (purchase_provider.g.dart 등 codegen)
5. Release keystore 생성 (`keytool -genkey -keystore android/app/upload-keystore.jks ...`) + `android/key.properties` 작성
6. Android 앱 번들 / iOS archive → 스토어 제출
