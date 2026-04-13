---
name: DrawCards 컴포넌트 UI 표시 제거
description: AI가 DrawCards A2UI 컴포넌트를 생성해도 UI에 표시하지 않음 — 카드+해석만 보여주기
type: feedback
---

DrawCards A2UI 컴포넌트를 채팅 UI에 표시하지 않음. 카드 뽑기는 앱 로직이 처리하고, AI는 해석(TarotCard + OracleMessage)만 담당.

**Why:** AI가 "카드를 뽑아주세요" 메시지를 중복 생성하여 혼란. 카드 뽑기는 picking phase에서 이미 처리됨.

**How to apply:** transport.dart에서 DrawCards 컴포넌트는 콜백으로만 처리(추가 뽑기 트리거 용), UI 메시지로는 표시하지 않음. AI 응답에서 카드 + 해석 텍스트만 화면에 표시.
