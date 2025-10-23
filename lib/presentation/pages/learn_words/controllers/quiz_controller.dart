import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/quiz_session_model.dart';
import '../providers/learn_words_providers.dart';
import '../utils/quiz_helpers.dart';

class QuizController {
  final WidgetRef ref;

  QuizController(this.ref);

  /// Handle answer selection
  void handleAnswerSelected(int selectedIndex, DateTime? questionStartTime) {
    final session = ref.read(currentQuizSessionProvider);
    final questions = ref.read(currentQuizQuestionsProvider);
    final currentIndex = ref.read(currentQuestionIndexProvider);
    
    if (session == null || questions.isEmpty || currentIndex >= questions.length) return;

    final question = questions[currentIndex];
    final timeToAnswer = questionStartTime != null 
        ? DateTime.now().difference(questionStartTime)
        : const Duration(seconds: 0);

    final mechanicsService = ref.read(quizMechanicsServiceProvider);
    final updatedSession = mechanicsService.processAnswer(
      session: session,
      questionId: question.id,
      selectedOptionIndex: selectedIndex,
      answeredAt: DateTime.now(),
      timeToAnswer: timeToAnswer,
    );

    ref.read(currentQuizSessionProvider.notifier).state = updatedSession;
    ref.read(quizStateProvider.notifier).state = QuizState.showingAnswer;
  }

  /// Move to next question
  void nextQuestion() {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    final questions = ref.read(currentQuizQuestionsProvider);
    
    if (currentIndex + 1 >= questions.length) {
      _completeQuiz();
    } else {
      ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    }
  }

  /// Complete quiz and update progress
  Future<void> _completeQuiz() async {
    final session = ref.read(currentQuizSessionProvider);
    final questions = ref.read(currentQuizQuestionsProvider);
    
    if (session != null && questions.isNotEmpty) {
      try {
        // Update user progress
        final progressService = ref.read(progressTrackingServiceProvider);
        await progressService.updateProgressAfterQuiz(
          userId: session.userId,
          session: session,
          questions: questions,
        );
        
        // Clear stats cache to refresh analytics
        QuizHelpers.clearStatsCache();
      } catch (e) {
        print('Error updating progress: $e');
      }
    }
    
    ref.read(quizStateProvider.notifier).state = QuizState.completed;
  }

  /// Restart quiz
  void restartQuiz() {
    ref.read(currentQuizSessionProvider.notifier).state = null;
    ref.read(currentQuizQuestionsProvider.notifier).state = [];
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(quizStateProvider.notifier).state = QuizState.idle;
  }

  /// Go to main menu
  void goToMainMenu() {
    ref.read(currentQuizSessionProvider.notifier).state = null;
    ref.read(currentQuizQuestionsProvider.notifier).state = [];
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(quizStateProvider.notifier).state = QuizState.idle;
  }

  /// Load questions for a session
  Future<void> loadQuestionsForSession(QuizSessionModel session) async {
    try {
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final questions = await mechanicsService.generateQuestionsForSession(session);
      
      if (questions.isEmpty) {
        throw Exception('Саволҳо эҷод нашуд');
      }
      
      ref.read(currentQuizQuestionsProvider.notifier).state = questions;
      ref.read(currentQuestionIndexProvider.notifier).state = 0;
    } catch (e) {
      print('Error loading questions: $e');
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  /// Start daily quiz
  Future<void> startDailyQuiz() async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final dailyService = ref.read(dailyQuizServiceProvider);
      final session = await dailyService.createTodayQuiz(userId: 'user_1');
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      print('Error starting daily quiz: $e');
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  /// Start random quiz
  Future<void> startRandomQuiz() async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: 'user_1',
        mode: QuizMode.random,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      print('Error starting random quiz: $e');
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  /// Start surah quiz
  Future<void> startSurahQuiz(int surahNumber) async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: 'user_1',
        mode: QuizMode.surah,
        surahNumber: surahNumber,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  /// Start review quiz
  Future<void> startReviewQuiz() async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: 'user_1',
        mode: QuizMode.review,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }
}
