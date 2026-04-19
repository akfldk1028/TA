-- tarot_daily_usage UPSERT. 하루 1 row 유지 + 누적 증가.

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
