---
name: TARO 다음 작업 목록
description: 2026-04-16 세션 — 배포 전체 배선 완료 (DB 확장 + 에러 추적 + 앱 정체성 + Fish Audio). 사용자 수동 작업 대기
type: project
---

## 완료 (2026-04-16 세션)

### Supabase 폴더 체계화

- `supabase/migrations/` (append-only), `supabase/schema/{tables,rpc,triggers,policies,views}`, `supabase/queries/` 재편
- 기존 5테이블 + 1 RPC + RLS 를 리소스별로 분리
- `supabase/README.md` 폴더 규칙 + 마이그레이션 실행법
- `supabase/schema.sql` DEPRECATED 표시

### DB 확장 (2 테이블 추가, 마이그레이션 apply 완료)

- `user_profiles` — 앱 사용자 프로필 (auth.users 트리거 `on_auth_user_created` 로 자동 생성)
- `error_logs` — 원격 에러 추적 (RLS 정책 없음 → 클라 직접 접근 차단)
- `log_app_error(...)` RPC (SECURITY DEFINER, anon/authenticated EXECUTE)

### 클라이언트 에러 훅

- `lib/core/observability/talker_supabase_observer.dart` — 신규. Talker → Supabase RPC.
- `lib/core/services/supabase_service.dart` — `logError()` 메서드 추가
- `lib/main.dart` — `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` + observer 등록. throttle 20/min. fail-silent.

### TTS Fish Audio Phase 1 코드 완료

- `supabase/functions/tts/index.ts` — Fish Audio S2 전환 완료 (클라 API 시그니처 유지)
- `lib/main.dart`, `CLAUDE.md`, `schema.sql` 주석/표 동기화
- Gemini fallback 제거 (`tarot_session.dart:31` primary only)

### 앱 정체성 교체 (Oracle / com.clickaround.oracle)

- Android: `build.gradle.kts` applicationId/namespace, `AndroidManifest.xml` label/권한정리, MainActivity 이동
- iOS: `project.pbxproj` 6 bundle ID, `Info.plist` CFBundleDisplayName/Name
- `.gitignore`: keystore 관련 추가
- signingConfig: release 블록 배선 (key.properties 존재 시 활성, 없으면 debug 폴백)

### 문서/메모리

- CLAUDE.md 전면 갱신 (Edge Functions, DB Tables, RPC, Secrets, Persona, 남은 작업)
- 전역 메모리 폴더화 (feedback/, project/, reference/) + 상세화
- 프로젝트 메모리 taro/ 하위에 `backend/supabase_folder_structure.md`, `backend/error_tracking.md`, `tts/fish_audio_migration.md`, `production/oracle_identity.md` 신규

## 🔴 다음 세션 즉시 해야 할 것 (사용자 수동)

### 1. Release keystore 생성

```bash
cd C:/DK/TA/TA/android/app
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

→ `android/key.properties` 작성 (storePassword/keyPassword/keyAlias=upload/storeFile=app/upload-keystore.jks). 자세한 건 `.claude/memory/taro/production/oracle_identity.md`.

### 2. Supabase Edge Function Secrets 주입

Dashboard (supabase-taro) > Settings > Edge Functions > Secrets:
- `FISH_AUDIO_API_KEY`
- `FISH_AUDIO_VOICE_MATILDA` / `_RIVER` / `_SHIMMER` / `_ADAM`

Secret 없으면 tts Edge Function 이 500 반환. 자세한 건 `.claude/memory/taro/tts/fish_audio_migration.md`.

### 3. 검증 빌드

```bash
flutter clean && flutter pub get
flutter build apk --debug    # rename 검증
flutter build appbundle --release  # keystore 연결 후
```

### 4. 실기기 TTS 청음 검증

- 페르소나 4명 speak → Fish Audio 한국어 품질 확인
- 자연어 태그 (`[whisper]`, `[professional tone]`) 반응 체크

## 중기

- **RevenueCat API 키** — 대시보드 앱 생성 후 placeholder 교체 (`lib/purchase/purchase_config.dart` 유사 파일)
- **`dart run build_runner build`** — `purchase_provider.g.dart`, `usage_provider.g.dart` 등 codegen
- **개인정보 처리방침 / 이용약관 URL** — Play Store / App Store 제출 필수

## 장기

- **Phase 2 TTS**: Gemini Live API Supabase WebSocket proxy (마이크 PCM → WebSocket)
- **에러 대시보드**: Supabase Studio SQL editor 북마크 → Retool/Metabase 또는 PostHog
- **severity=critical Slack 알림** Edge Function
- **로컬 `assets/cards/` 가라 이미지 정리**

## 이전 완료 (이력)

### 2026-04-14
- Flutter 3.41.6 + Dart 3.11.0 업그레이드, purchases_flutter 8.x API 마이그레이션, build_runner codegen 복구
- Supabase MCP 레포별 분리 (TA=supabase-taro, MOL=supabase-mol, user-scope 제거)

### 2026-04-09
- AI 모델 Gemini → Qwen 3.5 Flash, FC preflight tool calling, 지식 DB 완성 (78장+4규칙)
- ai-tarot Edge Function v4 배포

### 2026-04-08
- Flutter i18n 17개 언어 리팩토링, Major Arcana 22장 + rules 4개 JSON 생성
