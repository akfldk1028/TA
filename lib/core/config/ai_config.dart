abstract final class AiConfig {
  static const String defaultModel = 'qwen3.5-flash';
  static const int maxHistoryMessages = 30;
  static const double reversalProbability = 0.3;

  // Supabase Edge Function config
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether Edge Function is configured (both URL and key present).
  static bool get useEdgeFunction =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
