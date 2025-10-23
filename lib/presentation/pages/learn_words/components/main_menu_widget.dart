import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/quiz_session_model.dart';
import '../providers/learn_words_providers.dart';

class MainMenuWidget extends ConsumerWidget {
  const MainMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Quick start options
          _buildQuickStartOptions(context, ref),
        ],
      ),
    );
  }

  Widget _buildQuickStartOptions(BuildContext context, WidgetRef ref) {
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
                    () => _startRandomQuiz(ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStartButton(
                    'Аз сура',
                    Icons.book,
                    Colors.green,
                    () => _showSurahSelection(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildQuickStartButton(
                'Такрорӣ',
                Icons.refresh,
                Colors.orange,
                () => _startReviewQuiz(ref),
              ),
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
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }


  // Event handlers
  Future<void> _startRandomQuiz(WidgetRef ref) async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: userId,
        mode: QuizMode.random,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await _loadQuestionsForSession(ref, session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      print('Error starting random quiz: $e');
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  void _showSurahSelection(BuildContext context, WidgetRef ref) {
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
                  _startSurahQuiz(ref, surahNumber);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startSurahQuiz(WidgetRef ref, int surahNumber) async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: userId,
        mode: QuizMode.surah,
        surahNumber: surahNumber,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await _loadQuestionsForSession(ref, session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      print('Error starting surah quiz: $e');
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  Future<void> _startReviewQuiz(WidgetRef ref) async {
    ref.read(quizStateProvider.notifier).state = QuizState.loading;
    
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      final mechanicsService = ref.read(quizMechanicsServiceProvider);
      final session = await mechanicsService.createQuizSession(
        userId: userId,
        mode: QuizMode.review,
        wordCount: 10,
      );
      
      ref.read(currentQuizSessionProvider.notifier).state = session;
      await _loadQuestionsForSession(ref, session);
      
      ref.read(quizStateProvider.notifier).state = QuizState.playing;
    } catch (e) {
      print('Error starting review quiz: $e');
      ref.read(quizStateProvider.notifier).state = QuizState.error;
    }
  }

  Future<void> _loadQuestionsForSession(WidgetRef ref, QuizSessionModel session) async {
    final mechanicsService = ref.read(quizMechanicsServiceProvider);
    final questions = await mechanicsService.generateQuestionsForSession(session);
    
    ref.read(currentQuizQuestionsProvider.notifier).state = questions;
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
  }

}
