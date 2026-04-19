-- 클라이언트에서 호출하는 단일 에러 로깅 진입점.
-- SECURITY DEFINER 로 RLS 우회 INSERT. auth.uid() 로 user_id 자동 채움 (anon 은 NULL).

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

-- anon 과 authenticated 에 실행 권한 부여 (RLS 는 INSERT 전에 함수 레벨에서 통과).
GRANT EXECUTE ON FUNCTION log_app_error(TEXT, TEXT, TEXT, TEXT, JSONB, TEXT, TEXT) TO anon, authenticated;
