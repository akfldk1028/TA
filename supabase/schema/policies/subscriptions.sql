-- 본인 구독만 select/insert/update. 서버측 purchase webhook 은 service_role 로 우회.
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subscriptions_user_select"
  ON subscriptions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "subscriptions_user_insert"
  ON subscriptions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "subscriptions_user_update"
  ON subscriptions
  FOR UPDATE
  USING (auth.uid() = user_id);
