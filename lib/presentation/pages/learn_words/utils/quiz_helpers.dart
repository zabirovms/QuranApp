import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/services/daily_quiz_service.dart' as daily_service;
import '../../../../data/services/progress_tracking_service.dart';
import '../../../../data/models/quiz_session_model.dart';
import '../../../widgets/learning_stats_widget.dart';
import '../../../widgets/quiz_settings_widget.dart';
import '../providers/learn_words_providers.dart';

class QuizHelpers {
  // Cache for learning stats
  static LearningStats? _cachedLearningStats;
  static DateTime? _lastStatsUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get daily quiz stats
  static Future<daily_service.DailyQuizStats> getDailyQuizStats(WidgetRef ref) async {
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      final dailyService = ref.read(dailyQuizServiceProvider);
      return await dailyService.getDailyQuizStats(userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Daily quiz stats loading timed out');
          return daily_service.DailyQuizStats.empty();
        },
      );
    } catch (e) {
      print('Error loading daily quiz stats: $e');
      return daily_service.DailyQuizStats.empty();
    }
  }

  /// Get learning stats with caching
  static Future<LearningStats> getLearningStats(WidgetRef ref) async {
    // Return cached data if it's still fresh
    if (_cachedLearningStats != null && 
        _lastStatsUpdate != null && 
        DateTime.now().difference(_lastStatsUpdate!) < _cacheTimeout) {
      return _cachedLearningStats!;
    }

    try {
      final userId = await ref.read(currentUserIdProvider.future);
      final progressService = ref.read(progressTrackingServiceProvider);
      final stats = await progressService.getLearningStats(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Learning stats loading timed out');
          return LearningStats.empty();
        },
      );
      
      // Cache the result
      _cachedLearningStats = stats;
      _lastStatsUpdate = DateTime.now();
      
      return stats;
    } catch (e) {
      print('Error loading learning stats: $e');
      return _cachedLearningStats ?? LearningStats.empty();
    }
  }

  /// Clear stats cache (call this when user completes a quiz)
  static void clearStatsCache() {
    _cachedLearningStats = null;
    _lastStatsUpdate = null;
  }

  /// Show stats dialog
  static void showStatsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Омори омӯзиш',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FutureBuilder<LearningStats>(
                      future: getLearningStats(ref),
                      builder: (context, snapshot) {
                        // Show cached data immediately if available
                        if (snapshot.connectionState == ConnectionState.waiting && 
                            _cachedLearningStats != null) {
                          return LearningStatsWidget(stats: _cachedLearningStats!);
                        }
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Боргирӣ...'),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        final stats = snapshot.data ?? LearningStats.empty();
                        return LearningStatsWidget(stats: stats);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show settings dialog
  static void showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Танзимоти бозӣ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Mode selection
                        QuizModeSelectorWidget(
                          selectedMode: QuizMode.random,
                          onModeChanged: (mode) {},
                          selectedSurahNumber: null,
                          onSurahChanged: (surah) {},
                        ),
                        const SizedBox(height: 16),
                        // Settings
                        QuizSettingsWidget(
                          wordCount: 10,
                          shuffleOptions: true,
                          showTransliteration: true,
                          onWordCountChanged: (count) {},
                          onShuffleOptionsChanged: (value) {},
                          onShowTransliterationChanged: (value) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show surah selection dialog
  static void showSurahSelection(BuildContext context, WidgetRef ref, Function(int) onSurahSelected) {
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
                  onSurahSelected(surahNumber);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
