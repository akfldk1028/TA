# ORACLE (taro_a2ui) — AI Tarot Reading App

## Quick Start

```bash
flutter pub get
flutter run -d <device> --dart-define-from-file=env.json
```

`env.json` (gitignored): `{"GEMINI_API_KEY":"...", "SUPABASE_URL":"https://niagjmqffibeuetxxbxp.supabase.co", "SUPABASE_ANON_KEY":"..."}`

## Architecture

Flutter 앱. A2UI(GenUI 0.7.0) 기반 타로 상담.

```
MenuScreen → ConsultationScreen (5-Phase 상태 머신)
  question → personaPick → picking → reading → chatting
```

- **AI**: Qwen 3.5 Flash (DashScope) → Supabase Edge Function `ai-tarot` v4 (FC preflight + SSE)
- **TTS**: flutter_tts(local) + ElevenLabs(remote) + Gemini Live(live)
- **State**: Riverpod (ChangeNotifierProvider.autoDispose)
- **i18n**: easy_localization (17개 언어)
- **IAP**: RevenueCat (purchases_flutter)

## Key Rules

- **UI 배치는 수학적 계산** — 하드코딩 금지. 경계 조건 → 역산 공식 사용.
- **DrawCards 컴포넌트 UI 미표시** — 카드+해석만 보여줌. transport.dart에서 콜백만 처리.
- **StreamAudioSource 쓰지 마라** — Android ExoPlayer Source error. 임시파일 재생만 사용.
- **JSON 키 `audioBase64`** — `audio` 아님 (Edge Function 응답 키)
- **WebSocket 응답 `Uint8List`** — `utf8.decode()` 필수, `as String` 불가
- **`responseModalities: ['AUDIO']` only** — `TEXT` 포함 시 1007 에러
- **Gemini Live는 camelCase JSON** — raw WebSocket은 proto3 매핑, snake_case 불가
- **TARO Supabase MCP**: `mcp__supabase-taro__*` 전용. 다른 Supabase MCP 혼용 금지.

## Supabase

- **Project**: `niagjmqffibeuetxxbxp`
- **Edge Functions**: `ai-tarot` v4 (Qwen FC preflight + SSE), `tts` v6 (ElevenLabs)
- **DB**: tarot_readings, tarot_messages, tarot_daily_usage, tarot_cards (78장 JSONB), tarot_rules (4규칙)
- **Storage**: `tarot-cards` 버킷 (78장 PNG, public)
- **Secrets**: QWEN_API_KEY, ELEVENLABS_API_KEY

## File Structure

```
lib/
├── core/tts/           — 3모드 TTS (local/remote/live)
├── core/services/      — SupabaseService
├── core/config/        — ai_config.dart (defaultModel: qwen3.5-flash)
├── features/reading/   — 상담 핵심 (catalog, models, pages, prompts, services)
├── features/menu/      — 메뉴 화면
├── i18n/               — 17개 언어
├── models/             — spread_type, tarot_card_data, oracle_persona
├── purchase/           — RevenueCat IAP
└── shared/widgets/     — card_face, flip_card
knowledge/tarot/        — 78장 카드 + 4규칙 JSON (AI 지식 DB)
assets/cards/generated/ — 78장 카와이 동물 카드 이미지
```

## Talker Log Tags

| Tag | File | What |
|-----|------|------|
| `[TarotSession]` | tarot_session.dart | Phase 전환, AI 에러 |
| `[Transport]` | transport.dart | A2UI JSON 파싱, 90s 타임아웃 |
| `[EdgeFunction]` | ai_client.dart | SSE 파싱, 45s 타임아웃 |
| `[RetryAiClient]` | ai_client.dart | retry/fallback |
| `[Purchase]` | purchase_service.dart | 구매, entitlement |
| `[Usage]` | usage_provider.dart | 사용량/남은 횟수 |

## Memory

상세 메모리: `.claude/memory/` 참조
