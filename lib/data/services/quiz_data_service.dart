import 'dart:math';
import '../datasources/remote/api_service.dart';
import '../models/word_by_word_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_session_model.dart';
import '../models/user_progress_model.dart';

/// Service for efficiently fetching and managing WBW data for the quiz game
class QuizDataService {
  final ApiService _apiService;
  final Map<String, List<WordByWordModel>> _wbwCache = {};
  final Map<String, List<String>> _translationCache = {};

  QuizDataService({required ApiService apiService}) : _apiService = apiService;

  /// Fetch WBW data for a specific surah
  Future<List<WordByWordModel>> getWordsForSurah(int surahNumber) async {
    final cacheKey = 'surah_$surahNumber';
    
    if (_wbwCache.containsKey(cacheKey)) {
      return _wbwCache[cacheKey]!;
    }

    try {
      // Get verses for the surah
      final versesResponse = await _apiService.getVersesBySurah(surahNumber);
      final verses = (versesResponse.data as List?) ?? [];
      
      if (verses.isEmpty) return [];

      // Extract unique keys
      final uniqueKeys = verses
          .map((v) => v['unique_key'] as String?)
          .where((key) => key != null)
          .cast<String>()
          .toList();

      // Fetch WBW data in batches
      final allWords = <WordByWordModel>[];
      const batchSize = 50;
      
      for (int i = 0; i < uniqueKeys.length; i += batchSize) {
        final batch = uniqueKeys.sublist(
          i,
          i + batchSize > uniqueKeys.length ? uniqueKeys.length : i + batchSize,
        );
        
        try {
          final wbwResponse = await _apiService.getWordByWordByKeys(batch);
          final wbwData = (wbwResponse.data as List?) ?? [];
          
          allWords.addAll(
            wbwData.map((item) => WordByWordModel.fromJson(item)),
          );
        } catch (e) {
          // Continue with other batches
          print('Error fetching WBW batch: $e');
        }
      }

      // Filter out words without translations
      final validWords = allWords.where((w) => w.farsi != null && w.farsi!.isNotEmpty).toList();
      
      _wbwCache[cacheKey] = validWords;
      return validWords;
    } catch (e) {
      print('Error fetching words for surah $surahNumber: $e');
      return [];
    }
  }

  /// Fetch random words from all surahs
  Future<List<WordByWordModel>> getRandomWords({int count = 10}) async {
    final allWords = <WordByWordModel>[];
    
    // Fetch from multiple random surahs to get variety
    final randomSurahs = _getRandomSurahNumbers(count: 5);
    
    for (final surahNumber in randomSurahs) {
      final words = await getWordsForSurah(surahNumber);
      allWords.addAll(words);
    }

    // Shuffle and return requested count
    allWords.shuffle();
    return allWords.take(count).toList();
  }

  /// Get words for daily quiz (mix of new and review words)
  Future<List<WordByWordModel>> getDailyWords({
    required String userId,
    required UserProgressModel userProgress,
    int count = 10,
  }) async {
    final dailyWords = <WordByWordModel>[];
    
    // Get words that need review (50% of daily words)
    final reviewWords = await _getReviewWords(userProgress, count ~/ 2);
    dailyWords.addAll(reviewWords);

    // Get new random words (50% of daily words)
    final remainingCount = count - dailyWords.length;
    if (remainingCount > 0) {
      final newWords = await getRandomWords(count: remainingCount);
      dailyWords.addAll(newWords);
    }

    return dailyWords;
  }

  /// Generate quiz questions from WBW data
  Future<List<QuizQuestionModel>> generateQuizQuestions({
    required List<WordByWordModel> words,
    required String surahReference,
  }) async {
    final questions = <QuizQuestionModel>[];
    
    // Get all available translations for wrong options
    final allTranslations = await _getAllTranslations();
    
    for (final word in words) {
      if (word.farsi == null || word.farsi!.isEmpty) continue;
      
      // Generate wrong options (3 random translations excluding the correct one)
      final wrongOptions = _generateWrongOptions(
        correctTranslation: word.farsi!,
        allTranslations: allTranslations,
        count: 3,
      );
      
      final question = QuizQuestionModel.fromWordByWord(
        wbw: word,
        wrongOptions: wrongOptions,
        surahReference: surahReference,
      );
      
      questions.add(question);
    }
    
    return questions;
  }

  /// Get words that need review based on user progress
  Future<List<WordByWordModel>> _getReviewWords(
    UserProgressModel userProgress,
    int count,
  ) async {
    final reviewWordIds = userProgress.getWordsForReview();
    final reviewWords = <WordByWordModel>[];
    
    // Get WBW data for words that need review
    for (final wordId in reviewWordIds.take(count)) {
      // Parse wordId to get surah and verse info
      final parts = wordId.split('_');
      if (parts.length >= 2) {
        final uniqueKey = parts[0];
        final surahNumber = int.tryParse(uniqueKey.split(':')[0]);
        
        if (surahNumber != null) {
          final words = await getWordsForSurah(surahNumber);
          final word = words.firstWhere(
            (w) => w.uniqueKey == uniqueKey,
            orElse: () => throw StateError('Word not found'),
          );
          reviewWords.add(word);
        }
      }
    }
    
    return reviewWords;
  }

  /// Get all available translations for generating wrong options
  Future<List<String>> _getAllTranslations() async {
    if (_translationCache.isNotEmpty) {
      return _translationCache.values.expand((list) => list).toList();
    }

    final allTranslations = <String>[];
    
    // Sample from multiple surahs to get diverse translations
    final sampleSurahs = [1, 2, 3, 4, 5, 18, 19, 20, 21, 22]; // Mix of different surahs
    
    for (final surahNumber in sampleSurahs) {
      final words = await getWordsForSurah(surahNumber);
      final translations = words
          .map((w) => w.farsi)
          .where((t) => t != null && t.isNotEmpty)
          .cast<String>()
          .toList();
      
      allTranslations.addAll(translations);
    }
    
    // Cache translations
    _translationCache['all'] = allTranslations;
    return allTranslations;
  }

  /// Generate wrong options for quiz questions
  List<String> _generateWrongOptions({
    required String correctTranslation,
    required List<String> allTranslations,
    required int count,
  }) {
    final wrongOptions = <String>[];
    final availableTranslations = allTranslations
        .where((t) => t != correctTranslation)
        .toList();
    
    // Shuffle and take random translations
    availableTranslations.shuffle();
    
    for (int i = 0; i < count && i < availableTranslations.length; i++) {
      wrongOptions.add(availableTranslations[i]);
    }
    
    return wrongOptions;
  }

  /// Get random surah numbers for variety
  List<int> _getRandomSurahNumbers({int count = 5}) {
    final random = Random();
    final surahNumbers = <int>{};
    
    while (surahNumbers.length < count) {
      surahNumbers.add(random.nextInt(114) + 1); // Surahs 1-114
    }
    
    return surahNumbers.toList();
  }

  /// Clear cache to free memory
  void clearCache() {
    _wbwCache.clear();
    _translationCache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'wbw_cache_size': _wbwCache.length,
      'translation_cache_size': _translationCache.length,
      'total_cached_words': _wbwCache.values.fold(0, (sum, list) => sum + list.length),
    };
  }
}
