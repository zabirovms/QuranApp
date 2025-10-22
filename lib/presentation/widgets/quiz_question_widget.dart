import 'package:flutter/material.dart';
import '../../data/models/quiz_question_model.dart';

/// Widget for displaying quiz questions with multiple choice options
class QuizQuestionWidget extends StatefulWidget {
  final QuizQuestionModel question;
  final Function(int) onAnswerSelected;
  final bool showAnswer;
  final int? selectedAnswer;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showAnswer = false,
    this.selectedAnswer,
  });

  @override
  State<QuizQuestionWidget> createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              _buildQuestionHeader(),
              const SizedBox(height: 24),
              
              // Arabic word
              _buildArabicWord(),
              const SizedBox(height: 16),
              
              // Transliteration (if available)
              if (widget.question.transliteration.isNotEmpty)
                _buildTransliteration(),
              
              const SizedBox(height: 24),
              
              // Answer options
              _buildAnswerOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      children: [
        Icon(
          Icons.quiz,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Ин калимаро интихоб кунед:',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildArabicWord() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Text(
        widget.question.arabicWord,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Amiri',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTransliteration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.question.transliteration,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Column(
      children: widget.question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = widget.selectedAnswer == index;
        final isCorrect = index == widget.question.correctOptionIndex;
        final isWrong = isSelected && !isCorrect;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: _getOptionColor(isSelected, isCorrect, isWrong),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.showAnswer ? null : () => widget.onAnswerSelected(index),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBorderColor(isSelected, isCorrect, isWrong),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Option letter
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getOptionLetterColor(isSelected, isCorrect, isWrong),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            color: _getOptionTextColor(isSelected, isCorrect, isWrong),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Option text
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: _getOptionTextColor(isSelected, isCorrect, isWrong),
                        ),
                      ),
                    ),
                    
                    // Result icon
                    if (widget.showAnswer)
                      Icon(
                        isCorrect ? Icons.check_circle : isWrong ? Icons.cancel : null,
                        color: isCorrect ? Colors.green : isWrong ? Colors.red : null,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getOptionColor(bool isSelected, bool isCorrect, bool isWrong) {
    if (widget.showAnswer) {
      if (isCorrect) return Colors.green.withOpacity(0.1);
      if (isWrong) return Colors.red.withOpacity(0.1);
    }
    if (isSelected) return Theme.of(context).primaryColor.withOpacity(0.1);
    return Colors.transparent;
  }

  Color _getBorderColor(bool isSelected, bool isCorrect, bool isWrong) {
    if (widget.showAnswer) {
      if (isCorrect) return Colors.green;
      if (isWrong) return Colors.red;
    }
    if (isSelected) return Theme.of(context).primaryColor;
    return Colors.grey[300]!;
  }

  Color _getOptionLetterColor(bool isSelected, bool isCorrect, bool isWrong) {
    if (widget.showAnswer) {
      if (isCorrect) return Colors.green;
      if (isWrong) return Colors.red;
    }
    if (isSelected) return Theme.of(context).primaryColor;
    return Colors.grey[400]!;
  }

  Color _getOptionTextColor(bool isSelected, bool isCorrect, bool isWrong) {
    if (widget.showAnswer) {
      if (isCorrect) return Colors.green[800]!;
      if (isWrong) return Colors.red[800]!;
    }
    if (isSelected) return Theme.of(context).primaryColor;
    return Colors.black87;
  }
}
