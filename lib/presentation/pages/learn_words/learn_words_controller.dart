import 'package:flutter/foundation.dart';
import '../../../data/datasources/remote/api_service.dart';
import '../../../data/datasources/remote/alquran_cloud_api.dart';
import '../../../data/datasources/local/surah_local_datasource.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/models/word_by_word_model.dart';
import '../../../data/repositories/integrated_quran_repository.dart';
import '../../../core/utils/compressed_json_loader.dart';
import 'learn_words_constants.dart';

enum LearnWordsScreen { surahs, learning, quiz }
enum QuizMode { words, verses }

class QuizAnswer {
  final String arabic;
  final String translation;
  final String? selectedAnswer;
  final bool isCorrect;

  QuizAnswer({
    required this.arabic,
    required this.translation,
    required this.selectedAnswer,
    required this.isCorrect,
  });
}

class LearnWordsState {
  final bool loading;
  final String? error;
  final LearnWordsScreen currentScreen;
  final List<SurahModel> surahs;
  final SurahModel? selectedSurah;
  final List<VerseModel> verses;
  final Map<String, List<WordByWordModel>> wordByWord;
  final int versesLoaded;
  final List<QuizWord> quizWords;
  final int currentQuizIndex;
  final int? lastCorrectAnswer;
  final int selectedVerseStart;
  final int selectedVerseEnd;
  final int customWordCount;
  final Map<int, bool> quizAnswers; // Track user answers: index -> isCorrect
  final bool showQuizResults;
  final Map<int, List<String>> quizOptions; // Store options for each question
  final QuizMode selectedQuizMode;

  LearnWordsState({
    this.loading = false,
    this.error,
    this.currentScreen = LearnWordsScreen.surahs,
    this.surahs = const [],
    this.selectedSurah,
    this.verses = const [],
    this.wordByWord = const {},
    this.versesLoaded = 0,
    this.quizWords = const [],
    this.currentQuizIndex = 0,
    this.lastCorrectAnswer,
    this.selectedVerseStart = LearnWordsConstants.defaultVerseStart,
    this.selectedVerseEnd = LearnWordsConstants.defaultVerseEnd,
    this.customWordCount = LearnWordsConstants.defaultWordCount,
    this.quizAnswers = const {},
    this.showQuizResults = false,
    this.quizOptions = const {},
    this.selectedQuizMode = QuizMode.words,
  });

  LearnWordsState copyWith({
    bool? loading,
    String? error,
    LearnWordsScreen? currentScreen,
    List<SurahModel>? surahs,
    SurahModel? selectedSurah,
    List<VerseModel>? verses,
    Map<String, List<WordByWordModel>>? wordByWord,
    int? versesLoaded,
    List<QuizWord>? quizWords,
    int? currentQuizIndex,
    int? lastCorrectAnswer,
    int? selectedVerseStart,
    int? selectedVerseEnd,
    int? customWordCount,
    Map<int, bool>? quizAnswers,
    bool? showQuizResults,
    Map<int, List<String>>? quizOptions,
    QuizMode? selectedQuizMode,
  }) {
    return LearnWordsState(
      loading: loading ?? this.loading,
      error: error,
      currentScreen: currentScreen ?? this.currentScreen,
      surahs: surahs ?? this.surahs,
      selectedSurah: selectedSurah ?? this.selectedSurah,
      verses: verses ?? this.verses,
      wordByWord: wordByWord ?? this.wordByWord,
      versesLoaded: versesLoaded ?? this.versesLoaded,
      quizWords: quizWords ?? this.quizWords,
      currentQuizIndex: currentQuizIndex ?? this.currentQuizIndex,
      lastCorrectAnswer: lastCorrectAnswer,
      selectedVerseStart: selectedVerseStart ?? this.selectedVerseStart,
      selectedVerseEnd: selectedVerseEnd ?? this.selectedVerseEnd,
      customWordCount: customWordCount ?? this.customWordCount,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      showQuizResults: showQuizResults ?? this.showQuizResults,
      quizOptions: quizOptions ?? this.quizOptions,
      selectedQuizMode: selectedQuizMode ?? this.selectedQuizMode,
    );
  }
}

class QuizWord {
  final String arabic;
  final String translation;
  final String uniqueKey;
  final int wordNumber;

  QuizWord({
    required this.arabic,
    required this.translation,
    required this.uniqueKey,
    required this.wordNumber,
  });
}

class LearnWordsController extends ChangeNotifier {
  LearnWordsController({
    required ApiService apiService,
    required AlQuranCloudApi aqcApi,
  })  : _apiService = apiService,
        _aqcApi = aqcApi {
    _repo = IntegratedQuranRepository(apiService: _apiService, aqc: _aqcApi);
    _localDataSource = SurahLocalDataSource();
    loadSurahs();
  }

  final ApiService _apiService;
  final AlQuranCloudApi _aqcApi;
  late final IntegratedQuranRepository _repo;
  late final SurahLocalDataSource _localDataSource;
  Map<int, int> _wordCounts = {}; // Map of surah number -> word count

  LearnWordsState _state = LearnWordsState();

  LearnWordsState get state => _state;

  /// Load word counts from local compressed JSON file
  Future<Map<int, int>> _loadWordCounts() async {
    try {
      final List<dynamic> wordCountsJson = await CompressedJsonLoader.loadCompressedJsonAsList(
        'assets/data/word_counts.json.gz',
      );
      
      final Map<int, int> wordCounts = {};
      for (final item in wordCountsJson) {
        final surahNumber = int.tryParse(item['surah_number'] as String? ?? '');
        final wordCount = item['word_count'] as int?;
        if (surahNumber != null && wordCount != null) {
          wordCounts[surahNumber] = wordCount;
        }
      }
      return wordCounts;
    } catch (e) {
      debugPrint('Failed to load word counts: $e');
      return {};
    }
  }

  Future<void> loadSurahs() async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();

    try {
      // Load surahs from local data source
      final surahs = await _localDataSource.getAllSurahs();
      
      // Load word counts from local JSON file
      _wordCounts = await _loadWordCounts();

      _state = _state.copyWith(
        loading: false,
        surahs: surahs,
      );
    } catch (e) {
      _state = _state.copyWith(
        loading: false,
        error: '${LearnWordsConstants.loadSurahsError}: $e',
      );
    }
    notifyListeners();
  }

  /// Get word count for a specific surah
  int? getWordCountForSurah(int surahNumber) {
    return _wordCounts[surahNumber];
  }

  Future<void> selectSurah(SurahModel surah) async {
    _state = _state.copyWith(
      selectedSurah: surah,
      versesLoaded: 0,
      verses: [],
      wordByWord: {},
      currentScreen: LearnWordsScreen.learning,
      loading: true,
      error: null,
    );
    notifyListeners();

    List<VerseModel> verses = [];
    Map<String, List<WordByWordModel>> wordByWordMap = {};
    String? errorMessage;

    try {
      // Load verses first
      verses = await _repo.getSupabaseVerses(surah.number);
    } catch (e) {
      // Check if it's a network error
      final isNetworkError = _isNetworkError(e);
      errorMessage = isNetworkError 
          ? LearnWordsConstants.offlineVersesMessage
          : '${LearnWordsConstants.loadVersesError}: $e';
      
      _state = _state.copyWith(
        loading: false,
        error: errorMessage,
      );
      notifyListeners();
      return;
    }

    // Try to load word-by-word data (this can fail independently)
    try {
      wordByWordMap = await _repo.getWordByWordForSurah(surah.number);
      // If we get an empty map but no exception, it's not a network error
      // The repository would throw NETWORK_ERROR if it was a network issue
    } catch (e) {
      // Check if it's a network error
      final isNetworkError = _isNetworkError(e);
      if (isNetworkError) {
        // Network error - show user-friendly message
        errorMessage = LearnWordsConstants.offlineWordByWordMessage;
      } else {
        // Non-network error - continue without word-by-word data silently
        debugPrint('Word-by-word data unavailable (non-network error): $e');
      }
      // wordByWordMap remains empty, which is fine
    }

    _state = _state.copyWith(
      verses: verses,
      wordByWord: wordByWordMap,
      versesLoaded: LearnWordsConstants.initialVersesToLoad,
      loading: false,
      error: errorMessage,
      selectedVerseEnd: surah.versesCount > LearnWordsConstants.initialVersesToLoad 
          ? LearnWordsConstants.initialVersesToLoad 
          : surah.versesCount,
    );
    notifyListeners();
  }

  /// Check if an error is a network/offline error
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Check for common network error indicators
    if (errorString.contains('network_error') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('internet connection') ||
        errorString.contains('socketexception') ||
        errorString.contains('connectionerror') ||
        errorString.contains('connectiontimeout') ||
        errorString.contains('receivetimeout') ||
        errorString.contains('network is unreachable')) {
      return true;
    }
    
    // Check for DioException network types
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      if (message.contains('connection timeout') ||
          message.contains('connection error') ||
          message.contains('receive timeout')) {
        return true;
      }
    }
    
    return false;
  }

  void goBackToSurahs() {
    _state = _state.copyWith(
      currentScreen: LearnWordsScreen.surahs,
      selectedSurah: null,
    );
    notifyListeners();
  }

  void loadMoreVerses() {
    if (_state.selectedSurah == null) return;

    final totalVerses = _state.verses.length;
    final start = _state.versesLoaded;
    final end = (start + LearnWordsConstants.versesLoadIncrement < totalVerses) 
        ? start + LearnWordsConstants.versesLoadIncrement 
        : totalVerses;

    _state = _state.copyWith(versesLoaded: end);
    notifyListeners();
  }

  void startCustomWordQuiz() {
    if (_state.selectedSurah == null || _state.wordByWord.isEmpty) return;

    // Validate custom word count
    final count = _state.customWordCount;
    if (count < LearnWordsConstants.minWordCount || count > LearnWordsConstants.maxWordCount) {
      _state = _state.copyWith(
        error: LearnWordsLocalizations.buildWordCountError(
          LearnWordsConstants.minWordCount,
          LearnWordsConstants.maxWordCount,
        ),
      );
      notifyListeners();
      return;
    }

    // Collect all words from word-by-word data
    final allWords = <QuizWord>[];
    for (final entry in _state.wordByWord.entries) {
      for (final word in entry.value) {
        if (word.farsi != null && word.farsi!.isNotEmpty) {
          allWords.add(QuizWord(
            arabic: word.arabic,
            translation: word.farsi ?? '',
            uniqueKey: word.uniqueKey,
            wordNumber: word.wordNumber,
          ));
        }
      }
    }

    if (allWords.length < count) {
      _state = _state.copyWith(
        error: LearnWordsLocalizations.buildWordCountExceedsError(allWords.length),
      );
      notifyListeners();
      return;
    }

    // Shuffle and select words
    allWords.shuffle();
    final wordsToQuiz = allWords.take(count).toList();

    _startQuiz(wordsToQuiz);
  }

  void startVerseRangeQuiz() {
    if (_state.selectedSurah == null) return;

    final start = _state.selectedVerseStart;
    final end = _state.selectedVerseEnd;

    // Validate verse range
    if (start < 1 || end < start) {
      _state = _state.copyWith(
        error: 'Диапазони нодуруст. Оят ё ба оят 1 бояд бошад ва то метавонад аз аз набошад',
      );
      notifyListeners();
      return;
    }

    if (end > _state.selectedSurah!.versesCount) {
      _state = _state.copyWith(
        error: LearnWordsLocalizations.buildRangeExceedsError(_state.selectedSurah!.versesCount),
      );
      notifyListeners();
      return;
    }

    // Get verses in range
    final versesInRange = _state.verses.where((v) =>
        v.verseNumber >= start && v.verseNumber <= end).toList();

    if (versesInRange.isEmpty) {
      _state = _state.copyWith(
        error: 'Ҳеҷ ояте дар ин диапазон нест',
      );
      notifyListeners();
      return;
    }

    // Collect words from these verses
    final allWords = <QuizWord>[];
    for (final verse in versesInRange) {
      final words = _state.wordByWord[verse.uniqueKey] ?? [];
      for (final word in words) {
        if (word.farsi != null && word.farsi!.isNotEmpty) {
          allWords.add(QuizWord(
            arabic: word.arabic,
            translation: word.farsi ?? '',
            uniqueKey: word.uniqueKey,
            wordNumber: word.wordNumber,
          ));
        }
      }
    }

    if (allWords.isEmpty) {
      _state = _state.copyWith(
        error: 'Ҳеҷ калимае дар ин оятҳо нест',
      );
      notifyListeners();
      return;
    }

    // Shuffle and select words
    allWords.shuffle();
    _startQuiz(allWords);
  }

  void startSingleVerseQuiz(VerseModel verse) {
    if (_state.selectedSurah == null) return;

    // Get words for this verse
    final words = _state.wordByWord[verse.uniqueKey] ?? [];
    final quizWords = words.map((w) => QuizWord(
      arabic: w.arabic,
      translation: w.farsi ?? '',
      uniqueKey: w.uniqueKey,
      wordNumber: w.wordNumber,
    )).toList();

    // Shuffle words for random order
    quizWords.shuffle();

    _startQuiz(quizWords);
  }

  void _startQuiz(List<QuizWord> words) {
    if (words.isEmpty) return;

    // Generate and store options for all questions
    final Map<int, List<String>> optionsMap = {};
    for (int i = 0; i < words.length; i++) {
      optionsMap[i] = _generateOptionsForQuestion(words[i], words);
    }

    _state = _state.copyWith(
      quizWords: words,
      currentQuizIndex: 0,
      lastCorrectAnswer: null,
      currentScreen: LearnWordsScreen.quiz,
      quizAnswers: {},
      showQuizResults: false,
      quizOptions: optionsMap,
    );
    notifyListeners();
  }

  List<String> _generateOptionsForQuestion(QuizWord currentWord, List<QuizWord> allWords) {
    final correctTranslation = currentWord.translation;

    // Get all unique translations
    final allTranslations = <String>{correctTranslation};
    for (final word in allWords) {
      if (word.translation.isNotEmpty) {
        allTranslations.add(word.translation);
      }
    }

    // Remove correct answer and get incorrect answers
    final otherTranslations = allTranslations.where((t) => t != correctTranslation).toList();
    otherTranslations.shuffle();
    
    // Try to get 3 incorrect answers (for 4 total options), but take what's available
    final incorrectAnswers = otherTranslations.take(LearnWordsConstants.minQuizOptions).toList();
    
    // If we don't have enough options, repeat some to make at least 3 incorrect options
    while (incorrectAnswers.length < LearnWordsConstants.minQuizOptions && allWords.length > 1) {
      final shuffled = allWords.where((w) => w.translation != correctTranslation).toList();
      shuffled.shuffle();
      if (shuffled.isNotEmpty && !incorrectAnswers.contains(shuffled.first.translation)) {
        incorrectAnswers.add(shuffled.first.translation);
      } else if (incorrectAnswers.isEmpty) {
        // Last resort - at least duplicate the correct answer
        incorrectAnswers.add(correctTranslation);
      } else {
        break;
      }
    }

    // Combine and shuffle
    final options = [correctTranslation, ...incorrectAnswers];
    options.shuffle();

    return options;
  }

  void nextQuiz() {
    if (_state.currentQuizIndex < _state.quizWords.length - 1) {
      _state = _state.copyWith(
        currentQuizIndex: _state.currentQuizIndex + 1,
        lastCorrectAnswer: null,
      );
      notifyListeners();
    }
  }

  void previousQuiz() {
    if (_state.currentQuizIndex > 0) {
      _state = _state.copyWith(
        currentQuizIndex: _state.currentQuizIndex - 1,
        lastCorrectAnswer: null,
      );
      notifyListeners();
    }
  }

  void endQuiz() {
    _state = _state.copyWith(
      currentScreen: LearnWordsScreen.learning,
      quizWords: [],
      currentQuizIndex: 0,
      lastCorrectAnswer: null,
      quizAnswers: {},
      showQuizResults: false,
      quizOptions: {},
    );
    notifyListeners();
  }

  void setCustomWordCount(int count) {
    _state = _state.copyWith(customWordCount: count);
    notifyListeners();
  }

  void setVerseRange(int start, int end) {
    _state = _state.copyWith(
      selectedVerseStart: start,
      selectedVerseEnd: end,
    );
    notifyListeners();
  }

  void setQuizMode(QuizMode mode) {
    _state = _state.copyWith(selectedQuizMode: mode);
    notifyListeners();
  }

  void setLastCorrectAnswer(int index) {
    final currentWord = _state.quizWords[_state.currentQuizIndex];
    final options = _state.quizOptions[_state.currentQuizIndex] ?? [];
    final selectedAnswer = options[index];
    final isCorrect = selectedAnswer == currentWord.translation;

    // Track the answer
    final updatedAnswers = Map<int, bool>.from(_state.quizAnswers);
    updatedAnswers[_state.currentQuizIndex] = isCorrect;

    _state = _state.copyWith(
      lastCorrectAnswer: index,
      quizAnswers: updatedAnswers,
    );
    notifyListeners();
  }

  int getQuizScore() {
    return _state.quizAnswers.values.where((isCorrect) => isCorrect).length;
  }

  double getQuizPercentage() {
    if (_state.quizAnswers.isEmpty) return 0;
    return (getQuizScore() / _state.quizAnswers.length) * 100;
  }

  bool allQuestionsAnswered() {
    return _state.quizAnswers.length == _state.quizWords.length;
  }

  void showQuizResults() {
    _state = _state.copyWith(showQuizResults: true);
    notifyListeners();
  }

  void hideQuizResults() {
    _state = _state.copyWith(showQuizResults: false);
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  // Calculate exact word count for a surah from word-by-word data
  Future<int> getExactWordCount(int surahNumber) async {
    try {
      final wordByWordMap = await _repo.getWordByWordForSurah(surahNumber);
      int totalWords = 0;
      for (final words in wordByWordMap.values) {
        totalWords += words.where((w) => w.farsi != null && w.farsi!.isNotEmpty).length;
      }
      return totalWords;
    } catch (e) {
      return 0;
    }
  }

  List<String> generateQuizOptions() {
    // Return stored options for current question
    return _state.quizOptions[_state.currentQuizIndex] ?? [];
  }

}

