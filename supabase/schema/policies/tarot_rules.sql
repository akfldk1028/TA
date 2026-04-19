-- 조합 규칙 공개 읽기.
ALTER TABLE tarot_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tarot_rules_public_read"
  ON tarot_rules
  FOR SELECT
  USING (true);
