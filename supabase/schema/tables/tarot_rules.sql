-- 4개 타로 조합 규칙 (elemental dignities 등). slug PK.
-- ai-tarot FC preflight 에서 `get_combination_rules` tool 로 조회.

CREATE TABLE IF NOT EXISTS tarot_rules (
  slug TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
