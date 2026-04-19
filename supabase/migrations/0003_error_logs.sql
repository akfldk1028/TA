-- 0003_error_logs.sql
-- 앱 오류 원격 추적 테이블 + log_app_error RPC.

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

ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;
-- 정책 없음 → anon/authenticated 는 직접 SELECT/INSERT 차단. RPC 만 허용.

CREATE OR REPLACE FUNCTION log_app_error(
  p_severity TEXT,
  p_tag TEXT,
  p_message TEXT,
  p_stack TEXT DEFAULT NULL,
  p_context JSONB DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL,
  p_platform TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  new_id UUID;
BEGIN
  IF p_severity NOT IN ('warning', 'error', 'critical') THEN
    RAISE EXCEPTION 'invalid severity: %', p_severity;
  END IF;

  INSERT INTO error_logs (user_id, severity, tag, message, stack, context, app_version, platform)
  VALUES (
    auth.uid(),
    p_severity,
    p_tag,
    LEFT(p_message, 2000),
    LEFT(COALESCE(p_stack, ''), 8000),
    p_context,
    p_app_version,
    COALESCE(p_platform, 'other')
  )
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION log_app_error(TEXT, TEXT, TEXT, TEXT, JSONB, TEXT, TEXT) TO anon, authenticated;
