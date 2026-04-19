-- 최근 24시간 에러 로그. 대시보드/오퍼레이션 용.
-- service_role 로 Supabase Studio SQL editor 에서 실행.

SELECT
  created_at,
  severity,
  tag,
  LEFT(message, 200) AS msg,
  platform,
  app_version,
  user_id
FROM error_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 500;

-- 태그별 집계
-- SELECT tag, severity, COUNT(*) AS n
-- FROM error_logs
-- WHERE created_at > NOW() - INTERVAL '7 days'
-- GROUP BY tag, severity
-- ORDER BY n DESC;
