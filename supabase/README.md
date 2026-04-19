# Supabase Backend — 오라클 (TARO)

Project ref: `niagjmqffibeuetxxbxp`

## 폴더 구조

```
supabase/
├── migrations/        # append-only 이력. 이름: NNNN_<slug>.sql
│   ├── 0001_initial_schema.sql
│   ├── 0002_user_profiles.sql
│   └── 0003_error_logs.sql
├── schema/            # 리소스별 현재 정의 (리뷰/검색용 참조)
│   ├── tables/        # 테이블 1개당 1 파일
│   ├── rpc/           # SECURITY DEFINER 함수들
│   ├── triggers/      # auth / 도메인 트리거
│   ├── policies/      # RLS 정책 (테이블별)
│   └── views/         # (비어있음 — 확장 대비)
├── queries/           # 대시보드/분석용 select 쿼리
├── functions/         # Edge Functions (Deno)
│   ├── ai-tarot/
│   ├── tts/
│   └── seed-knowledge/
├── README.md          # 이 파일
├── config.toml        # Supabase CLI 설정
└── schema.sql         # [DEPRECATED] legacy 단일파일. schema/ 와 migrations/ 우선.
```

## 규칙

1. **DB 변경은 반드시 `migrations/NNNN_*.sql` 로 먼저 추가** — 기존 파일 수정 금지.
2. **변경 후 `schema/<resource>/` 쪽 파일도 동일하게 갱신** (현재 상태 스냅샷 역할).
3. **파일명 규칙**
   - migrations: `NNNN_<slug>.sql` (4자리 순번)
   - tables: `<table_name>.sql`
   - rpc: `<function_name>.sql`
   - triggers: `on_<event>_<target>.sql`
   - policies: `<table_name>.sql` (해당 테이블의 모든 policy 한 파일)
4. **RLS는 모든 public 테이블에 활성화**. 정책은 `policies/` 에서 관리.
5. **`schema.sql` 은 수정 금지** — legacy 참조 전용. 신규 프로젝트 부트스트랩은 `migrations/` 순차 실행.

## 마이그레이션 적용

Claude Code MCP 경유:
```
mcp__supabase-taro__apply_migration(
  name="0002_user_profiles",
  query="<migrations/0002_user_profiles.sql 의 내용>"
)
```

적용 순서는 파일명 순번 그대로. 배포 후엔 `mcp__supabase-taro__list_migrations` 로 서버 상태 확인.

## Secrets (Dashboard > Settings > Edge Functions)

| Secret | 용도 |
|---|---|
| `QWEN_API_KEY` | ai-tarot Edge Function — DashScope Qwen 3.5 Flash |
| `FISH_AUDIO_API_KEY` | tts Edge Function — Fish Audio S2 |
| `FISH_AUDIO_VOICE_MATILDA` | 신비 현자 (여성) reference_id |
| `FISH_AUDIO_VOICE_RIVER` | 분석가 (중성) reference_id |
| `FISH_AUDIO_VOICE_SHIMMER` | 친구 (여성) reference_id |
| `FISH_AUDIO_VOICE_ADAM` | 직설가 (남성) reference_id |

`ELEVENLABS_API_KEY` 는 롤백 대비용으로 당분간 유지 (삭제 금지).

## Storage

- `tarot-cards` (public 버킷) — 78장 PNG. URL: `{SUPABASE_URL}/storage/v1/object/public/tarot-cards/{suit}_{rank:02d}.png`
