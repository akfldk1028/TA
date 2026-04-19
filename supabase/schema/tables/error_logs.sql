-- 앱 오류 원격 추적. 클라이언트는 log_app_error RPC 로만 INSERT.
-- SELECT 는 service_role 만 (대시보드/관리자). RLS 로 anon 차단.

CREATE TABLE IF NOT EXISTS error_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  severity TEXT NOT NULL CHECK (severity IN ('warning', 'error', 'critical')),
  tag TEXT NOT NULL,
  message TEXT NOT NULL,
  stack TEXT,
  context JSONB,
  app_version TEXT,
  platform TEXT CHECK (platform IN ('android', 'ios', 'web', 'other')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_error_logs_created_at
  ON error_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_error_logs_tag_severity
  ON error_logs(tag, severity, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_error_logs_user_id
  ON error_logs(user_id)
  WHERE user_id IS NOT NULL;
