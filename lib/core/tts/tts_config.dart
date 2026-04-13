/// TTS 언어별 설정 매핑 (17개 locale)
class TtsLocaleConfig {
  const TtsLocaleConfig({
    required this.ttsLanguage,
    this.speechRate = 0.45,
    this.pitch = 1.0,
  });

  final String ttsLanguage;
  final double speechRate;
  final double pitch;

  static const Map<String, TtsLocaleConfig> localeMap = {
    'ko': TtsLocaleConfig(ttsLanguage: 'ko-KR', speechRate: 0.3, pitch: 0.95),
    'en': TtsLocaleConfig(ttsLanguage: 'en-US', speechRate: 0.35, pitch: 0.95),
    'ja': TtsLocaleConfig(ttsLanguage: 'ja-JP', speechRate: 0.3, pitch: 0.95),
    'zh': TtsLocaleConfig(ttsLanguage: 'zh-CN', speechRate: 0.35, pitch: 0.95),
    'vi': TtsLocaleConfig(ttsLanguage: 'vi-VN', speechRate: 0.35, pitch: 0.95),
    'th': TtsLocaleConfig(ttsLanguage: 'th-TH', speechRate: 0.35, pitch: 0.95),
    'id': TtsLocaleConfig(ttsLanguage: 'id-ID', speechRate: 0.35, pitch: 0.95),
    'ms': TtsLocaleConfig(ttsLanguage: 'ms-MY', speechRate: 0.35, pitch: 0.95),
    'my': TtsLocaleConfig(ttsLanguage: 'my-MM', speechRate: 0.35, pitch: 0.95),
    'fr': TtsLocaleConfig(ttsLanguage: 'fr-FR', speechRate: 0.35, pitch: 0.95),
    'de': TtsLocaleConfig(ttsLanguage: 'de-DE', speechRate: 0.35, pitch: 0.95),
    'es': TtsLocaleConfig(ttsLanguage: 'es-ES', speechRate: 0.35, pitch: 0.95),
    'pt': TtsLocaleConfig(ttsLanguage: 'pt-BR', speechRate: 0.35, pitch: 0.95),
    'it': TtsLocaleConfig(ttsLanguage: 'it-IT', speechRate: 0.35, pitch: 0.95),
    'hi': TtsLocaleConfig(ttsLanguage: 'hi-IN', speechRate: 0.3, pitch: 0.95),
    'ar': TtsLocaleConfig(ttsLanguage: 'ar-SA', speechRate: 0.3, pitch: 0.95),
    'ru': TtsLocaleConfig(ttsLanguage: 'ru-RU', speechRate: 0.35, pitch: 0.95),
  };

  static const TtsLocaleConfig fallback =
      TtsLocaleConfig(ttsLanguage: 'en-US', speechRate: 0.35, pitch: 0.95);

  static TtsLocaleConfig forLocale(String languageCode) =>
      localeMap[languageCode] ?? fallback;
}