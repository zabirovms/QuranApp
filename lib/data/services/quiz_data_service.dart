import 'dart:math';
import 'package:dio/dio.dart';
import '../datasources/remote/api_service.dart';
import '../models/word_by_word_model.dart';
import '../models/quiz_question_model.dart';
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
      print('Fetching word-by-word data for surah $surahNumber...');
      
      // Direct fetch from word_by_word table for the surah
      final wbwResponse = await _apiService.getWordByWordForSurah(surahNumber).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Timeout fetching WBW data for surah $surahNumber');
          return Response(
            requestOptions: RequestOptions(),
            data: [],
          );
        },
      );
      
      final wbwData = (wbwResponse.data as List?) ?? [];
      print('Fetched ${wbwData.length} word-by-word entries for surah $surahNumber');
      
      if (wbwData.isEmpty) {
        print('No word-by-word data found for surah $surahNumber');
        return [];
      }

      // Convert to WordByWordModel and filter valid words
      final allWords = wbwData
          .map((item) => WordByWordModel.fromJson(item))
          .where((w) => w.farsi != null && w.farsi!.isNotEmpty)
          .toList();

      print('Valid words with translations: ${allWords.length}');
      
      _wbwCache[cacheKey] = allWords;
      return allWords;
    } catch (e) {
      print('Error fetching words for surah $surahNumber: $e');
      return [];
    }
  }

  /// Fetch random words from all surahs (optimized with caching)
  Future<List<WordByWordModel>> getRandomWords({int count = 10}) async {
    print('Fetching $count random words...');
    
    // Check if we have enough cached words
    final allCachedWords = <WordByWordModel>[];
    for (final words in _wbwCache.values) {
      allCachedWords.addAll(words);
    }
    
    if (allCachedWords.length >= count) {
      print('Using ${allCachedWords.length} cached words');
      allCachedWords.shuffle();
      return allCachedWords.take(count).toList();
    }
    
    // If not enough cached words, fetch from popular surahs
    final popularSurahs = [1, 2, 3, 4, 5, 18, 19, 20, 21, 22, 55, 67, 78, 112, 113, 114];
    final allWords = <WordByWordModel>[];
    
    for (final surahNumber in popularSurahs) {
      try {
        final words = await getWordsForSurah(surahNumber);
        allWords.addAll(words);
        
        print('Surah $surahNumber: ${words.length} words (total: ${allWords.length})');
        
        // If we have enough words, break early
        if (allWords.length >= count * 3) break;
      } catch (e) {
        print('Error fetching surah $surahNumber: $e');
        continue;
      }
    }

    if (allWords.isEmpty) {
      print('No words found! Check your database connection and data.');
      return [];
    }

    // Shuffle and return requested count
    allWords.shuffle();
    final selectedWords = allWords.take(count).toList();
    print('Selected ${selectedWords.length} random words');
    return selectedWords;
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
    
    if (words.isEmpty) return questions;
    
    // Get all available translations for wrong options
    final allTranslations = await _getAllTranslations();
    
    for (final word in words) {
      if (word.farsi == null || word.farsi!.isEmpty) {
        print('Skipping word ${word.uniqueKey} - no translation');
        continue;
      }
      
      // Ensure we have enough wrong options
      if (allTranslations.length < 3) {
        print('Not enough translations for wrong options, skipping word ${word.uniqueKey}');
        continue;
      }
      
      // Generate wrong options (3 random translations excluding the correct one)
      final wrongOptions = _generateWrongOptions(
        correctTranslation: word.farsi!,
        allTranslations: allTranslations,
        count: 3,
      );
      
      // Ensure we have exactly 4 options (1 correct + 3 wrong)
      if (wrongOptions.length < 3) {
        print('Not enough wrong options for word ${word.uniqueKey}, skipping');
        continue;
      }
      
      try {
        final question = QuizQuestionModel.fromWordByWord(
          wbw: word,
          wrongOptions: wrongOptions,
          surahReference: surahReference,
        );
        
        questions.add(question);
      } catch (e) {
        print('Error creating question for word ${word.uniqueKey}: $e');
        continue;
      }
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
