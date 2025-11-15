import 'package:flutter/material.dart';
import '../learn_words_constants.dart';
import '../../../../core/theme/app_theme.dart';

class QuizProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback? onShowResults;

  const QuizProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.isAnswered,
    this.isCorrect,
    this.onShowResults,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / totalQuestions;

    return Column(
      children: [
        Text(
          LearnWordsLocalizations.buildQuizProgress(currentIndex + 1, totalQuestions),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        CircularProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800]
              : Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          strokeWidth: LearnWordsConstants.quizProgressStrokeWidth,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isAnswered)
              _buildAnswerBadge(isCorrect == true)
            else
              const SizedBox(),
            if (onShowResults != null)
              ElevatedButton.icon(
                onPressed: onShowResults,
                icon: const Icon(LearnWordsConstants.quizIcon, size: LearnWordsConstants.iconSize),
                label: const Text(LearnWordsConstants.showResultsLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              )
            else
              const SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerBadge(bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCorrect ? LearnWordsConstants.correctAnswer : LearnWordsConstants.wrongAnswer,
        style: TextStyle(
          color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
