import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/quiz_session_model.dart';

/// Enhanced quiz completion widget with better feedback and animations
class QuizCompletionWidget extends ConsumerStatefulWidget {
  final QuizSessionModel session;
  final VoidCallback onRestart;
  final VoidCallback onGoToMainMenu;

  const QuizCompletionWidget({
    super.key,
    required this.session,
    required this.onRestart,
    required this.onGoToMainMenu,
  });

  @override
  ConsumerState<QuizCompletionWidget> createState() => _QuizCompletionWidgetState();
}

class _QuizCompletionWidgetState extends ConsumerState<QuizCompletionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scoreController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.session.totalQuestions > 0 
        ? widget.session.score / widget.session.totalQuestions 
        : 0.0;
    final isGoodScore = accuracy >= 0.7;
    final isExcellentScore = accuracy >= 0.9;

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
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
                // Result icon with animation
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scoreAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _getResultColor(isGoodScore, isExcellentScore).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          _getResultIcon(isGoodScore, isExcellentScore),
                          size: 40,
                          color: _getResultColor(isGoodScore, isExcellentScore),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Score display with animation
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Text(
                      '${widget.session.score}/${widget.session.totalQuestions}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getResultColor(isGoodScore, isExcellentScore),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                
                // Accuracy percentage
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getResultColor(isGoodScore, isExcellentScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(accuracy * 100).toStringAsFixed(1)}% дақиқат',
                    style: TextStyle(
                      color: _getResultColor(isGoodScore, isExcellentScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Performance feedback
                Text(
                  _getPerformanceMessage(accuracy),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: widget.onRestart,
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
                        onPressed: widget.onGoToMainMenu,
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
        ),
      ),
    );
  }

  Color _getResultColor(bool isGoodScore, bool isExcellentScore) {
    if (isExcellentScore) return Colors.green;
    if (isGoodScore) return Colors.blue;
    return Colors.orange;
  }

  IconData _getResultIcon(bool isGoodScore, bool isExcellentScore) {
    if (isExcellentScore) return Icons.emoji_events;
    if (isGoodScore) return Icons.star;
    return Icons.psychology;
  }

  String _getPerformanceMessage(double accuracy) {
    if (accuracy >= 0.9) {
      return 'Аъло! Шумо хеле хуб омӯхтаед!';
    } else if (accuracy >= 0.7) {
      return 'Хуб! Боз якчанд маротиба такрор кунед.';
    } else if (accuracy >= 0.5) {
      return 'Мутавассит. Калимаҳоро боз омӯхта лозим аст.';
    } else {
      return 'Калимаҳоро аз нав омӯхта лозим аст.';
    }
  }
}
