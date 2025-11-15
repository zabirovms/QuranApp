import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  late SharedPreferences _prefs;

  SettingsService._internal();

  factory SettingsService() => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme settings
  Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString('theme_mode', themeMode);
  }

  String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'system';
  }

  // Language settings
  Future<void> setTranslationLanguage(String language) async {
    await _prefs.setString('translation_language', language);
  }

  String getTranslationLanguage() {
    return _prefs.getString('translation_language') ?? AppConstants.defaultLanguage;
  }

  // Font size settings
  Future<void> setFontSize(double fontSize) async {
    await _prefs.setDouble('font_size', fontSize);
  }

  double getFontSize() {
    return _prefs.getDouble('font_size') ?? AppConstants.defaultFontSize;
  }

  // Line spacing settings
  Future<void> setLineSpacing(double lineSpacing) async {
    await _prefs.setDouble('line_spacing', lineSpacing);
  }

  double getLineSpacing() {
    return _prefs.getDouble('line_spacing') ?? AppConstants.defaultLineSpacing;
  }

  // Audio settings
  Future<void> setAudioEnabled(bool enabled) async {
    await _prefs.setBool('audio_enabled', enabled);
  }

  bool getAudioEnabled() {
    return _prefs.getBool('audio_enabled') ?? true;
  }

  Future<void> setAudioVolume(double volume) async {
    await _prefs.setDouble('audio_volume', volume);
  }

  double getAudioVolume() {
    return _prefs.getDouble('audio_volume') ?? 1.0;
  }

  Future<void> setAudioSpeed(double speed) async {
    await _prefs.setDouble('audio_speed', speed);
  }

  double getAudioSpeed() {
    return _prefs.getDouble('audio_speed') ?? 1.0;
  }

  Future<void> setAudioEdition(String edition) async {
    await _prefs.setString('audio_edition', edition);
  }

  String getAudioEdition() {
    return _prefs.getString('audio_edition') ?? 'ar.alafasy';
  }

  // Display settings
  Future<void> setShowTransliteration(bool show) async {
    await _prefs.setBool('show_transliteration', show);
  }

  bool getShowTransliteration() {
    return _prefs.getBool('show_transliteration') ?? true;
  }

  Future<void> setShowTafsir(bool show) async {
    await _prefs.setBool('show_tafsir', show);
  }

  bool getShowTafsir() {
    return _prefs.getBool('show_tafsir') ?? false;
  }

  Future<void> setWordByWordMode(bool enabled) async {
    await _prefs.setBool('word_by_word_mode', enabled);
  }

  bool getWordByWordMode() {
    return _prefs.getBool('word_by_word_mode') ?? false;
  }

  Future<void> setShowOnlyArabic(bool show) async {
    await _prefs.setBool('show_only_arabic', show);
  }

  bool getShowOnlyArabic() {
    return _prefs.getBool('show_only_arabic') ?? false;
  }

  // Content view mode
  Future<void> setContentViewMode(String mode) async {
    await _prefs.setString('content_view_mode', mode);
  }

  String getContentViewMode() {
    return _prefs.getString('content_view_mode') ?? 'compact';
  }

  // Tasbeeh settings
  Future<void> setTasbeehTarget(int target) async {
    await _prefs.setInt('tasbeeh_target', target);
  }

  int getTasbeehTarget() {
    return _prefs.getInt('tasbeeh_target') ?? AppConstants.defaultTasbeehTarget;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool('vibration_enabled', enabled);
  }

  bool getVibrationEnabled() {
    return _prefs.getBool('vibration_enabled') ?? true;
  }

  // Word learning settings
  Future<void> setWordLearningDifficulty(String difficulty) async {
    await _prefs.setString('word_learning_difficulty', difficulty);
  }

  String getWordLearningDifficulty() {
    return _prefs.getString('word_learning_difficulty') ?? 'beginner';
  }

  Future<void> setWordLearningMode(String mode) async {
    await _prefs.setString('word_learning_mode', mode);
  }

  String getWordLearningMode() {
    return _prefs.getString('word_learning_mode') ?? 'flashcards';
  }

  // Search settings
  Future<void> setSearchLanguage(String language) async {
    await _prefs.setString('search_language', language);
  }

  String getSearchLanguage() {
    return _prefs.getString('search_language') ?? 'both';
  }

  // Offline settings
  Future<void> setOfflineMode(bool enabled) async {
    await _prefs.setBool('offline_mode', enabled);
  }

  bool getOfflineMode() {
    return _prefs.getBool('offline_mode') ?? false;
  }

  Future<void> setAutoDownloadAudio(bool enabled) async {
    await _prefs.setBool('auto_download_audio', enabled);
  }

  bool getAutoDownloadAudio() {
    return _prefs.getBool('auto_download_audio') ?? false;
  }

  // User preferences
  Future<void> setUserId(String userId) async {
    await _prefs.setString('user_id', userId);
  }

  String? getUserId() {
    return _prefs.getString('user_id');
  }

  Future<void> setLastReadSurah(int surahNumber) async {
    await _prefs.setInt('last_read_surah', surahNumber);
  }

  int? getLastReadSurah() {
    return _prefs.getInt('last_read_surah');
  }

  Future<void> setLastReadVerse(int surahNumber, int verseNumber) async {
    await _prefs.setInt('last_read_surah', surahNumber);
    await _prefs.setInt('last_read_verse', verseNumber);
  }

  Map<String, int>? getLastReadPosition() {
    final surah = _prefs.getInt('last_read_surah');
    final verse = _prefs.getInt('last_read_verse');
    if (surah != null && verse != null) {
      return {'surah': surah, 'verse': verse};
    }
    return null;
  }

  // App version and first launch
  Future<void> setAppVersion(String version) async {
    await _prefs.setString('app_version', version);
  }

  String? getAppVersion() {
    return _prefs.getString('app_version');
  }

  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool('first_launch', isFirstLaunch);
  }

  bool isFirstLaunch() {
    return _prefs.getBool('first_launch') ?? true;
  }

  // Clear all settings
  Future<void> clearAllSettings() async {
    await _prefs.clear();
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'theme_mode': getThemeMode(),
      'translation_language': getTranslationLanguage(),
      'font_size': getFontSize(),
      'line_spacing': getLineSpacing(),
      'audio_enabled': getAudioEnabled(),
      'audio_volume': getAudioVolume(),
      'audio_speed': getAudioSpeed(),
      'show_transliteration': getShowTransliteration(),
      'show_tafsir': getShowTafsir(),
      'word_by_word_mode': getWordByWordMode(),
      'show_only_arabic': getShowOnlyArabic(),
      'content_view_mode': getContentViewMode(),
      'tasbeeh_target': getTasbeehTarget(),
      'vibration_enabled': getVibrationEnabled(),
      'word_learning_difficulty': getWordLearningDifficulty(),
      'word_learning_mode': getWordLearningMode(),
      'search_language': getSearchLanguage(),
      'offline_mode': getOfflineMode(),
      'auto_download_audio': getAutoDownloadAudio(),
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;
      
      switch (key) {
        case 'theme_mode':
          await setThemeMode(value as String);
          break;
        case 'translation_language':
          await setTranslationLanguage(value as String);
          break;
        case 'font_size':
          await setFontSize(value as double);
          break;
        case 'line_spacing':
          await setLineSpacing(value as double);
          break;
        case 'audio_enabled':
          await setAudioEnabled(value as bool);
          break;
        case 'audio_volume':
          await setAudioVolume(value as double);
          break;
        case 'audio_speed':
          await setAudioSpeed(value as double);
          break;
        case 'show_transliteration':
          await setShowTransliteration(value as bool);
          break;
        case 'show_tafsir':
          await setShowTafsir(value as bool);
          break;
        case 'word_by_word_mode':
          await setWordByWordMode(value as bool);
          break;
        case 'show_only_arabic':
          await setShowOnlyArabic(value as bool);
          break;
        case 'content_view_mode':
          await setContentViewMode(value as String);
          break;
        case 'tasbeeh_target':
          await setTasbeehTarget(value as int);
          break;
        case 'vibration_enabled':
          await setVibrationEnabled(value as bool);
          break;
        case 'word_learning_difficulty':
          await setWordLearningDifficulty(value as String);
          break;
        case 'word_learning_mode':
          await setWordLearningMode(value as String);
          break;
        case 'search_language':
          await setSearchLanguage(value as String);
          break;
        case 'offline_mode':
          await setOfflineMode(value as bool);
          break;
        case 'auto_download_audio':
          await setAutoDownloadAudio(value as bool);
          break;
      }
    }
  }
}
