-- 본인 리딩만 조회/추가.
ALTER TABLE tarot_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tarot_readings_user_select"
  ON tarot_readings
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "tarot_readings_user_insert"
  ON tarot_readings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
