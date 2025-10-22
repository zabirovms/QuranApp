import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quiz_session_model.g.dart';

/// Model for tracking quiz sessions and progress
@JsonSerializable()
class QuizSessionModel extends Equatable {
  final String id;
  final String userId;
  final List<String> questionIds;
  final List<QuizAnswerModel> answers;
  final int score;
  final int totalQuestions;
  final DateTime startedAt;
  final DateTime? completedAt;
  final QuizMode mode;
  final int? surahNumber;
  final int? dailyWordCount;

  const QuizSessionModel({
    required this.id,
    required this.userId,
    required this.questionIds,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.startedAt,
    this.completedAt,
    required this.mode,
    this.surahNumber,
    this.dailyWordCount,
  });

  factory QuizSessionModel.create({
    required String userId,
    required List<String> questionIds,
    required QuizMode mode,
    int? surahNumber,
    int? dailyWordCount,
  }) {
    return QuizSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      questionIds: questionIds,
      answers: [],
      score: 0,
      totalQuestions: questionIds.length,
      startedAt: DateTime.now(),
      mode: mode,
      surahNumber: surahNumber,
      dailyWordCount: dailyWordCount,
    );
  }

  factory QuizSessionModel.fromJson(Map<String, dynamic> json) =>
      _$QuizSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizSessionModelToJson(this);

  QuizSessionModel copyWith({
    String? id,
    String? userId,
    List<String>? questionIds,
    List<QuizAnswerModel>? answers,
    int? score,
    int? totalQuestions,
    DateTime? startedAt,
    DateTime? completedAt,
    QuizMode? mode,
    int? surahNumber,
    int? dailyWordCount,
  }) {
    return QuizSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionIds: questionIds ?? this.questionIds,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      mode: mode ?? this.mode,
      surahNumber: surahNumber ?? this.surahNumber,
      dailyWordCount: dailyWordCount ?? this.dailyWordCount,
    );
  }

  bool get isCompleted => completedAt != null;
  double get progress => answers.length / totalQuestions;
  double get accuracy => totalQuestions > 0 ? score / totalQuestions : 0.0;
  Duration get duration => (completedAt ?? DateTime.now()).difference(startedAt);

  @override
  List<Object?> get props => [
        id,
        userId,
        questionIds,
        answers,
        score,
        totalQuestions,
        startedAt,
        completedAt,
        mode,
        surahNumber,
        dailyWordCount,
      ];
}

/// Model for individual quiz answers
@JsonSerializable()
class QuizAnswerModel extends Equatable {
  final String questionId;
  final int selectedOptionIndex;
  final bool isCorrect;
  final DateTime answeredAt;
  final Duration timeToAnswer;

  const QuizAnswerModel({
    required this.questionId,
    required this.selectedOptionIndex,
    required this.isCorrect,
    required this.answeredAt,
    required this.timeToAnswer,
  });

  factory QuizAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAnswerModelToJson(this);

  @override
  List<Object?> get props => [
        questionId,
        selectedOptionIndex,
        isCorrect,
        answeredAt,
        timeToAnswer,
      ];
}

/// Quiz modes
enum QuizMode {
  @JsonValue('random')
  random,
  @JsonValue('surah')
  surah,
  @JsonValue('daily')
  daily,
  @JsonValue('review')
  review,
}
