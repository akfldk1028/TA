-- 78장 타로 카드 지식 DB.
-- ai-tarot Edge Function 의 FC preflight 에서 `get_card_knowledge` tool 로 조회.

CREATE TABLE IF NOT EXISTS tarot_cards (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  suit TEXT NOT NULL,
  rank INTEGER NOT NULL,
  keywords TEXT[] DEFAULT '{}',
  upright_meanings TEXT[] DEFAULT '{}',
  reversed_meanings TEXT[] DEFAULT '{}',
  image_url TEXT,
  data JSONB,
  card_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(suit, rank)
);
