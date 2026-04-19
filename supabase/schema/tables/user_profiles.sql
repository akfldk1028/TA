-- 앱 사용자(타로보는사람) 프로필. auth.users 1:1 확장.
-- INSERT 는 on_auth_user_created 트리거가 자동 처리 → 클라이언트는 UPDATE 만.

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT,
  locale TEXT DEFAULT 'en',
  preferred_persona TEXT,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_fcm_token
  ON user_profiles(fcm_token)
  WHERE fcm_token IS NOT NULL;
