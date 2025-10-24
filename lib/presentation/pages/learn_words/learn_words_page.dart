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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Initialize quiz controller
    _quizController = QuizController(ref);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context, quizState),
      body: _buildBody(quizState, session, questions, currentIndex),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, QuizState quizState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back, size: 20, color: colorScheme.onSurface),
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
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
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
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Тайёр карда истода...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Лутфан интизор шавед',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
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

}