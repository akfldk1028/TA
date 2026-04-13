const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

String getApiKey() {
  if (_geminiApiKey.isNotEmpty) return _geminiApiKey;
  throw Exception(
    'GEMINI_API_KEY is required. '
    'Run with: flutter run --dart-define=GEMINI_API_KEY=\$GEMINI_API_KEY',
  );
}
