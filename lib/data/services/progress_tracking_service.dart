import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress_model.dart';
import '../models/quiz_session_model.dart';
import '../models/quiz_question_model.dart';

/// Service for tracking and managing user progress
class ProgressTrackingService {
  static const String _progressKey = 'user_progress';
  static const String _sessionsKey = 'quiz_sessions';
  static const String _dailyStreakKey = 'daily_streak';

  /// Get user progress from local storage
  Future<UserProgressModel?> getUserProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('$_progressKey$userId');
      
      if (progressJson == null) return null;
      
      final progressMap = jsonDecode(progressJson) as Map<String, dynamic>;
      return UserProgressModel.fromJson(progressMap);
    } catch (e) {
      print('Error loading user progress: $e');
      return null;
    }
  }

  /// Save user progress to local storage
  Future<bool> saveUserProgress(UserProgressModel progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = jsonEncode(progress.toJson());
      return await prefs.setString('$_progressKey${progress.userId}', progressJson);
    } catch (e) {
      print('Error saving user progress: $e');
      return false;
    }
  }

  /// Update progress after quiz session completion
  Future<UserProgressModel> updateProgressAfterQuiz({
    required String userId,
    required QuizSessionModel session,
    required List<QuizQuestionModel> questions,
  }) async {
    UserProgressModel progress = await getUserProgress(userId) ?? 
        UserProgressModel.create(userId);

    // Update word progress for each question
    for (final answer in session.answers) {
      final question = questions.firstWhere(
        (q) => q.id == answer.questionId,
        orElse: () => throw StateError('Question not found'),
      );

      final wordId = question.id;
      final wordProgress = progress.wordProgress[wordId] ?? 
          WordProgressModel.create(wordId);

      final updatedWordProgress = wordProgress.markStudied(answer.isCorrect);
      progress = progress.copyWith(
        wordProgress: {
          ...progress.wordProgress,
          wordId: updatedWordProgress,
        },
      );
    }

    // Update overall progress
    final newTotalWordsLearned = progress.wordProgress.values
        .where((wp) => wp.isMastered)
        .length;

    final newTotalSessions = progress.totalSessionsCompleted + 1;

    // Update streak
    final (newCurrentStreak, newLongestStreak) = _updateStreak(
      progress.currentStreak,
      progress.longestStreak,
      progress.lastStudyDate,
    );

    progress = progress.copyWith(
      totalWordsLearned: newTotalWordsLearned,
      totalSessionsCompleted: newTotalSessions,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastStudyDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveUserProgress(progress);
    return progress;
  }

  /// Get words that need review
  Future<List<String>> getWordsForReview(String userId) async {
    final progress = await getUserProgress(userId);
    if (progress == null) return [];

    return progress.getWordsForReview();
  }

  /// Get daily quiz words (mix of new and review)
  Future<List<String>> getDailyQuizWords({
    required String userId,
    int newWordCount = 5,
    int reviewWordCount = 5,
  }) async {
    final progress = await getUserProgress(userId);
    if (progress == null) return [];

    final reviewWords = progress.getWordsForReview();
    final dailyWords = <String>[];

    // Add review words
    dailyWords.addAll(reviewWords.take(reviewWordCount));

    // Add new words (this would need to be implemented with word selection logic)
    // For now, return review words
    return dailyWords;
  }

  /// Check if user has studied today
  Future<bool> hasStudiedToday(String userId) async {
    final progress = await getUserProgress(userId);
    if (progress == null) return false;

    return progress.hasStudiedToday;
  }

  /// Get learning statistics
  Future<LearningStats> getLearningStats(String userId) async {
    final progress = await getUserProgress(userId);
    if (progress == null) return LearningStats.empty();

    final masteredWords = progress.wordProgress.values
        .where((wp) => wp.isMastered)
        .length;

    final totalWordsStudied = progress.wordProgress.length;
    final totalCorrectAnswers = progress.wordProgress.values
        .fold(0, (sum, wp) => sum + wp.correctCount);
    final totalIncorrectAnswers = progress.wordProgress.values
        .fold(0, (sum, wp) => sum + wp.incorrectCount);

    final overallAccuracy = (totalCorrectAnswers + totalIncorrectAnswers) > 0
        ? totalCorrectAnswers / (totalCorrectAnswers + totalIncorrectAnswers)
        : 0.0;

    return LearningStats(
      totalWordsStudied: totalWordsStudied,
      masteredWords: masteredWords,
      totalSessions: progress.totalSessionsCompleted,
      currentStreak: progress.currentStreak,
      longestStreak: progress.longestStreak,
      overallAccuracy: overallAccuracy,
      lastStudyDate: progress.lastStudyDate,
    );
  }

  /// Get progress by surah
  Future<Map<int, SurahProgress>> getSurahProgress(String userId) async {
    final progress = await getUserProgress(userId);
    if (progress == null) return {};

    final surahProgress = <int, SurahProgress>{};

    for (final wordProgress in progress.wordProgress.values) {
      // Parse wordId to get surah number
      final parts = wordProgress.wordId.split('_');
      if (parts.isNotEmpty) {
        final uniqueKey = parts[0];
        final surahNumber = int.tryParse(uniqueKey.split(':')[0]);
        
        if (surahNumber != null) {
          surahProgress[surahNumber] = surahProgress[surahNumber] ?? SurahProgress.empty();
          surahProgress[surahNumber] = surahProgress[surahNumber]!.addWord(wordProgress);
        }
      }
    }

    return surahProgress;
  }

  /// Reset user progress (for testing or account reset)
  Future<bool> resetUserProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_progressKey$userId');
      await prefs.remove('$_sessionsKey$userId');
      await prefs.remove('$_dailyStreakKey$userId');
      return true;
    } catch (e) {
      print('Error resetting user progress: $e');
      return false;
    }
  }

  /// Export user progress data
  Future<Map<String, dynamic>> exportUserProgress(String userId) async {
    final progress = await getUserProgress(userId);
    if (progress == null) return {};

    return {
      'user_id': userId,
      'export_date': DateTime.now().toIso8601String(),
      'progress': progress.toJson(),
    };
  }

  /// Import user progress data
  Future<bool> importUserProgress(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id'] as String;
      final progressData = data['progress'] as Map<String, dynamic>;
      
      final progress = UserProgressModel.fromJson(progressData);
      return await saveUserProgress(progress);
    } catch (e) {
      print('Error importing user progress: $e');
      return false;
    }
  }

  // Private helper methods

  (int, int) _updateStreak(int currentStreak, int longestStreak, DateTime lastStudyDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStudy = DateTime(lastStudyDate.year, lastStudyDate.month, lastStudyDate.day);
    
    final daysDifference = today.difference(lastStudy).inDays;
    
    if (daysDifference == 0) {
      // Already studied today
      return (currentStreak, longestStreak);
    } else if (daysDifference == 1) {
      // Studied yesterday, continue streak
      final newStreak = currentStreak + 1;
      return (newStreak, newStreak > longestStreak ? newStreak : longestStreak);
    } else {
      // Streak broken
      return (1, longestStreak);
    }
  }
}

/// Learning statistics for user
class LearningStats {
  final int totalWordsStudied;
  final int masteredWords;
  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final double overallAccuracy;
  final DateTime lastStudyDate;

  const LearningStats({
    required this.totalWordsStudied,
    required this.masteredWords,
    required this.totalSessions,
    required this.currentStreak,
    required this.longestStreak,
    required this.overallAccuracy,
    required this.lastStudyDate,
  });

  factory LearningStats.empty() {
    return LearningStats(
      totalWordsStudied: 0,
      masteredWords: 0,
      totalSessions: 0,
      currentStreak: 0,
      longestStreak: 0,
      overallAccuracy: 0.0,
      lastStudyDate: DateTime.now(),
    );
  }

  String get accuracyPercentage => '${(overallAccuracy * 100).toStringAsFixed(1)}%';
  String get masteryPercentage => totalWordsStudied > 0 
      ? '${((masteredWords / totalWordsStudied) * 100).toStringAsFixed(1)}%'
      : '0%';
}

/// Progress tracking for individual surahs
class SurahProgress {
  final int surahNumber;
  final int totalWords;
  final int studiedWords;
  final int masteredWords;
  final double accuracy;

  const SurahProgress({
    required this.surahNumber,
    required this.totalWords,
    required this.studiedWords,
    required this.masteredWords,
    required this.accuracy,
  });

  factory SurahProgress.empty() {
    return const SurahProgress(
      surahNumber: 0,
      totalWords: 0,
      studiedWords: 0,
      masteredWords: 0,
      accuracy: 0.0,
    );
  }

  SurahProgress addWord(WordProgressModel wordProgress) {
    final newStudiedWords = studiedWords + 1;
    final newMasteredWords = wordProgress.isMastered ? masteredWords + 1 : masteredWords;
    final newAccuracy = (wordProgress.correctCount + wordProgress.incorrectCount) > 0
        ? wordProgress.correctCount / (wordProgress.correctCount + wordProgress.incorrectCount)
        : 0.0;

    return SurahProgress(
      surahNumber: surahNumber,
      totalWords: totalWords,
      studiedWords: newStudiedWords,
      masteredWords: newMasteredWords,
      accuracy: newAccuracy,
    );
  }

  String get progressPercentage => totalWords > 0 
      ? '${((studiedWords / totalWords) * 100).toStringAsFixed(1)}%'
      : '0%';
}
