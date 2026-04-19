-- 클라이언트는 log_app_error RPC(SECURITY DEFINER)로만 INSERT.
-- 직접 INSERT/SELECT 는 차단 (service_role 만 우회).
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- 정책 없음 → RLS 활성 상태에서 public.role=anon/authenticated 는 모든 쿼리 거부.
-- service_role 은 RLS 무시하므로 관리자 콘솔/SQL editor 에서 자유 조회.
