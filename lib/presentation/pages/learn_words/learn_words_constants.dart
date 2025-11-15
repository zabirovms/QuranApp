import 'package:flutter/material.dart';

/// Constants for Learn Words page
class LearnWordsConstants {
  // Default values
  static const int defaultWordCount = 10;
  static const int defaultVerseStart = 1;
  static const int defaultVerseEnd = 5;
  static const int initialVersesToLoad = 15;
  static const int versesLoadIncrement = 15;
  
  // Limits
  static const int minWordCount = 1;
  static const int maxWordCount = 100;
  static const int minQuizOptions = 3;
  static const int totalQuizOptions = 4;
  
  // Animation timings
  static const Duration quizAnswerDelay = Duration(milliseconds: 1200);
  static const Duration lastQuestionDelay = Duration(milliseconds: 1500);
  
  // Score thresholds
  static const double excellentScore = 80.0;
  static const double goodScore = 60.0;
  
  // UI constants
  static const double quizProgressStrokeWidth = 12;
  static const double emojiSize = 72;
  static const double iconSize = 18;
  static const double smallIconSize = 16;
  static const double quizIconSize = 20;
  static const double arabicFontSize = 48;
  static const double largeArabicFontSize = 17;
  static const double verseHeaderFontSize = 13;
  
  // Text strings
  static const String appBarTitle = 'Омӯхтани калимаҳо';
  static const String errorTitle = 'Хатогӣ';
  static const String surahsListTitle = 'Рӯйхати сураҳо';
  static const String surahPrefix = 'Сураи';
  static const String versesLabel = 'оят';
  static const String wordsLabel = 'калима';
  static const String approximateWordCount = 'Қариб';
  static const String wordCountLabel = 'миқдори калимаҳо';
  static const String verseFromLabel = 'аз ояти';
  static const String verseToLabel = 'то ояти';
  static const String dashSeparator = '–';
  static const String quizButtonLabel = 'Санҷиш';
  static const String quizFromVerseLabel = 'Санҷиш аз оят';
  static const String verseHeaderPrefix = 'Ояти';
  static const String quizTooltip = 'Тест аз ин оят';
  static const String loadMoreButton = 'Боргирии бештар';
  static const String fromLabel = 'аз';
  static const String emptyWordsMessage = 'Ҳеҷ калимае нест';
  static const String correctAnswer = '✓ Дуруст';
  static const String wrongAnswer = '✗ Нодуруст';
  static const String showResultsLabel = 'Намоиши натиҷаҳо';
  static const String backButton = 'Қаблӣ';
  static const String nextButton = 'Баъдӣ';
  static const String returnToSurahButton = 'Бозгашт ба сура';
  static const String resultsTitle = 'Натиҷаҳои санҷиш';
  static const String reviewAnswersTitle = 'Баррасии ҷавобҳо';
  static const String backToQuizButton = 'Бозгашт ба санҷиш';
  static const String retryButtonLabel = 'Аз нав такрор';
  
  // Result messages
  static const String excellentMessage = 'Офарин! Пешравиҳо муборак!';
  static const String goodMessage = 'Бад не. Кӯшиш мекунем аз ин беҳтар шавад!';
  static const String needsPracticeMessage = 'Ноумед намешавем! Боз дубора кӯшиш мекунем!';
  
  // Error messages
  static const String wordCountError = 'Миқдори калимаҳо бояд аз';
  static const String toError = 'то';
  static const String beError = 'бошад';
  static const String wordCountExceedsError = 'Миқдори калимаҳо аз';
  static const String notMoreError = 'зиёд нест';
  static const String invalidRangeError = 'Диапазони нодуруст. Оят ё ба оят';
  static const String verseMustError = '1 бояд бошад ва то метавонад аз аз набошад';
  static const String rangeExceedsError = 'Диапазон аз';
  static const String verseError = 'оятҳои сура мегузарад';
  static const String noVerseInRangeError = 'Ҳеҷ ояте дар ин диапазон нест';
  static const String noWordsError = 'Ҳеҷ калимае дар ин оятҳо нест';
  static const String loadSurahsError = 'Хатогӣ дар боргирии сураҳо';
  static const String loadVersesError = 'Хатогӣ дар боргирии оятҳо';
  
  // Network/Offline errors
  static const String offlineTitle = 'Интернет пайваст нест';
  static const String offlineWordByWordMessage = 'Маълумоти калима ба калима дастрас нест. Лутфан интернетро тафтиш кунед ва дубора кӯшиш кунед.';
  static const String offlineVersesMessage = 'Оятҳо дастрас нестанд. Лутфан интернетро тафтиш кунед ва дубора кӯшиш кунед.';
  static const String networkErrorCheckConnection = 'Лутфан интернетро тафтиш кунед ва дубора кӯшиш кунед';
  
  // Icons
  static const IconData arrowBackIcon = Icons.arrow_back;
  static const IconData quizIcon = Icons.quiz;
  static const IconData listAltIcon = Icons.list_alt;
  static const IconData unfoldMoreIcon = Icons.unfold_more;
  static const IconData checkCircleIcon = Icons.check_circle;
  static const IconData cancelIcon = Icons.cancel;
  static const IconData replayIcon = Icons.replay;
  static const IconData arrowForwardIcon = Icons.arrow_forward;
  static const IconData arrowForwardIosIcon = Icons.arrow_forward_ios;
  
  // Colors for results
  static const Color excellentColor = Colors.green;
  static const Color goodColor = Colors.blue;
  static const Color needsPracticeColor = Colors.orange;
  
  // Emojis
  static const String excellentEmoji = '🎉';
  static const String goodEmoji = '👍';
  static const String needsPracticeEmoji = '💪';
}

/// Extensions for building localized strings
extension LearnWordsLocalizations on LearnWordsConstants {
  /// Build surah subtitle text
  static String buildSurahSubtitle(int versesCount) {
    return '$versesCount ${LearnWordsConstants.versesLabel} • ${LearnWordsConstants.approximateWordCount} ${(versesCount * 4.5).toStringAsFixed(0)} ${LearnWordsConstants.wordsLabel}';
  }
  
  /// Build verse number text
  static String buildVerseNumber(int verseNumber) {
    return '${LearnWordsConstants.verseHeaderPrefix} $verseNumber';
  }
  
  /// Build surah title
  static String buildSurahTitle(String surahName) {
    return '${LearnWordsConstants.surahPrefix} $surahName';
  }
  
  /// Build word count error message
  static String buildWordCountError(int min, int max) {
    return '${LearnWordsConstants.wordCountError} $min ${LearnWordsConstants.toError} $max ${LearnWordsConstants.beError}';
  }
  
  /// Build word count exceeds error
  static String buildWordCountExceedsError(int available) {
    return '${LearnWordsConstants.wordCountExceedsError} $available ${LearnWordsConstants.notMoreError}';
  }
  
  /// Build range exceeds error
  static String buildRangeExceedsError(int surahVerses) {
    return '${LearnWordsConstants.rangeExceedsError} $surahVerses ${LearnWordsConstants.verseError}';
  }
  
  /// Build load more button text
  static String buildLoadMoreText(int loaded, int total) {
    return '${LearnWordsConstants.loadMoreButton} ($loaded ${LearnWordsConstants.fromLabel} $total)';
  }
  
  /// Build quiz progress text
  static String buildQuizProgress(int current, int total) {
    return 'Калимаи $current ${LearnWordsConstants.fromLabel} $total';
  }
}
