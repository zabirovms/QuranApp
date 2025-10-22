import 'package:flutter/material.dart';
import '../../data/models/quiz_session_model.dart';
import '../../data/models/user_progress_model.dart';
import '../../data/services/progress_tracking_service.dart';
import '../../data/services/quiz_data_service.dart';
import '../../data/services/quiz_mechanics_service.dart';

/// Service for managing daily quiz functionality
class DailyQuizService {
  final QuizDataService _dataService;
  final QuizMechanicsService _mechanicsService;
  final ProgressTrackingService _progressService;

  DailyQuizService({
    required QuizDataService dataService,
    required QuizMechanicsService mechanicsService,
    required ProgressTrackingService progressService,
  }) : _dataService = dataService,
       _mechanicsService = mechanicsService,
       _progressService = progressService;

  /// Check if user has completed today's quiz
  Future<bool> hasCompletedTodayQuiz(String userId) async {
    return await _progressService.hasStudiedToday(userId);
  }

  /// Get today's quiz words (mix of new and review)
  Future<List<String>> getTodayQuizWords({
    required String userId,
    int newWordCount = 5,
    int reviewWordCount = 5,
  }) async {
    return await _progressService.getDailyQuizWords(
      userId: userId,
      newWordCount: newWordCount,
      reviewWordCount: reviewWordCount,
    );
  }

  /// Create today's daily quiz session
  Future<QuizSessionModel> createTodayQuiz({
    required String userId,
    int wordCount = 10,
  }) async {
    final dailyWords = await getTodayQuizWords(
      userId: userId,
      newWordCount: wordCount ~/ 2,
      reviewWordCount: wordCount ~/ 2,
    );

    return QuizSessionModel.create(
      userId: userId,
      questionIds: dailyWords,
      mode: QuizMode.daily,
      dailyWordCount: wordCount,
    );
  }

  /// Get daily quiz statistics
  Future<DailyQuizStats> getDailyQuizStats(String userId) async {
    final progress = await _progressService.getUserProgress(userId);
    if (progress == null) return DailyQuizStats.empty();

    final hasStudiedToday = progress.hasStudiedToday;
    final currentStreak = progress.currentStreak;
    final longestStreak = progress.longestStreak;
    final totalSessions = progress.totalSessionsCompleted;

    // Calculate average daily words
    final averageDailyWords = totalSessions > 0 
        ? progress.totalWordsLearned / totalSessions 
        : 0.0;

    return DailyQuizStats(
      hasStudiedToday: hasStudiedToday,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalSessions: totalSessions,
      averageDailyWords: averageDailyWords,
      lastStudyDate: progress.lastStudyDate,
    );
  }

  /// Get streak information
  Future<StreakInfo> getStreakInfo(String userId) async {
    final progress = await _progressService.getUserProgress(userId);
    if (progress == null) return StreakInfo.empty();

    final now = DateTime.now();
    final lastStudy = progress.lastStudyDate;
    final daysSinceLastStudy = now.difference(lastStudy).inDays;

    String streakStatus;
    if (daysSinceLastStudy == 0) {
      streakStatus = 'Шумо имрӯз омӯхтаед!';
    } else if (daysSinceLastStudy == 1) {
      streakStatus = 'Зуҳури худро идома диҳед!';
    } else {
      streakStatus = 'Зуҳур қатъ шуд. Озод оғоз кунед!';
    }

    return StreakInfo(
      currentStreak: progress.currentStreak,
      longestStreak: progress.longestStreak,
      daysSinceLastStudy: daysSinceLastStudy,
      streakStatus: streakStatus,
      lastStudyDate: progress.lastStudyDate,
    );
  }

  /// Get motivational message based on progress
  String getMotivationalMessage(DailyQuizStats stats) {
    if (stats.currentStreak >= 7) {
      return 'Аъло! Шумо як ҳафта мунтазам омӯхтаед!';
    } else if (stats.currentStreak >= 3) {
      return 'Хуб! Зуҳури худро идома диҳед!';
    } else if (stats.hasStudiedToday) {
      return 'Имрӯз хуб омӯхтаед! Фардӣ ҳам идома диҳед!';
    } else {
      return 'Омӯзиши калимаҳоро оғоз кунед!';
    }
  }

  /// Get daily quiz recommendations
  Future<List<String>> getDailyRecommendations(String userId) async {
    final progress = await _progressService.getUserProgress(userId);
    if (progress == null) return [];

    final recommendations = <String>[];

    // Check if user needs to review words
    final reviewWords = progress.getWordsForReview();
    if (reviewWords.isNotEmpty) {
      recommendations.add('${reviewWords.length} калима барои такрор омӯхта лозим аст');
    }

    // Check streak
    if (progress.currentStreak == 0) {
      recommendations.add('Зуҳури нав оғоз кунед');
    } else if (progress.currentStreak >= 3) {
      recommendations.add('Зуҳури ${progress.currentStreak} рӯза идома диҳед!');
    }

    // Check mastery level
    final masteredWords = progress.wordProgress.values
        .where((wp) => wp.isMastered)
        .length;
    if (masteredWords >= 50) {
      recommendations.add('Шумо ${masteredWords} калима омӯхтаед! Аъло!');
    }

    return recommendations;
  }
}

/// Daily quiz statistics
class DailyQuizStats {
  final bool hasStudiedToday;
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final double averageDailyWords;
  final DateTime lastStudyDate;

  const DailyQuizStats({
    required this.hasStudiedToday,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSessions,
    required this.averageDailyWords,
    required this.lastStudyDate,
  });

  factory DailyQuizStats.empty() {
    return DailyQuizStats(
      hasStudiedToday: false,
      currentStreak: 0,
      longestStreak: 0,
      totalSessions: 0,
      averageDailyWords: 0.0,
      lastStudyDate: DateTime.now(),
    );
  }

  String get averageDailyWordsFormatted => 
      averageDailyWords.toStringAsFixed(1);
}

/// Streak information
class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final int daysSinceLastStudy;
  final String streakStatus;
  final DateTime lastStudyDate;

  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.daysSinceLastStudy,
    required this.streakStatus,
    required this.lastStudyDate,
  });

  factory StreakInfo.empty() {
    return StreakInfo(
      currentStreak: 0,
      longestStreak: 0,
      daysSinceLastStudy: 0,
      streakStatus: 'Омӯзишро оғоз кунед',
      lastStudyDate: DateTime.now(),
    );
  }
}

/// Widget for displaying daily quiz information
class DailyQuizWidget extends StatelessWidget {
  final DailyQuizStats stats;
  final StreakInfo streakInfo;
  final List<String> recommendations;
  final String motivationalMessage;
  final VoidCallback? onStartQuiz;
  final bool isLoading;

  const DailyQuizWidget({
    super.key,
    required this.stats,
    required this.streakInfo,
    required this.recommendations,
    required this.motivationalMessage,
    this.onStartQuiz,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 16),
            
            // Motivational message
            _buildMotivationalMessage(context),
            const SizedBox(height: 16),
            
            // Streak information
            _buildStreakInfo(context),
            const SizedBox(height: 16),
            
            // Statistics
            _buildStatistics(context),
            const SizedBox(height: 16),
            
            // Recommendations
            if (recommendations.isNotEmpty) _buildRecommendations(context),
            const SizedBox(height: 16),
            
            // Start quiz button
            _buildStartQuizButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.today,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Бозӣи рӯзона',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (stats.hasStudiedToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Тамом шуд',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMotivationalMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        motivationalMessage,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStreakInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStreakCard(
            context,
            'Зуҳури ҳозира',
            '${streakInfo.currentStreak}',
            Icons.local_fire_department,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStreakCard(
            context,
            'Беҳтарин зуҳур',
            '${streakInfo.longestStreak}',
            Icons.emoji_events,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Омори рӯзона',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Сессияҳо',
                '${stats.totalSessions}',
                Icons.play_circle,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Калимаҳои миёна',
                stats.averageDailyWordsFormatted,
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тавсияҳо',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStartQuizButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onStartQuiz,
        icon: isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(isLoading ? 'Тайёр карда истода...' : 'Бозӣ оғоз кардан'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
