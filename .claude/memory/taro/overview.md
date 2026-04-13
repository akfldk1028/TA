---
name: TARO v2 Project Overview
description: A2UI 타로 앱 — Qwen AI + FC tool calling, 5-Phase 하네스, Supabase, 17개 언어
type: project
---

TARO v2는 하이브리드 아키텍처 타로 리딩 앱.
경로: `D:/Data/33_A2UI/A2UI/clone/TARO/`

**Why:** 진짜 타로 경험 — 유저가 직접 카드를 고르고 뒤집고, AI는 지식 DB 기반으로 해석.

**How to apply:** 카드 선택/뒤집기 = 네이티브 Flutter, 해석 = A2UI (GenUI 0.7.0)

## 아키텍처

```
MenuScreen → ConsultationScreen(질문→페르소나→카드뽑기→AI해석→채팅)
```

네비게이션: go_router
상태관리: Riverpod (ChangeNotifierProvider.autoDispose)
i18n: easy_localization (17개 언어, MultiFileAssetLoader)
AI: Qwen 3.5 Flash (DashScope) → Supabase Edge Function `ai-tarot` v4 (FC preflight + SSE)
로깅: talker_flutter + TalkerRiverpodObserver

## AI 리딩 플로우 (핵심)

```
Flutter → ai-tarot Edge Function v4
  1. FC preflight (non-streaming)
     → Qwen tool_call: get_card_knowledge("The Fool") → DB 조회
     → Qwen tool_call: get_combination_rules("elemental_dignities") → DB 조회
     → Qwen: 지식 참고하여 최종 답변 생성
  2. SSE 스트리밍으로 Flutter에 전달
     → Transport: A2UI JSON 파싱 → TarotCard/OracleMessage 위젯 렌더링
```

## 하네스 (Harness)

- `_setPhase()` + `_validTransitions` 맵: 유효한 phase 전환만 허용
- `RetryAiClient`: Edge Function → retry 1회 → GeminiAiClient fallback
- Talker 태그: `[TarotSession]`, `[Transport]`, `[EdgeFunction]`, `[RetryAiClient]`

## 기술 스택

| 분류 | 기술 |
|------|------|
| AI 모델 | **Qwen 3.5 Flash** (DashScope 싱가포르, $0.10/$0.40 per 1M) |
| AI 연동 | Edge Function FC preflight → tool calling → SSE streaming |
| 지식 DB | Supabase `tarot_cards` (78장 JSONB) + `tarot_rules` (4규칙) |
| State | Riverpod (ChangeNotifierProvider.autoDispose) |
| Routing | go_router |
| i18n | easy_localization (17개 언어) |
| DB | Hive (로컬) + Supabase (원격) |
| Storage | Supabase Storage `tarot-cards` 버킷 (78장 PNG) |
| Image | cached_network_image (Supabase Storage URL) |
| TTS | flutter_tts (local) + ElevenLabs (remote) + Gemini Live (live) |
| IAP | purchases_flutter (RevenueCat) |
| UI | A2UI GenUI 0.7.0 (TarotCard, OracleMessage) |

## 실행

```bash
cd D:/Data/33_A2UI/A2UI/clone/TARO
flutter pub get
flutter run -d emulator-5554 --dart-define-from-file=env.json
```

`env.json` (gitignored): `{"GEMINI_API_KEY":"...", "SUPABASE_URL":"https://niagjmqffibeuetxxbxp.supabase.co", "SUPABASE_ANON_KEY":"..."}`
