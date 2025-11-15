class AppConstants {
  // App Information
  static const String appName = 'Қуръон бо Тафсири Осонбаён';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String supabaseUrl = 'https://bwymwoomylotjlnvawlr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3eW13b29teWxvdGpsbnZhd2xyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4MDM2ODUsImV4cCI6MjA2MjM3OTY4NX0.0LP8whhfrlt15EUgtrzRox25oiApzg9ZGy8kgiV1NP8';
  static const String alquranCloudUrl = 'https://api.alquran.cloud/v1';
  
  // Database Configuration
  static const String quranDatabaseName = 'quran.db';
  static const int quranDatabaseVersion = 1;
  
  // Hive Box Names
  static const String settingsBox = 'settings';
  static const String bookmarksBox = 'bookmarks';
  static const String userPreferencesBox = 'user_preferences';
  static const String searchHistoryBox = 'search_history';
  static const String tasbeehBox = 'tasbeeh';
  static const String wordLearningBox = 'word_learning';
  static const String downloadedTranslationsBox = 'downloaded_translations';
  
  // Audio Configuration
  static const String audioBaseUrl = 'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy';
  static const String audioBackupUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/surah';
  
  // Pagination
  static const int versesPerPage = 10;
  static const int searchResultsPerPage = 20;
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Search Configuration
  static const int minSearchLength = 2;
  static const int maxSearchHistory = 50;
  
  // Tasbeeh Configuration
  static const List<int> defaultTasbeehTargets = [33, 99, 100, 500];
  static const int defaultTasbeehTarget = 33;
  
  // Word Learning Configuration
  static const int beginnerWordCount = 10;
  static const int intermediateWordCount = 20;
  static const int advancedWordCount = 30;
  
  // Supported Languages
  static const List<String> supportedLanguages = [
    'tajik',
    'tj_2',
    'tj_3',
    'farsi',
    'russian',
  ];
  
  // Default Language
  static const String defaultLanguage = 'tj_2'; // Абуаломуддин
  
  // Translation Names
  static String getTranslationName(String languageCode) {
    switch (languageCode) {
      case 'tajik':
        return 'Абдул Муҳаммад Оятӣ';
      case 'tj_2':
        return 'Абуаломуддин (бо тафсир)';
      case 'tj_3':
        return 'Pioneers of Translation Center';
      case 'farsi':
        return 'Форсӣ';
      case 'russian':
        return 'Эльмир Кулиев';
      default:
        return 'Тоҷикӣ';
    }
  }
  
  // Font Sizes
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultFontSize = 16.0;
  
  // Line Spacing
  static const double minLineSpacing = 1.0;
  static const double maxLineSpacing = 2.5;
  static const double defaultLineSpacing = 1.5;
  
  // Font Families
  static const String? arabicFontFamily = null; // Use system default
  static const String? tajikFontFamily = null; // Use system default
  static const String englishFontFamily = 'Roboto';
}
