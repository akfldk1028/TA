-- 리딩 세션 중 오간 대화 메시지 (role/content).
-- tarot_readings 1:N 관계. RLS 는 reading_id 경유 본인 소유 여부 검사.

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
