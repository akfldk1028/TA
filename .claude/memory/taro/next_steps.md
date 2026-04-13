---
name: TARO 다음 작업 목록
description: 2026-04-09 — Qwen+FC tool calling 완료. 남은: Secret 설정, 실기기 테스트, 앱 빌드
type: project
---

## 완료 (2026-04-09)

- **AI 모델 전환**: Gemini → Qwen 3.5 Flash (DashScope)
- **FC preflight tool calling**: SJ saju-tools 패턴 적용
  - get_card_knowledge(card_name) — DB에서 카드 지식 조회
  - get_combination_rules(rule_type) — 조합 규칙 조회
- **타로 지식 시스템 완성**:
  - Minor Arcana 56장 JSON 생성 (wands/cups/swords/pentacles 각 14장)
  - DB 삽입 78장 + 4규칙 (seed-knowledge Edge Function 활용)
  - tarot_cards 테이블에 `data` JSONB + `card_id` TEXT 컬럼 추가
  - pentacles: DB name "Coins" → "Pentacles" 수정
- ai-tarot Edge Function v4 배포 (version 11)
- Flutter ai_config.dart: defaultModel → 'qwen3.5-flash'

## 완료 (2026-04-08)

- Flutter i18n 17개 언어 전면 리팩토링
- Major Arcana 22장 + rules 4개 JSON 생성

## 다음 (미완료)

### 즉시 (배포 전)
1. **QWEN_API_KEY** Supabase Secret 설정 — Dashboard > Settings > Edge Functions > Secrets
2. **실기기 테스트** — AI가 tool_call로 카드 지식 조회하는지 확인 (Edge Function 로그)
3. **seed-knowledge Edge Function 삭제** — 일회용이므로 사용 후 제거

### 중기
4. **RevenueCat 설정** — 대시보드 앱 → API 키 → purchase_config.dart
5. **codegen** — `dart run build_runner build`
6. **스토어 상품 등록** — Google Play / App Store Connect
7. **Live 양방향 음성** — record 패키지 PCM → WebSocket

### 앱 런칭
8. **실기기 STT 검증** — 에뮬레이터 마이크 미작동
9. **로컬 assets/cards/ 정리** — 가라 이미지 삭제
10. **Android/iOS 빌드** — 앱 아이콘, 스플래시
