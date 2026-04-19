-- 완료된 타로 리딩 세션 기록. SupabaseService.saveReading() 에서 insert.

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
