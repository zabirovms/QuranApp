import 'dart:math';
import '../models/quiz_question_model.dart';
import '../models/quiz_session_model.dart';
import '../models/user_progress_model.dart';
import '../services/quiz_data_service.dart';

/// Service for managing quiz mechanics and game logic
class QuizMechanicsService {
  final QuizDataService _dataService;
  final Random _random = Random();

  QuizMechanicsService({required QuizDataService dataService}) 
      : _dataService = dataService;

  /// Create a new quiz session
  Future<QuizSessionModel> createQuizSession({
    required String userId,
    required QuizMode mode,
    int? surahNumber,
    int wordCount = 10,
  }) async {
    List<String> questionIds = [];

    switch (mode) {
      case QuizMode.random:
        questionIds = await _createRandomQuiz(wordCount);
        break;
      case QuizMode.surah:
        if (surahNumber != null) {
          questionIds = await _createSurahQuiz(surahNumber, wordCount);
        }
        break;
      case QuizMode.daily:
        questionIds = await _createDailyQuiz(userId, wordCount);
        break;
      case QuizMode.review:
        questionIds = await _createReviewQuiz(userId, wordCount);
        break;
    }

    return QuizSessionModel.create(
      userId: userId,
      questionIds: questionIds,
      mode: mode,
      surahNumber: surahNumber,
      dailyWordCount: mode == QuizMode.daily ? wordCount : null,
    );
  }

  /// Generate quiz questions for a session
  Future<List<QuizQuestionModel>> generateQuestionsForSession(
    QuizSessionModel session,
  ) async {
    final questions = <QuizQuestionModel>[];
    
    for (final questionId in session.questionIds) {
      final question = await _generateQuestionFromId(questionId, session);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Process user's answer and update session
  QuizSessionModel processAnswer({
    required QuizSessionModel session,
    required String questionId,
    required int selectedOptionIndex,
    required DateTime answeredAt,
    required Duration timeToAnswer,
  }) {
    final question = _getQuestionFromSession(session, questionId);
    if (question == null) return session;

    final isCorrect = selectedOptionIndex == question.correctOptionIndex;
    final newScore = isCorrect ? session.score + 1 : session.score;

    final answer = QuizAnswerModel(
      questionId: questionId,
      selectedOptionIndex: selectedOptionIndex,
      isCorrect: isCorrect,
      answeredAt: answeredAt,
      timeToAnswer: timeToAnswer,
    );

    final updatedAnswers = List<QuizAnswerModel>.from(session.answers)..add(answer);
    final isCompleted = updatedAnswers.length >= session.totalQuestions;

    return session.copyWith(
      answers: updatedAnswers,
      score: newScore,
      completedAt: isCompleted ? answeredAt : null,
    );
  }

  /// Shuffle quiz options to prevent pattern recognition
  QuizQuestionModel shuffleQuestionOptions(QuizQuestionModel question) {
    final shuffledOptions = List<String>.from(question.options);
    shuffledOptions.shuffle();
    
    final newCorrectIndex = shuffledOptions.indexOf(question.correctTranslation);
    
    return question.copyWith(
      options: shuffledOptions,
      correctOptionIndex: newCorrectIndex,
    );
  }

  /// Get adaptive difficulty based on user performance
  int getAdaptiveWordCount({
    required UserProgressModel userProgress,
    required QuizMode mode,
  }) {
    final baseCount = 10;
    final accuracy = userProgress.totalSessionsCompleted > 0 
        ? userProgress.totalSessionsCompleted / (userProgress.totalSessionsCompleted + 1)
        : 0.5;

    if (accuracy > 0.8) {
      return baseCount + 5; // Increase difficulty for good performers
    } else if (accuracy < 0.5) {
      return baseCount - 3; // Decrease difficulty for struggling users
    }
    
    return baseCount;
  }

  /// Calculate quiz statistics
  QuizStats calculateQuizStats(QuizSessionModel session) {
    if (session.answers.isEmpty) {
      return QuizStats.empty();
    }

    final correctAnswers = session.answers.where((a) => a.isCorrect).length;
    final totalAnswers = session.answers.length;
    final accuracy = totalAnswers > 0 ? correctAnswers / totalAnswers : 0.0;
    
    final averageTime = session.answers
        .map((a) => a.timeToAnswer.inMilliseconds)
        .reduce((a, b) => a + b) / totalAnswers;

    final fastestAnswer = session.answers
        .map((a) => a.timeToAnswer)
        .reduce((a, b) => a < b ? a : b);

    final slowestAnswer = session.answers
        .map((a) => a.timeToAnswer)
        .reduce((a, b) => a > b ? a : b);

    return QuizStats(
      accuracy: accuracy,
      averageTime: Duration(milliseconds: averageTime.round()),
      fastestAnswer: fastestAnswer,
      slowestAnswer: slowestAnswer,
      totalQuestions: session.totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: totalAnswers - correctAnswers,
    );
  }

  /// Get performance feedback based on quiz results
  String getPerformanceFeedback(QuizStats stats) {
    if (stats.accuracy >= 0.9) {
      return "Аъло! Шумо хеле хуб омӯхтаед!";
    } else if (stats.accuracy >= 0.7) {
      return "Хуб! Боз якчанд маротиба такрор кунед.";
    } else if (stats.accuracy >= 0.5) {
      return "Мутавассит. Калимаҳоро боз омӯхта лозим аст.";
    } else {
      return "Калимаҳоро аз нав омӯхта лозим аст.";
    }
  }

  // Private helper methods

  Future<List<String>> _createRandomQuiz(int wordCount) async {
    final words = await _dataService.getRandomWords(count: wordCount);
    return words.map((w) => '${w.uniqueKey}_${w.wordNumber}').toList();
  }

  Future<List<String>> _createSurahQuiz(int surahNumber, int wordCount) async {
    final words = await _dataService.getWordsForSurah(surahNumber);
    words.shuffle();
    return words.take(wordCount).map((w) => '${w.uniqueKey}_${w.wordNumber}').toList();
  }

  Future<List<String>> _createDailyQuiz(String userId, int wordCount) async {
    // This would require user progress data
    // For now, return random words
    return await _createRandomQuiz(wordCount);
  }

  Future<List<String>> _createReviewQuiz(String userId, int wordCount) async {
    // This would require user progress data
    // For now, return random words
    return await _createRandomQuiz(wordCount);
  }

  Future<QuizQuestionModel?> _generateQuestionFromId(
    String questionId,
    QuizSessionModel session,
  ) async {
    // Parse questionId to get WBW data
    final parts = questionId.split('_');
    if (parts.length < 2) return null;

    final uniqueKey = parts[0];
    final wordNumber = int.tryParse(parts[1]);
    if (wordNumber == null) return null;

    final surahNumber = int.tryParse(uniqueKey.split(':')[0]);
    if (surahNumber == null) return null;

    final words = await _dataService.getWordsForSurah(surahNumber);
    final word = words.firstWhere(
      (w) => w.uniqueKey == uniqueKey && w.wordNumber == wordNumber,
      orElse: () => throw StateError('Word not found'),
    );

    final questions = await _dataService.generateQuizQuestions(
      words: [word],
      surahReference: 'Сураи $surahNumber',
    );

    return questions.isNotEmpty ? questions.first : null;
  }

  QuizQuestionModel? _getQuestionFromSession(
    QuizSessionModel session,
    String questionId,
  ) {
    // This would need to be implemented with proper question storage
    // For now, return null
    return null;
  }
}

/// Statistics for quiz performance
class QuizStats {
  final double accuracy;
  final Duration averageTime;
  final Duration fastestAnswer;
  final Duration slowestAnswer;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;

  const QuizStats({
    required this.accuracy,
    required this.averageTime,
    required this.fastestAnswer,
    required this.slowestAnswer,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });

  factory QuizStats.empty() {
    return const QuizStats(
      accuracy: 0.0,
      averageTime: Duration.zero,
      fastestAnswer: Duration.zero,
      slowestAnswer: Duration.zero,
      totalQuestions: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
    );
  }

  String get accuracyPercentage => '${(accuracy * 100).toStringAsFixed(1)}%';
  String get averageTimeFormatted => _formatDuration(averageTime);
  String get fastestTimeFormatted => _formatDuration(fastestAnswer);
  String get slowestTimeFormatted => _formatDuration(slowestAnswer);

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}с';
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}м ${seconds}с';
    }
  }
}
