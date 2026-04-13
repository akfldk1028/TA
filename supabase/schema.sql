-- TARO (ORACLE) Supabase Schema
-- Project: niagjmqffibeuetxxbxp
-- Run this on a fresh Supabase project to set up all tables, RLS, and functions.
--
-- Prerequisites:
--   1. Enable anonymous auth: Dashboard > Authentication > Settings > Enable anonymous sign-ins
--   2. Create storage bucket: Dashboard > Storage > New bucket > "tarot-cards" (public)
--   3. Set Edge Function Secrets: QWEN_API_KEY, ELEVENLABS_API_KEY

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
-- RPC Functions
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
-- Row Level Security (RLS)
-- ═══════════════════════════════════════════

ALTER TABLE tarot_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarot_daily_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tarot_cards_public_read" ON tarot_cards FOR SELECT USING (true);
CREATE POLICY "tarot_rules_public_read" ON tarot_rules FOR SELECT USING (true);
CREATE POLICY "tarot_readings_user_select" ON tarot_readings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tarot_readings_user_insert" ON tarot_readings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tarot_daily_usage_user_select" ON tarot_daily_usage FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "subscriptions_user_select" ON subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "subscriptions_user_insert" ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "subscriptions_user_update" ON subscriptions FOR UPDATE USING (auth.uid() = user_id);
