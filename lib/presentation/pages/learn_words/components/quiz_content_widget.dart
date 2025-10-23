import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/quiz_question_model.dart';
import '../../../../data/models/quiz_session_model.dart';
import '../../../widgets/quiz_question_widget.dart';
import '../../../widgets/quiz_progress_widget.dart';
import '../providers/learn_words_providers.dart';

class QuizContentWidget extends ConsumerWidget {
  final QuizSessionModel? session;
  final List<QuizQuestionModel> questions;
  final int currentIndex;
  final DateTime? questionStartTime;
  final Function(int) onAnswerSelected;
  final VoidCallback onNextQuestion;
  final VoidCallback onRestartQuiz;
  final VoidCallback onGoToMainMenu;

  const QuizContentWidget({
    super.key,
    required this.session,
    required this.questions,
    required this.currentIndex,
    this.questionStartTime,
    required this.onAnswerSelected,
    required this.onNextQuestion,
    required this.onRestartQuiz,
    required this.onGoToMainMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session == null || questions.isEmpty) {
      return _buildErrorState(context, 'Маълумотҳои бозӣ ёфт нашуд. Лутфан боз кӯшиш кунед.');
    }

    if (currentIndex >= questions.length) {
      return _buildQuizResults(context, session!);
    }

    final question = questions[currentIndex];
    final isShowingAnswer = ref.watch(quizStateProvider) == QuizState.showingAnswer;

    return Column(
      children: [
        // Progress widget
        QuizProgressWidget(
          session: session!,
          stats: null, // Could be calculated
        ),
        
        // Question widget
        Expanded(
          child: QuizQuestionWidget(
            question: question,
            onAnswerSelected: onAnswerSelected,
            showAnswer: isShowingAnswer,
            selectedAnswer: session!.answers.isNotEmpty 
                ? session!.answers.last.selectedOptionIndex 
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
              onPressed: onNextQuestion,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Навбатӣ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResults(BuildContext context, QuizSessionModel session) {
    final accuracy = session.totalQuestions > 0 
        ? session.score / session.totalQuestions 
        : 0.0;

    return SingleChildScrollView(
      child: Center(
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
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ҳисоб: ${session.score}/${session.totalQuestions}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Дақиқат: ${(accuracy * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRestartQuiz,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Такрор'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onGoToMainMenu,
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
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Хатогии бозӣ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onGoToMainMenu,
                icon: const Icon(Icons.home),
                label: const Text('Бозгашт ба асосӣ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
