-- 본인 사용량만 조회. insert/update 는 RPC(SECURITY DEFINER)가 처리.
ALTER TABLE tarot_daily_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tarot_daily_usage_user_select"
  ON tarot_daily_usage
  FOR SELECT
  USING (auth.uid() = user_id);
