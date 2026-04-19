# TARO Memory Index

## Feedback (코딩 규칙)
- [feedback/math_layout.md](feedback/math_layout.md) — UI 배치 시 항상 수학적 계산 (하드코딩 금지)
- [feedback/no_drawcards_component.md](feedback/no_drawcards_component.md) — DrawCards 컴포넌트 UI 표시 안 함

## Overview
- [taro/overview.md](taro/overview.md) — 전체 아키텍처, 기술 스택, AI 리딩 플로우, 실행 방법
- [taro/app_direction.md](taro/app_direction.md) — 앱 방향성: A2UI 앱 번들의 첫 번째 앱
- [taro/next_steps.md](taro/next_steps.md) — 남은 작업: Secret 설정, 실기기 테스트, 앱 빌드

## Architecture & Harness
- [taro/arch/consultation_flow.md](taro/arch/consultation_flow.md) — 5-Phase 상태 머신 + FC preflight + 추가카드/새주제
- [taro/arch/ui_flow_v2.md](taro/arch/ui_flow_v2.md) — UI 위젯 구조, CachedNetworkImage 카드, 모드 선택
- [taro/arch/card_fan_ui.md](taro/arch/card_fan_ui.md) — 카드 팬: 78장 3줄, 수학적 radius 계산
- [taro/arch/harness_design.md](taro/arch/harness_design.md) — 하네스 설계 + Talker 로그 태그 맵 (디버깅 필독)
- [taro/arch/known_issues.md](taro/arch/known_issues.md) — 해결/미해결 이슈 패턴

## Backend & Supabase
- [taro/backend/backend_setup.md](taro/backend/backend_setup.md) — ai-tarot v4 (Qwen+FC) + DB 연동 (tables 섹션은 supabase_folder_structure 참조)
- [taro/backend/supabase_info.md](taro/backend/supabase_info.md) — Supabase MCP 연결 규칙 (supabase-taro 전용)
- [taro/backend/supabase_mcp_setup.md](taro/backend/supabase_mcp_setup.md) — MCP 인증, Edge Function 배포 상태
- [taro/backend/supabase_folder_structure.md](taro/backend/supabase_folder_structure.md) — **2026-04-16** migrations/schema/queries 재편 + 8테이블 인벤토리 + 새 테이블 추가 체크리스트
- [taro/backend/error_tracking.md](taro/backend/error_tracking.md) — **2026-04-16** error_logs + log_app_error RPC + TalkerSupabaseObserver 엔드투엔드

## Data & Knowledge
- [taro/data/data_notes.md](taro/data/data_notes.md) — tarot_data.json 구조, 표준화 상태
- [taro/data/tarot_knowledge.md](taro/data/tarot_knowledge.md) — Rider-Waite 78장 의미, 스프레드, 해석 원칙
- [taro/data/knowledge_system.md](taro/data/knowledge_system.md) — 78장+4규칙 DB 완료, FC tool calling 연동

## Design
- [taro/design/ai_model_config.md](taro/design/ai_model_config.md) — Qwen 3.5 Flash + FC preflight + tarot-tools
- [taro/design/advisor_design.md](taro/design/advisor_design.md) — 개발 시점 Claude Code advisor 3종(architect/reviewer/explorer) 설계. 런타임 Qwen과 무관
- [taro/design/branding.md](taro/design/branding.md) — ORACLE 브랜딩: 골드 타이포 로고, 아이콘 규격
- [taro/design/card_image_plan.md](taro/design/card_image_plan.md) — 78장 카와이 동물 이미지 파이프라인
- [taro/design/category_spreads.md](taro/design/category_spreads.md) — 5카테고리, 7 스프레드, DrawCards 트리거
- [taro/design/stitch_project.md](taro/design/stitch_project.md) — Stitch MCP 프로젝트, 디자인 시스템

## TTS
- [taro/tts/tts_module.md](taro/tts/tts_module.md) — core/tts/ 구조, local/remote/live 3모드
- [taro/tts/logic_review.md](taro/tts/logic_review.md) — Gemini Live camelCase 규칙
- [taro/tts/fish_audio_migration.md](taro/tts/fish_audio_migration.md) — **2026-04-16** ElevenLabs → Fish Audio S2 Phase 1 코드 완료 + Secret 주입 대기

## Gemini Live & STT
- [taro/live/gemini_live_findings.md](taro/live/gemini_live_findings.md) — WebSocket 제약사항, 모델명, setup 형식
- [taro/live/stt_setup.md](taro/live/stt_setup.md) — speech_to_text 권한, 에뮬레이터 마이크 설정

## Purchase
- [taro/purchase/purchase_module.md](taro/purchase/purchase_module.md) — RevenueCat IAP 폴더 구조, 상품 ID

## Production
- [taro/production/oracle_identity.md](taro/production/oracle_identity.md) — **2026-04-16** com.clickaround.oracle 전면 교체. keystore 생성만 대기
- [taro/production/api_key_security.md](taro/production/api_key_security.md) — **2026-04-16** GEMINI_API_KEY rotate 절차 + Android package restriction. env.json/dotenv 관리 규칙

## Code Review History
- [taro/review/code_review_log.md](taro/review/code_review_log.md) — 1차~3차 리뷰 수정 기록
- [taro/review/code_review_fixes.md](taro/review/code_review_fixes.md) — 4차~7차 리뷰: 하네스+Talker+버그 수정
