-- 0002_user_profiles.sql
-- 앱 사용자 프로필 테이블 + auth.users 트리거.

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

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_profiles' AND policyname='user_profiles_self_select') THEN
    CREATE POLICY "user_profiles_self_select" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_profiles' AND policyname='user_profiles_self_update') THEN
    CREATE POLICY "user_profiles_self_update" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

-- 트리거 함수: auth.users INSERT → user_profiles 자동 생성
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id, locale)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'locale', 'en')
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 기존 auth.users 에 대해 백필 (현재 DB 의 anon 유저들)
INSERT INTO public.user_profiles (user_id, locale)
SELECT id, 'en'
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public.user_profiles);
