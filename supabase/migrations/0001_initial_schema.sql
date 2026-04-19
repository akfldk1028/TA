-- 0001_initial_schema.sql
-- 기존 프로덕션 DB (niagjmqffibeuetxxbxp)에 이미 존재하는 오브젝트 baseline.
-- IF NOT EXISTS / OR REPLACE 덕분에 재적용해도 no-op. 새 Supabase 프로젝트 부트스트랩 시 최초 실행.
--
-- Prerequisites:
--   1. Dashboard > Authentication > Settings > Enable anonymous sign-ins
--   2. Dashboard > Storage > New bucket > "tarot-cards" (public)
--   3. Edge Function Secrets: QWEN_API_KEY, FISH_AUDIO_API_KEY + FISH_AUDIO_VOICE_*

-- ═══════════════════════════════════════════
-- Tables
-- ═══════════════════════════════════════════

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

CREATE TABLE IF NOT EXISTS tarot_rules (
  slug TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tarot_readings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  question TEXT,
  spread_type TEXT,
  cards JSONB,
  persona TEXT,
  locale TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tarot_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reading_id UUID REFERENCES tarot_readings(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  tokens_used INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tarot_messages_reading_id
  ON tarot_messages(reading_id);

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

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  product_id TEXT NOT NULL,
  platform TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  is_lifetime BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- ═══════════════════════════════════════════
-- RPC
-- ═══════════════════════════════════════════

CREATE OR REPLACE FUNCTION increment_tarot_usage(
  p_user_id UUID,
  p_reading_count INTEGER DEFAULT 0,
  p_token_count INTEGER DEFAULT 0,
  p_gemini_cost NUMERIC DEFAULT 0
) RETURNS VOID AS $$
BEGIN
  INSERT INTO tarot_daily_usage (user_id, usage_date, reading_count, token_count, gemini_cost)
  VALUES (p_user_id, CURRENT_DATE, p_reading_count, p_token_count, p_gemini_cost)
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET
    reading_count = tarot_daily_usage.reading_count + EXCLUDED.reading_count,
    token_count = tarot_daily_usage.token_count + EXCLUDED.token_count,
    gemini_cost = tarot_daily_usage.gemini_cost + EXCLUDED.gemini_cost;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════
-- Row Level Security
-- ═══════════════════════════════════════════

ALTER TABLE tarot_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_daily_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarot_cards' AND policyname='tarot_cards_public_read') THEN
    CREATE POLICY "tarot_cards_public_read" ON tarot_cards FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarot_rules' AND policyname='tarot_rules_public_read') THEN
    CREATE POLICY "tarot_rules_public_read" ON tarot_rules FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarot_readings' AND policyname='tarot_readings_user_select') THEN
    CREATE POLICY "tarot_readings_user_select" ON tarot_readings FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarot_readings' AND policyname='tarot_readings_user_insert') THEN
    CREATE POLICY "tarot_readings_user_insert" ON tarot_readings FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarot_messages' AND policyname='Users can CRUD own messages') THEN
    CREATE POLICY "Users can CRUD own messages" ON tarot_messages FOR ALL USING (
      reading_id IN (SELECT id FROM tarot_readings WHERE user_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarot_daily_usage' AND policyname='tarot_daily_usage_user_select') THEN
    CREATE POLICY "tarot_daily_usage_user_select" ON tarot_daily_usage FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscriptions' AND policyname='subscriptions_user_select') THEN
    CREATE POLICY "subscriptions_user_select" ON subscriptions FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscriptions' AND policyname='subscriptions_user_insert') THEN
    CREATE POLICY "subscriptions_user_insert" ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscriptions' AND policyname='subscriptions_user_update') THEN
    CREATE POLICY "subscriptions_user_update" ON subscriptions FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;
