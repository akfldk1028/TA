---
name: Supabase 폴더 구조 + 마이그레이션 규칙
description: 2026-04-16 재편 — migrations/schema/queries/functions 분리. 새 테이블 추가 체크리스트
type: architecture
---

# Supabase 폴더 구조 (2026-04-16 재편)

## 디렉토리

```
supabase/
├── migrations/              # append-only 버전드 (NNNN_<slug>.sql)
│   ├── 0001_initial_schema.sql   # 기존 DB baseline — re-apply 시 IF NOT EXISTS 덕분에 no-op
│   ├── 0002_user_profiles.sql    # apply 완료
│   └── 0003_error_logs.sql       # apply 완료
├── schema/                  # 리소스별 현재 정의 (리뷰/검색 레퍼런스)
│   ├── tables/              # 테이블 1 = 파일 1
│   │   ├── tarot_cards.sql
│   │   ├── tarot_rules.sql
│   │   ├── tarot_readings.sql
│   │   ├── tarot_messages.sql
│   │   ├── tarot_daily_usage.sql
│   │   ├── subscriptions.sql
│   │   ├── user_profiles.sql
│   │   └── error_logs.sql
│   ├── rpc/
│   │   ├── increment_tarot_usage.sql
│   │   └── log_app_error.sql
│   ├── triggers/
│   │   └── on_auth_user_created.sql
│   ├── policies/            # 테이블별 RLS
│   │   ├── tarot_cards.sql
│   │   ├── tarot_rules.sql
│   │   ├── tarot_readings.sql
│   │   ├── tarot_messages.sql
│   │   ├── tarot_daily_usage.sql
│   │   ├── subscriptions.sql
│   │   ├── user_profiles.sql
│   │   └── error_logs.sql       # 정책 없음 (클라 차단, service_role 만)
│   └── views/                    # 비어있음 — 확장 대비
├── queries/                 # 대시보드/분석용 SELECT
│   └── error_logs_recent.sql
├── functions/               # Edge Functions (Deno) — 런타임
│   ├── ai-tarot/
│   ├── tts/
│   └── seed-knowledge/
├── README.md                # 규칙 요약
└── schema.sql               # [DEPRECATED] legacy 단일 파일 — 수정 금지
```

## 규칙

1. **DB 변경 = `migrations/NNNN_*.sql` 새 파일 추가** (기존 수정 금지, append-only)
2. **`schema/<resource>/` 도 동일 내용으로 갱신** — 현재 상태 스냅샷
3. 파일명 규칙:
   - migrations: `NNNN_<slug>.sql` (4자리 순번)
   - tables: `<table_name>.sql`
   - rpc: `<function_name>.sql`
   - triggers: `on_<event>_<target>.sql`
   - policies: `<table_name>.sql` (테이블의 모든 policy 한 파일)
4. RLS 는 모든 public 테이블에 활성화. 정책은 `policies/` 에서 관리.
5. **`schema.sql` 수정 금지** — deprecated. 신규 프로젝트 부트스트랩은 `migrations/` 순차.

## 마이그레이션 적용

```
mcp__supabase-taro__apply_migration(
  name="<slug>",
  query="<migrations/<file>.sql 내용>"
)
```

- 이름은 snake_case, 순번 없이 slug 만. 서버 이력에 자동 타임스탬프 붙음.
- 적용 후 `mcp__supabase-taro__list_migrations` 로 확인.
- `apply_migration` 은 DDL 전용. DML/테스트는 `execute_sql`.

## 새 테이블 추가 체크리스트

1. `schema/tables/<name>.sql` 작성
2. `schema/policies/<name>.sql` 작성
3. RPC/트리거 필요하면 해당 폴더에도
4. `migrations/NNNN_<slug>.sql` 작성 — idempotent (`IF NOT EXISTS`, `DO $$ IF NOT EXISTS (pg_policies)`)
5. `apply_migration` 실행
6. `list_tables` 로 확인
7. (선택) `execute_sql` 로 테스트 INSERT / SELECT

## Idempotency 패턴

```sql
-- Table
CREATE TABLE IF NOT EXISTS foo (...);

-- Policy (CREATE POLICY IF NOT EXISTS 는 PG 15+ 에서만 → DO block 으로 우회)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename='foo' AND policyname='foo_read') THEN
    CREATE POLICY "foo_read" ON foo FOR SELECT USING (true);
  END IF;
END $$;

-- Function
CREATE OR REPLACE FUNCTION ...;

-- Trigger (DROP + CREATE 패턴)
DROP TRIGGER IF EXISTS t_name ON foo;
CREATE TRIGGER t_name ...;
```

## 왜 이렇게 했나

- 이전엔 `schema.sql` 단일 파일 → 어떤 변경이 언제 들어갔는지 추적 불가, diff 어려움.
- migrations = 이력, schema = 현재 상태 분리 → 리뷰/rollback 양쪽 대응.
- 신규 AI 세션이 "DB 어떻게 생겼지?" 알려면 `schema/tables/` 만 읽으면 됨. migrations 안 파도 됨.
