---
name: TARO v2 Project Overview
description: A2UI 타로 앱 — Qwen AI + FC tool calling, 5-Phase 하네스, Supabase, 17개 언어
type: project
---

TARO v2 (package: `taro_a2ui`)는 하이브리드 아키텍처 타로 리딩 앱.
경로: `C:/DK/TA/TA/`

**Why:** 진짜 타로 경험 — 유저가 직접 카드를 고르고 뒤집고, AI는 지식 DB 기반으로 해석.

**How to apply:** 카드 선택/뒤집기 = 네이티브 Flutter, 해석 = A2UI (GenUI 0.7.0)

## 아키텍처

```
MenuScreen → ConsultationScreen(질문→페르소나→카드뽑기→AI해석→채팅)
```

네비게이션: go_router
상태관리: Riverpod (ChangeNotifierProvider.autoDispose + code-gen Notifier)
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

`arch/harness_design.md` 참조. 요약:
- `_setPhase()` + `_validTransitions` 맵: 유효한 phase 전환만 허용
- `RetryAiClient`: Edge Function → retry 1회 → GeminiAiClient fallback
- Talker 태그: `[TarotSession]`, `[Transport]`, `[EdgeFunction]`, `[RetryAiClient]`, `[Purchase]`, `[Usage]`, `[Gate]`

## 기술 스택

| 분류 | 기술 |
|------|------|
| Flutter SDK | 3.41.6 stable (Dart 3.11.0) — 필수 최소 버전 |
| AI 모델 | **Qwen 3.5 Flash** (DashScope 싱가포르, $0.10/$0.40 per 1M) |
| AI 연동 | Edge Function FC preflight → tool calling → SSE streaming |
| 지식 DB | Supabase `tarot_cards` (78장 JSONB) + `tarot_rules` (4규칙) |
| State | Riverpod 2.6 + riverpod_generator (code-gen Notifier) |
| Routing | go_router 14 |
| i18n | easy_localization (17개 언어) |
| DB | Hive (로컬) + Supabase (원격) |
| Storage | Supabase Storage `tarot-cards` 버킷 (78장 PNG) |
| Image | cached_network_image (Supabase Storage URL) |
| TTS | flutter_tts (local) + ElevenLabs (remote) + Gemini Live (live) |
| IAP | purchases_flutter **8.11** (RevenueCat) |
| UI | A2UI GenUI 0.7.0 (TarotCard, OracleMessage) |

## 실행

```bash
cd C:/DK/TA/TA
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 최초/providers 수정 후 필수
flutter run -d <device> --dart-define-from-file=env.json
```

`env.json` (gitignored):
```json
{
  "GEMINI_API_KEY": "...",
  "SUPABASE_URL": "https://niagjmqffibeuetxxbxp.supabase.co",
  "SUPABASE_ANON_KEY": "..."
}
```

## 주의 사항 (최근 hand-off)

- **purchases_flutter 8.x API 변경**: `Purchases.purchasePackage()` 는 이제 `CustomerInfo`를 직접 반환. `result.customerInfo` 접근 금지 — `result` 자체가 CustomerInfo. (2026-04-14 수정)
- **riverpod codegen 산출물(.g.dart)은 gitignored 아님** — 누락 시 빌드 실패. pub get 직후 build_runner 반드시 실행.
- **Flutter 3.38 이하 사용 금지** — pubspec SDK constraint `^3.11.3` 때문에 해결 실패.