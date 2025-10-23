import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/quiz_question_model.dart';
import '../../../../data/models/quiz_session_model.dart';
import '../../../../data/services/quiz_data_service.dart';
import '../../../../data/services/quiz_mechanics_service.dart';
import '../../../../data/services/progress_tracking_service.dart';
import '../../../../data/services/daily_quiz_service.dart' as daily_service;
import '../../../../data/services/user_service.dart';
import '../../../../data/datasources/remote/api_service.dart';

/// Quiz states
enum QuizState {
  idle,
  loading,
  playing,
  showingAnswer,
  completed,
  error,
}

/// Provider for UserService
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Provider for current user ID
final currentUserIdProvider = FutureProvider<String>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getCurrentUserId();
});

/// Provider for QuizDataService
final quizDataServiceProvider = Provider<QuizDataService>((ref) {
  final apiService = ApiService();
  return QuizDataService(apiService: apiService);
});

/// Provider for QuizMechanicsService
final quizMechanicsServiceProvider = Provider<QuizMechanicsService>((ref) {
  final dataService = ref.watch(quizDataServiceProvider);
  return QuizMechanicsService(dataService: dataService);
});

/// Provider for ProgressTrackingService
final progressTrackingServiceProvider = Provider<ProgressTrackingService>((ref) {
  return ProgressTrackingService();
});

/// Provider for DailyQuizService
final dailyQuizServiceProvider = Provider<daily_service.DailyQuizService>((ref) {
  final dataService = ref.watch(quizDataServiceProvider);
  final mechanicsService = ref.watch(quizMechanicsServiceProvider);
  final progressService = ref.watch(progressTrackingServiceProvider);
  return daily_service.DailyQuizService(
    dataService: dataService,
    mechanicsService: mechanicsService,
    progressService: progressService,
  );
});

/// Provider for current quiz session
final currentQuizSessionProvider = StateProvider<QuizSessionModel?>((ref) => null);

/// Provider for current quiz questions
final currentQuizQuestionsProvider = StateProvider<List<QuizQuestionModel>>((ref) => []);

/// Provider for current question index
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for quiz state
final quizStateProvider = StateProvider<QuizState>((ref) => QuizState.idle);
