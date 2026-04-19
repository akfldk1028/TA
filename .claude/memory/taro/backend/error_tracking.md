---
name: 원격 에러 추적 — error_logs + log_app_error RPC + TalkerSupabaseObserver
description: 앱 오류 Supabase 로 업로드하는 엔드투엔드 흐름. 2026-04-16 도입
type: architecture
---

# 원격 에러 추적

## 동인

런칭 이후 로컬 Talker 콘솔만으로는 사용자 기기 오류 파악 불가. 서버 집계 필수.
경량 테이블 + RPC 만으로 Sentry 급 기능 일부 대체 (대시보드는 Supabase Studio SQL editor 북마크).

## 흐름

```
[Dart exception / error]
  ↓
FlutterError.onError          (UI 렌더링 에러)
PlatformDispatcher.onError    (async/platform 에러)
runZonedGuarded 핸들러         (기타 zone 에러)
  ↓  (전부 main.dart 에 등록)
talker.handle(error, stack, <source-tag>)
  ↓
TalkerSupabaseObserver.onError / onException
  ↓  throttle check (max 20 events / min, sliding window)
  ↓  platform detect (kIsWeb / Platform.isAndroid / isIOS)
SupabaseService.logError(severity, tag, message, stack, context, appVersion, platform)
  ↓  client.rpc('log_app_error', params)
log_app_error(...)  [PG SECURITY DEFINER]
  ↓  auth.uid() 자동 user_id
  ↓  LEFT(message, 2000) / LEFT(stack, 8000) 트렁케이트
INSERT INTO error_logs
```

## 서버

- `supabase/schema/tables/error_logs.sql` — 컬럼 + 인덱스
- `supabase/schema/policies/error_logs.sql` — **정책 없음** (anon/authenticated SELECT/INSERT 차단)
- `supabase/schema/rpc/log_app_error.sql` — SECURITY DEFINER + `GRANT EXECUTE TO anon, authenticated`
- 적용 마이그레이션: `supabase/migrations/0003_error_logs.sql`

Severity CHECK: `warning | error | critical`.
Platform CHECK: `android | ios | web | other`.

## 클라

| 파일 | 역할 |
|---|---|
| `lib/core/observability/talker_supabase_observer.dart` | TalkerObserver 서브클래스 + throttle/platform detect |
| `lib/core/services/supabase_service.dart` (`logError` 메서드) | RPC 호출 래퍼. fail-silent. |
| `lib/main.dart` | `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` + observer 등록 |

**등록 순서 중요**: observer 는 `SupabaseService.init()` 완료 후 `talker.configure(observer: ...)`. 이전에 걸면 첫 logError 가 client null 접근.

## App Version

`lib/main.dart`:
```dart
const String kAppVersion = '1.0.0+1';  // pubspec.yaml version 과 동기화
```

`package_info_plus` 미도입. pubspec version 변경 시 이 상수도 같이 수정.

## 운영 쿼리

`supabase/queries/error_logs_recent.sql`:
```sql
SELECT created_at, severity, tag, LEFT(message, 200) msg, platform, app_version, user_id
FROM error_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC LIMIT 500;
```

Supabase Studio SQL editor (service_role 권한) 에서 실행. 대시보드 붙일 거면 Retool/Metabase 연결.

## 하지 말 것

- **PII 넣지 마라** — `message`/`context` 에 사용자 질문 원문, auth 토큰, 이메일 금지.
- **직접 INSERT 금지** — 클라는 RPC 만. anon 이 INSERT 시 401.
- **재시도 큐 만들지 마라** — best-effort. 네트워크 실패해도 로컬 Talker 에는 남음.
- **throttle 해제 금지** — 20/min 은 스팸 억제. 풀면 급격한 로그 폭증.

## 확장 포인트

- `context` 에 `phase`, `endpoint`, `retry_count` 등 자유 구조. JSONB 인덱스 필요해지면 GIN 추가.
- severity='critical' 이면 Slack webhook 알림 Edge Function 추가 (TODO).
- 유저별 오류 집계: `SELECT user_id, COUNT(*) FROM error_logs GROUP BY user_id ORDER BY 2 DESC` — 반복 크래시 유저 식별.
