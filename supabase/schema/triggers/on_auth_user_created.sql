-- auth.users INSERT 시 user_profiles 자동 생성.
-- SECURITY DEFINER 로 auth 스키마 쓰기 권한 확보.

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
