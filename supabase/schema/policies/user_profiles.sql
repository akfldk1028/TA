-- 본인 프로필만 읽기/수정. INSERT 는 트리거 담당이라 정책 없음.
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_profiles_self_select"
  ON user_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "user_profiles_self_update"
  ON user_profiles
  FOR UPDATE
  USING (auth.uid() = user_id);
