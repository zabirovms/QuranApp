import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/quiz_question_model.dart';
import '../../../data/models/quiz_session_model.dart';
import 'providers/learn_words_providers.dart';
import 'components/main_menu_widget.dart';
import 'components/quiz_content_widget.dart';
import 'components/error_state_widget.dart';
import 'components/quiz_completion_widget.dart';
import 'controllers/quiz_controller.dart';
import 'utils/quiz_helpers.dart';

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
  late QuizController _quizController;

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

    // Initialize quiz controller
    _quizController = QuizController(ref);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, quizState),
      body: _buildBody(quizState, session, questions, currentIndex),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, QuizState quizState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () {
          if (GoRouter.of(context).canPop()) {
            GoRouter.of(context).pop();
          } else {
            GoRouter.of(context).go('/');
          }
        },
      ),
      title: Text(
        _getAppBarTitle(quizState),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: _buildAppBarActions(context, quizState),
    );
  }

  String _getAppBarTitle(QuizState quizState) {
    switch (quizState) {
      case QuizState.idle:
        return 'Омӯзиши калимаҳо';
      case QuizState.loading:
        return 'Тайёр карда истода...';
      case QuizState.playing:
      case QuizState.showingAnswer:
        return 'Бозӣ';
      case QuizState.completed:
        return 'Натиҷа';
      case QuizState.error:
        return 'Хатогӣ';
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context, QuizState quizState) {
    if (quizState == QuizState.idle) {
      return [
        _buildActionButton(
          context,
          icon: Icons.analytics,
          onPressed: () => QuizHelpers.showStatsDialog(context, ref),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context,
          icon: Icons.settings,
          onPressed: () => QuizHelpers.showSettingsDialog(context, ref),
        ),
        const SizedBox(width: 16),
      ];
    }
    return [
      _buildActionButton(
        context,
        icon: Icons.home,
        onPressed: () => _quizController.goToMainMenu(),
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20),
        ),
        onPressed: onPressed,
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
        return const MainMenuWidget();
      case QuizState.loading:
        return _buildLoadingState();
      case QuizState.playing:
      case QuizState.showingAnswer:
        return QuizContentWidget(
          session: session,
          questions: questions,
          currentIndex: currentIndex,
          questionStartTime: _questionStartTime,
          onAnswerSelected: (index) => _handleAnswerSelected(index),
          onNextQuestion: _nextQuestion,
          onRestartQuiz: () => _quizController.restartQuiz(),
          onGoToMainMenu: () => _quizController.goToMainMenu(),
        );
      case QuizState.completed:
        return QuizCompletionWidget(
          session: session!,
          onRestart: () => _quizController.restartQuiz(),
          onGoToMainMenu: () => _quizController.goToMainMenu(),
        );
      case QuizState.error:
        return ErrorStateWidget(
          onRetry: () => _quizController.goToMainMenu(),
        );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Тайёр карда истода...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Лутфан интизор шавед',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _handleAnswerSelected(int selectedIndex) {
    _quizController.handleAnswerSelected(selectedIndex, _questionStartTime);
  }

  void _nextQuestion() {
    _quizController.nextQuestion();
    _questionStartTime = DateTime.now();
  }

  Widget _buildQuizResults(QuizSessionModel? session) {
    if (session == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Хатогии бозӣ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final accuracy = session.totalQuestions > 0 
        ? session.score / session.totalQuestions 
        : 0.0;
    final isGoodScore = accuracy >= 0.7;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result icon and score
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isGoodScore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                isGoodScore ? Icons.emoji_events : Icons.psychology,
                size: 40,
                color: isGoodScore ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            
            // Score display
            Text(
              '${session.score}/${session.totalQuestions}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGoodScore ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            
            // Accuracy percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isGoodScore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(accuracy * 100).toStringAsFixed(1)}% дақиқат',
                style: TextStyle(
                  color: isGoodScore ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _quizController.restartQuiz(),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Такрор кардан', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _quizController.goToMainMenu(),
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text('Асосӣ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}