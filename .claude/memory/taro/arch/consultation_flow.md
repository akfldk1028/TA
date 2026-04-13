---
name: TARO Consultation Flow (전체 플로우)
description: 5-Phase 상태 머신 + FC preflight tool calling + 추가카드/새주제 + Talker 로깅
type: reference
---

## 전체 플로우 (2026-04-09 기준)

```
question → personaPick → picking → reading → chatting
                                      ↑          │
                            (additional) ←── picking ←┘
                                      ↑          │
                            (new_topic) → question ←┘
```

### Phase 상세

| Phase | 화면 | AI 호출 | 트리거 |
|-------|------|---------|--------|
| question | 큰 세리프 텍스트 + 추천 칩 | 없음 | 초기 진입 또는 new_topic |
| personaPick | 사용자 질문 표시 + 페르소나 선택 | 없음 | 사용자 질문 입력 |
| picking | 78장 3줄 카드 팬 | 없음 | 페르소나 확정 또는 additional |
| reading | SpreadDisplay + 카드별 해석 | OracleMessage + TarotCard | 카드 뽑기 완료 |
| chatting | SpreadDisplay + 자유 대화 | 사용자 메시지 기반 | 마지막 카드 해석 완료 |

### AI 호출 경로 (v4 — FC preflight)

```
TarotSession._sendToAi()
  → TaroContentGenerator.sendRequest()
    → RetryAiClient.sendStream()
      → EdgeFunctionAiClient → ai-tarot Edge Function v4
        [서버 내부]
        1. FC preflight (non-streaming, 최대 5회)
           → Qwen tool_call: get_card_knowledge("The Fool")
           → DB 조회 → 결과 주입 → Qwen 재호출
           → 최종 텍스트 답변 확보
        2. SSE 스트리밍 반환
      → [실패 시] retry 1회
      → [재실패 시] GeminiAiClient fallback
    → JSON 파싱: A2UI 블록 증분 emit
    → DrawCards/ReadingSummary 컴포넌트 필터링
```

### 하네스 (Harness) 가드

`_validTransitions` 맵으로 유효한 전이만 허용:
```dart
question → {personaPick}
personaPick → {picking}
picking → {reading}
reading → {chatting, picking}
chatting → {question, picking}
```

### 추가 카드 / 새 주제

- **Additional**: AI `DrawCards(context='additional')` → picking → reading → chatting
- **New Topic**: AI `DrawCards(context='new_topic')` → question (처음부터)

### 모드 선택

- **Auto**: AI가 순서대로 카드 뒤집기 + 해석 + TTS
- **Manual**: 사용자 탭 → 한 장씩 해석

### 핵심 파일

```
providers/tarot_session.dart      — Phase 상태 머신 + _setPhase() 가드
services/transport.dart           — ContentGenerator, A2UI JSON 파싱
services/ai_client.dart           — EdgeFunction/Gemini/RetryAiClient
prompts/prompt_builder.dart       — 시스템 프롬프트 조립
screens/consultation_screen.dart  — UI 오케스트레이션
```

**Why:** 실제 타로 상담 재현 — 질문 맥락 + 카드 지식 DB 기반 해석이 핵심 가치.
**How to apply:** 모든 phase 전환은 `_setPhase()` 경유, AI 호출은 RetryAiClient 경유.
