---
name: TARO 하네스 + 프로젝트 이해 맵
description: 전체 레이어/파일 책임, AI 호출 체인, Talker 로그 태그, 디버깅 순서 — 프로젝트 첫 진입 시 필독
type: reference
---

이 문서 하나로 TARO 프로젝트의 런타임 흐름을 추적할 수 있어야 한다.
하네스(Harness) = AI 에이전트 오케스트레이션 인프라 (Anthropic/OpenAI/Fowler 용어).

## 1. 레이어 맵 (상위 → 하위)

```
┌───────────────────────────────────────────────────────────────┐
│ UI Layer                                                       │
│   consultation_screen.dart  ← 사용자 입력/STT, Phase별 위젯 분기 │
│   widgets/  card_fan, spread_display, chat_input, persona...   │
└──────────────────────────▲────────────────────────────────────┘
                           │ watch/read
┌──────────────────────────┴────────────────────────────────────┐
│ State Layer (Riverpod)                                         │
│   providers/tarot_session.dart   ← 5-Phase 상태머신 + _setPhase│
│   providers/usage_provider.dart  ← 일일 사용량 (code-gen)     │
│   providers/purchase_provider.dart ← IAP 상태 (code-gen)       │
└──────────────────────────▲────────────────────────────────────┘
                           │ sendRequest(stream)
┌──────────────────────────┴────────────────────────────────────┐
│ Transport / A2UI Layer                                          │
│   services/transport.dart        ← JSON 증분 파싱, 컴포넌트 emit │
│   catalog/ oracle_message, tarot_card, draw_cards              │
└──────────────────────────▲────────────────────────────────────┘
                           │ sendStream()
┌──────────────────────────┴────────────────────────────────────┐
│ AI Client Layer                                                │
│   services/ai_client.dart                                      │
│     RetryAiClient  → primary + retry 1회 → fallback            │
│     EdgeFunctionAiClient (primary)  → Supabase ai-tarot        │
│     GeminiAiClient (fallback)       → Gemini API 직접          │
└──────────────────────────▲────────────────────────────────────┘
                           │ POST /functions/v1/ai-tarot
┌──────────────────────────┴────────────────────────────────────┐
│ Backend (Supabase Edge Functions)                              │
│   ai-tarot v4 (ver 11)                                         │
│     Step 1: FC preflight (non-streaming, 최대 5 round)         │
│       Qwen tool_call ↔ get_card_knowledge / get_combination_rules│
│       → tarot_cards / tarot_rules DB 조회                      │
│     Step 2: SSE streaming (50자 청크) → Flutter                 │
│   tts v6: ElevenLabs multilingual v2 (7 voices)                │
└────────────────────────────────────────────────────────────────┘
```

## 2. 5-Phase 상태머신 (tarot_session.dart)

```
question → personaPick → picking → reading → chatting
                                     ↑          │
                                 (additional) ←─picking─┘
                                     ↑          │
                                 (new_topic) →─question─┘
```

- Phase 전환은 **반드시** `_setPhase(newPhase)` 경유. 직접 `_phase =` 할당 금지.
- `_validTransitions` 맵: 출발→목적지 화이트리스트. 무효 전환 시 `[TarotSession]` warning 로그 + ignored.
- AI 호출은 `reading` 진입 시 자동 트리거. `chatting`에서는 사용자 입력 마다.

## 3. AI 호출 체인 (단일 상담 1회)

1. `TarotSession._sendToAi(prompt, cards)` — system prompt 조립 (base + category + persona)
2. `TaroContentGenerator.sendRequest(messages, tools)` — A2UI JSON schema 포함
3. `RetryAiClient.sendStream(req)`
   - try primary (`EdgeFunctionAiClient`) → SSE 청크 yield*
   - fail → 1회 retry → 여전히 fail → `GeminiAiClient` fallback yield*
4. `Transport` — 청크를 `A2UIResponse` JSON으로 증분 파싱
   - `OracleMessage` / `TarotCard` 컴포넌트만 emit
   - `DrawCards` 컴포넌트는 UI 표시 안 함 (콜백만 처리)
5. 90s 타임아웃 → `[Transport] timeout` 로그 + 에러 메시지 (isError=true)

## 4. 파일별 책임 (핵심만)

| 경로 | 역할 | 건드릴 때 주의 |
|------|------|---------------|
| `lib/main.dart` | Hive/Supabase/TTS/Purchase 초기화, Talker 글로벌 | 초기화 순서 변경 금지 |
| `lib/app.dart` | MaterialApp, theme, go_router 주입 | |
| `lib/core/config/ai_config.dart` | `String.fromEnvironment` — env.json 키 바인딩 | dart-define 키명 고정 |
| `lib/core/services/supabase_service.dart` | init + 익명 auth, `useEdgeFunction` 게이트 | supabaseUrl 빈 값이면 init skip |
| `lib/core/tts/tts_service.dart` | 3모드(local/remote/live) 전환, voice 매핑 | `StreamAudioSource` 금지 — 임시파일 방식 |
| `lib/features/reading/pages/providers/tarot_session.dart` | 5-Phase 상태머신 (핵심!) | `_setPhase` 경유 강제 |
| `lib/features/reading/services/transport.dart` | A2UI JSON 증분 파싱, 컴포넌트 필터 | `DrawCards` drop 유지 |
| `lib/features/reading/services/ai_client.dart` | Retry/Fallback 체인 | `yield*` 스트리밍 보존 (await for로 재패키징 금지) |
| `lib/purchase/providers/purchase_provider.dart` | IAP 상태 + `_checkPremium()` 판정 | purchases_flutter 8.x API — `result`는 `CustomerInfo` 자체 |
| `lib/purchase/widgets/purchase_gate.dart` | 허용/차단 게이트 | `[Gate]` 로그로 근거 남길 것 |

## 5. Talker 로그 태그 맵

디버깅 시 태그로 필터링하면 된다.

### 상담 플로우 (하네스)

| 태그 | 파일 | 추적 내용 |
|------|------|----------|
| `[TarotSession]` | tarot_session.dart | Phase 전환 (`→`), 무효 전환 경고, AI 에러 |
| `[Transport]` | transport.dart | A2UI JSON 파싱, 컴포넌트 emit/drop, 90s 타임아웃 |
| `[EdgeFunction]` | ai_client.dart | SSE 파싱 실패, 45s 스트림 타임아웃 |
| `[RetryAiClient]` | ai_client.dart | retry 시도, fallback 전환 |

### 결제 시스템

| 태그 | 파일 | 추적 내용 |
|------|------|----------|
| `[Purchase]` | purchase_service.dart, purchase_provider.dart | 초기화, 구매/복원/entitlement 판정, forcePremium |
| `[PurchaseQueries]` | data/queries/ | Supabase 구독 조회 실패 |
| `[PurchaseMutations]` | data/mutations/ | Supabase 구매 기록 실패 |
| `[Usage]` | usage_provider.dart | 오늘 사용량/남은 횟수, 프리미엄 무제한 |
| `[Gate]` | purchase_gate.dart | 허용/차단 판정 (remaining 값 포함) |

### 자동 (TalkerRiverpodObserver)

모든 Riverpod Provider 생성/해제/상태변경 → `[riverpod-update]` 자동 로깅.

## 6. 디버깅 순서 (처음부터 따라가기)

1. **증상 확인** — 화면에서 어떤 동작이 안 되나? (카드 안 뜸 / AI 응답 없음 / Phase stuck / 결제 실패)
2. **태그 필터** — 섹션 5의 태그 맵에서 해당 레이어 찾기
3. **타임라인 재구성** — Talker 화면 = 시간순 스트림. 해당 태그 + `[riverpod-update]` 교차 참조
4. **레이어 하강** — UI → State → Transport → AI Client → Edge Function 순
5. **Edge Function 로그** — 클라이언트에서 안 잡히면 Supabase Dashboard > Functions > Logs

### 증상별 진입 태그

| 증상 | 1차 태그 | 2차 태그 |
|------|----------|----------|
| AI 응답 안 옴 | `[Transport]` | `[EdgeFunction]`, `[RetryAiClient]` |
| 카드 해석 멈춤 | `[TarotSession]` | `[Transport]` (90s timeout) |
| Phase 갇힘 | `[TarotSession]` | `_validTransitions` 맵 확인 |
| 무료 횟수 이상 | `[Usage]` | `[Gate]` |
| 구매 완료됐는데 프리미엄 아님 | `[Purchase]` | `_checkPremium` reason 확인 |
| TTS 무음 | 직접 println 로그 | just_audio 에러 스택 |

## 7. 주요 불변식 (깨지면 시스템 망가짐)

- **Phase 전환은 `_setPhase()` 경유** (직접 할당 금지)
- **AI 호출은 `RetryAiClient` 경유** (primary 직접 호출 금지)
- **스트림은 `yield*`로 전달** (await-for로 수집해서 재emit 금지 — 증분 렌더 깨짐)
- **DrawCards 컴포넌트 UI 표시 안 함** (transport에서 필터)
- **UI 좌표는 수학적 계산** (하드코딩 금지, feedback/math_layout.md 참조)
- **StreamAudioSource 금지** (Android ExoPlayer Source error — 임시파일 방식만)
- **Gemini Live WebSocket은 camelCase + `responseModalities: ['AUDIO']` only**

## 8. isPremium 판정 로직 (purchase_provider.dart `_checkPremium`)

`(bool isPremium, String reason)` 반환:
1. entitlement (구독만 신뢰, 시간제 제외) → `entitlement:{pid}`
2. activeSubscriptions (monthly) → `activeSub:monthly`
3. nonSubscriptionTransactions (시간 기반) → `timeBased:{pid}`
4. forcePremium fallback → `forcePremium:{pid}`
5. 없음 → `free`

**로그에 항상 reason 포함** — 왜 프리미엄으로 판정됐는지 추적 가능.