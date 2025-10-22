import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_progress_model.g.dart';

/// Model for tracking user's learning progress
@JsonSerializable()
class UserProgressModel extends Equatable {
  final String userId;
  final Map<String, WordProgressModel> wordProgress;
  final Map<String, int> surahProgress;
  final int totalWordsLearned;
  final int totalSessionsCompleted;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastStudyDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProgressModel({
    required this.userId,
    required this.wordProgress,
    required this.surahProgress,
    required this.totalWordsLearned,
    required this.totalSessionsCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastStudyDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProgressModel.create(String userId) {
    final now = DateTime.now();
    return UserProgressModel(
      userId: userId,
      wordProgress: {},
      surahProgress: {},
      totalWordsLearned: 0,
      totalSessionsCompleted: 0,
      currentStreak: 0,
      longestStreak: 0,
      lastStudyDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProgressModel.fromJson(Map<String, dynamic> json) =>
      _$UserProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgressModelToJson(this);

  UserProgressModel copyWith({
    String? userId,
    Map<String, WordProgressModel>? wordProgress,
    Map<String, int>? surahProgress,
    int? totalWordsLearned,
    int? totalSessionsCompleted,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgressModel(
      userId: userId ?? this.userId,
      wordProgress: wordProgress ?? this.wordProgress,
      surahProgress: surahProgress ?? this.surahProgress,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      totalSessionsCompleted: totalSessionsCompleted ?? this.totalSessionsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get progress for a specific word
  WordProgressModel? getWordProgress(String wordId) {
    return wordProgress[wordId];
  }

  /// Check if user has studied today
  bool get hasStudiedToday {
    final today = DateTime.now();
    return lastStudyDate.year == today.year &&
        lastStudyDate.month == today.month &&
        lastStudyDate.day == today.day;
  }

  /// Get words that need review (incorrect answers or not studied recently)
  List<String> getWordsForReview() {
    return wordProgress.entries
        .where((entry) {
          final progress = entry.value;
          return progress.incorrectCount > 0 ||
              progress.lastStudied.isBefore(
                DateTime.now().subtract(const Duration(days: 7)),
              );
        })
        .map((entry) => entry.key)
        .toList();
  }

  @override
  List<Object?> get props => [
        userId,
        wordProgress,
        surahProgress,
        totalWordsLearned,
        totalSessionsCompleted,
        currentStreak,
        longestStreak,
        lastStudyDate,
        createdAt,
        updatedAt,
      ];
}

/// Model for tracking progress of individual words
@JsonSerializable()
class WordProgressModel extends Equatable {
  final String wordId;
  final int correctCount;
  final int incorrectCount;
  final DateTime firstStudied;
  final DateTime lastStudied;
  final bool isMastered;
  final List<DateTime> studyDates;

  const WordProgressModel({
    required this.wordId,
    required this.correctCount,
    required this.incorrectCount,
    required this.firstStudied,
    required this.lastStudied,
    required this.isMastered,
    required this.studyDates,
  });

  factory WordProgressModel.create(String wordId) {
    final now = DateTime.now();
    return WordProgressModel(
      wordId: wordId,
      correctCount: 0,
      incorrectCount: 0,
      firstStudied: now,
      lastStudied: now,
      isMastered: false,
      studyDates: [now],
    );
  }

  factory WordProgressModel.fromJson(Map<String, dynamic> json) =>
      _$WordProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$WordProgressModelToJson(this);

  WordProgressModel copyWith({
    String? wordId,
    int? correctCount,
    int? incorrectCount,
    DateTime? firstStudied,
    DateTime? lastStudied,
    bool? isMastered,
    List<DateTime>? studyDates,
  }) {
    return WordProgressModel(
      wordId: wordId ?? this.wordId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      firstStudied: firstStudied ?? this.firstStudied,
      lastStudied: lastStudied ?? this.lastStudied,
      isMastered: isMastered ?? this.isMastered,
      studyDates: studyDates ?? this.studyDates,
    );
  }

  double get accuracy => (correctCount + incorrectCount) > 0 
      ? correctCount / (correctCount + incorrectCount) 
      : 0.0;

  int get totalAttempts => correctCount + incorrectCount;

  /// Mark word as studied with result
  WordProgressModel markStudied(bool isCorrect) {
    final now = DateTime.now();
    final newStudyDates = List<DateTime>.from(studyDates)..add(now);
    
    return copyWith(
      correctCount: isCorrect ? correctCount + 1 : correctCount,
      incorrectCount: !isCorrect ? incorrectCount + 1 : incorrectCount,
      lastStudied: now,
      studyDates: newStudyDates,
      isMastered: isCorrect && correctCount >= 3 && accuracy >= 0.8,
    );
  }

  @override
  List<Object?> get props => [
        wordId,
        correctCount,
        incorrectCount,
        firstStudied,
        lastStudied,
        isMastered,
        studyDates,
      ];
}
