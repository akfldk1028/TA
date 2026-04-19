-- 모든 유저(익명 포함) 78장 지식 DB 읽기 허용.
ALTER TABLE tarot_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tarot_cards_public_read"
  ON tarot_cards
  FOR SELECT
  USING (true);
