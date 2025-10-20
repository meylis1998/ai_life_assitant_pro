/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AI Life Assistant Pro';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 24);
  static const String cacheBoxName = 'app_cache';

  // AI Providers
  static const String geminiProvider = 'gemini';
  static const String claudeProvider = 'claude';
  static const String openAIProvider = 'openai';

  // Rate Limits (requests per minute)
  static const int geminiRateLimit = 60;
  static const int claudeRateLimit = 50;
  static const int openAIRateLimit = 60;

  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(minutes: 5);

  // File Size Limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  // Message Limits
  static const int maxMessageLength = 4000;
  static const int maxConversationHistory = 50;

  // Voice Settings
  static const double defaultSpeechRate = 1.0;
  static const double defaultSpeechPitch = 1.0;
  static const double defaultSpeechVolume = 1.0;

  // Storage Keys
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String onboardingKey = 'onboarding_completed';
  static const String userPreferencesKey = 'user_preferences';
  static const String aiProviderKey = 'selected_ai_provider';

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de', 'zh'];

  // Supported File Extensions
  static const List<String> supportedDocuments = [
    'pdf',
    'txt',
    'md',
    'doc',
    'docx',
  ];
  static const List<String> supportedImages = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
}
