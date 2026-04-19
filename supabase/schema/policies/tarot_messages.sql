-- reading_id 로 본인 리딩 소속 확인 → 전체 CRUD 허용.
ALTER TABLE tarot_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own messages"
  ON tarot_messages
  FOR ALL
  USING (
    reading_id IN (
      SELECT tarot_readings.id
      FROM tarot_readings
      WHERE tarot_readings.user_id = auth.uid()
    )
  );
