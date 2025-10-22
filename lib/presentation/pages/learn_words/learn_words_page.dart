import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/quiz_question_model.dart';
import '../../../data/models/quiz_session_model.dart';
import '../../../data/services/quiz_data_service.dart';
import '../../../data/services/quiz_mechanics_service.dart';
import '../../../data/services/progress_tracking_service.dart';
import '../../../data/services/daily_quiz_service.dart' as daily_service;
import '../../../data/datasources/remote/api_service.dart';
import '../../widgets/quiz_question_widget.dart';
import '../../widgets/quiz_progress_widget.dart';
import '../../widgets/learning_stats_widget.dart';
import '../../widgets/quiz_settings_widget.dart';
import '../../widgets/daily_quiz_widget.dart';

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

/// Quiz states
enum QuizState {
  idle,
  loading,
  playing,
  showingAnswer,
  completed,
  error,
}

/// Main quiz page using Supabase WBW data
class LearnWordsPage extends ConsumerStatefulWidget {
  const LearnWordsPage({super.key});

  @override
  ConsumerState<LearnWordsPage> createState() => _LearnWordsPageState();
}

class _LearnWordsPageState extends ConsumerState<LearnWordsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizStateProvider);
    final session = ref.watch(currentQuizSessionProvider);
    final questions = ref.watch(currentQuizQuestionsProvider);
    final currentIndex = ref.watch(currentQuestionIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Always navigate to home when back button is pressed
        GoRouter.of(context).go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Омӯзиши калимаҳо'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              GoRouter.of(context).go('/');
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
        ),
        body: _buildBody(quizState, session, questions, currentIndex),
      ),
    );
  }

  Widget _buildBody(
    QuizState quizState,
    QuizSessionModel? session,
    List<QuizQuestionModel> questions,
    int currentIndex,
  ) {
    switch (quizState) {
      case QuizState.idle:
        return _buildMainMenu();
      case QuizState.loading:
        return const Center(child: CircularProgressIndicator());
      case QuizState.playing:
      case QuizState.showingAnswer:
        return _buildQuizContent(session, questions, currentIndex);
      case QuizState.completed:
        return _buildQuizResults(session);
      case QuizState.error:
        return _buildErrorState();
    }
  }

  Widget _buildMainMenu() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Daily quiz section
          _buildDailyQuizSection(),
          
          // Quick start options
          _buildQuickStartOptions(),
          
          // Recent progress
          _buildRecentProgress(),
        ],
      ),
    );
  }

  Widget _buildDailyQuizSection() {
    return FutureBuilder<daily_service.DailyQuizStats>(
      future: _getDailyQuizStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data ?? daily_service.DailyQuizStats.empty();
        final streakInfo = snapshot.hasData ? daily_service.StreakInfo.empty() : daily_service.StreakInfo.empty();
        final recommendations = <String>[];
        final motivationalMessage = 'Омӯзиши калимаҳоро оғоз кунед!';

        return DailyQuizWidget(
          stats: stats,
          streakInfo: streakInfo,
          recommendations: recommendations,
          motivationalMessage: motivationalMessage,
          onStartQuiz: () => _startDailyQuiz(),
        );
      },
    );
  }

  Widget _buildQuickStartOptions() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Оғози зуд',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStartButton(
                    'Тасодуфӣ',
                    Icons.shuffle,
                    Colors.blue,
                    () => _startRandomQuiz(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStartButton(
                    'Аз сура',
                    Icons.book,
                    Colors.green,
                    () => _showSurahSelection(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStartButton(
                    'Такрорӣ',
                    Icons.refresh,
                    Colors.orange,
                    () => _startReviewQuiz(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStartButton(
                    'Омори',
                    Icons.analytics,
                    Colors.purple,
                    () => _showStatsDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRecentProgress() {
    return FutureBuilder<LearningStats>(
      future: _getLearningStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data ?? LearningStats.empty();
        return LearningStatsWidget(
          stats: stats,
          surahProgress: null, // Could be loaded separately
        );
      },
    );
  }

  Widget _buildQuizContent(
    QuizSessionModel? session,
    List<QuizQuestionModel> questions,
    int currentIndex,
  ) {
    if (session == null || questions.isEmpty) {
      return const Center(child: Text('Хатогии бозӣ'));
    }

    if (currentIndex >= questions.length) {
      return _buildQuizResults(session);
    }

    final question = questions[currentIndex];
    final isShowingAnswer = ref.watch(quizStateProvider) == QuizState.showingAnswer;

    return Column(
      children: [
        // Progress widget
        QuizProgressWidget(
          session: session,
          stats: null, // Could be calculated
        ),
        
        // Question widget
        Expanded(
          child: QuizQuestionWidget(
            question: question,
            onAnswerSelected: (index) => _handleAnswerSelected(index),
            showAnswer: isShowingAnswer,
            selectedAnswer: session.answers.isNotEmpty 
                ? session.answers.last.selectedOptionIndex 
                : null,
          ),
        ),
        
        // Navigation buttons
        if (isShowingAnswer) _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _nextQuestion(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Навбатӣ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResults(QuizSessionModel? session) {
    if (session == null) return const Center(child: Text('Хатогии бозӣ'));

    final accuracy = session.totalQuestions > 0 
        ? session.score / session.totalQuestions 
        : 0.0;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: accuracy >= 0.7 ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Бозӣ ба охир расид!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ҳисоб: ${session.score}/${session.totalQuestions}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Дақиқат: ${(accuracy * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _restartQuiz(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Такрор'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _goToMainMenu(),
                      icon: const Icon(Icons.home),
                      label: const Text('Асосӣ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Хатогии бозӣ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Хатогие рух дод. Лутфан боз кӯшиш кунед.'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _goToMainMenu(),
                icon: const Icon(Icons.refresh),
                label: const Text('Боз кӯшиш'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Event handlers

  Future<void> _startDailyQuiz() async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final dailyService = ref.read(dailyQuizServiceProvider);
      final session = await dailyService.createTodayQuiz(userId: 'user_1');
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await _loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  Future<void> _startRandomQuiz() async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: 'user_1',
        mode: QuizMode.random,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await _loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  void _showSurahSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сураро интихоб кунед'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 114,
            itemBuilder: (context, index) {
              final surahNumber = index + 1;
              return ListTile(
                title: Text('Сураи $surahNumber'),
                onTap: () {
                  Navigator.pop(context);
                  _startSurahQuiz(surahNumber);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startSurahQuiz(int surahNumber) async {
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
      await _loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  Future<void> _startReviewQuiz() async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: 'user_1',
        mode: QuizMode.review,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await _loadQuestionsForSession(session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  Future<void> _loadQuestionsForSession(QuizSessionModel session) async {
    final mechanicsService = ref.read(quizMechanicsServiceProvider);
    final questions = await mechanicsService.generateQuestionsForSession(session);
    
    ref.read(currentQuizQuestionsProvider.notifier).state = questions;
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
  }

  void _handleAnswerSelected(int selectedIndex) {
    final session = ref.read(currentQuizSessionProvider);
    final questions = ref.read(currentQuizQuestionsProvider);
    final currentIndex = ref.read(currentQuestionIndexProvider);
    
    if (session == null || questions.isEmpty) return;

    final question = questions[currentIndex];
    final timeToAnswer = _questionStartTime != null 
        ? DateTime.now().difference(_questionStartTime!)
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

  void _nextQuestion() {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    final questions = ref.read(currentQuizQuestionsProvider);
    
    if (currentIndex + 1 >= questions.length) {
      ref.read(quizStateProvider.notifier).state = QuizState.completed;
    } else {
      ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
      _questionStartTime = DateTime.now();
    }
  }

  void _restartQuiz() {
    ref.read(currentQuizSessionProvider.notifier).state = null;
    ref.read(currentQuizQuestionsProvider.notifier).state = [];
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(quizStateProvider.notifier).state = QuizState.idle;
  }

  void _goToMainMenu() {
    ref.read(currentQuizSessionProvider.notifier).state = null;
    ref.read(currentQuizQuestionsProvider.notifier).state = [];
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(quizStateProvider.notifier).state = QuizState.idle;
  }

  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Омори омӯзиш'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<LearningStats>(
            future: _getLearningStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final stats = snapshot.data ?? LearningStats.empty();
              return LearningStatsWidget(stats: stats);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Танзимот'),
        content: SizedBox(
          width: double.maxFinite,
          child: QuizSettingsWidget(
            wordCount: 10,
            shuffleOptions: true,
            showTransliteration: true,
            onWordCountChanged: (count) {},
            onShuffleOptionsChanged: (value) {},
            onShowTransliterationChanged: (value) {},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  // Helper methods

  Future<daily_service.DailyQuizStats> _getDailyQuizStats() async {
    final dailyService = ref.read(dailyQuizServiceProvider);
    return await dailyService.getDailyQuizStats('user_1');
  }

  Future<LearningStats> _getLearningStats() async {
    final progressService = ref.read(progressTrackingServiceProvider);
    return await progressService.getLearningStats('user_1');
  }
}