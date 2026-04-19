-- 유저별 일일 사용량 집계. increment_tarot_usage RPC 로 UPSERT.
-- UNIQUE(user_id, usage_date) 로 하루 1 row.

CREATE TABLE IF NOT EXISTS tarot_daily_usage (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  usage_date DATE DEFAULT CURRENT_DATE,
  reading_count INTEGER DEFAULT 0,
  token_count INTEGER DEFAULT 0,
  gemini_cost NUMERIC(10,6) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, usage_date)
);
