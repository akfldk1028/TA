-- Add server-side rate limit to log_app_error RPC.
-- Client-side throttle in TalkerSupabaseObserver (20/min) is insufficient —
-- anon key is bundled in the APK, so a leaked key could flood error_logs.
--
-- Limits:
--   authenticated user: 30 rows/min per auth.uid()
--   anon:               60 rows/min globally (shared bucket)
-- Over-limit calls RETURN NULL silently (no exception — keeps fail-silent client contract).

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
  uid UUID := auth.uid();
  recent_count INT;
BEGIN
  IF p_severity NOT IN ('warning', 'error', 'critical') THEN
    RAISE EXCEPTION 'invalid severity: %', p_severity;
  END IF;

  IF uid IS NOT NULL THEN
    SELECT COUNT(*) INTO recent_count
    FROM error_logs
    WHERE user_id = uid
      AND created_at > NOW() - INTERVAL '1 minute';
    IF recent_count >= 30 THEN
      RETURN NULL;
    END IF;
  ELSE
    SELECT COUNT(*) INTO recent_count
    FROM error_logs
    WHERE user_id IS NULL
      AND created_at > NOW() - INTERVAL '1 minute';
    IF recent_count >= 60 THEN
      RETURN NULL;
    END IF;
  END IF;

  INSERT INTO error_logs (user_id, severity, tag, message, stack, context, app_version, platform)
  VALUES (
    uid,
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

-- Supporting index for the COUNT() scans (partial where created_at recent).
CREATE INDEX IF NOT EXISTS idx_error_logs_user_created
  ON error_logs (user_id, created_at DESC);