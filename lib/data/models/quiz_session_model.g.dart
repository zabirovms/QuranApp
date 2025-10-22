// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizSessionModel _$QuizSessionModelFromJson(Map<String, dynamic> json) =>
    QuizSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questionIds: (json['questionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      answers: (json['answers'] as List<dynamic>)
          .map((e) => QuizAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: (json['score'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      mode: $enumDecode(_$QuizModeEnumMap, json['mode']),
      surahNumber: (json['surahNumber'] as num?)?.toInt(),
      dailyWordCount: (json['dailyWordCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QuizSessionModelToJson(QuizSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'questionIds': instance.questionIds,
      'answers': instance.answers,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'mode': _$QuizModeEnumMap[instance.mode]!,
      'surahNumber': instance.surahNumber,
      'dailyWordCount': instance.dailyWordCount,
    };

const _$QuizModeEnumMap = {
  QuizMode.random: 'random',
  QuizMode.surah: 'surah',
  QuizMode.daily: 'daily',
  QuizMode.review: 'review',
};

QuizAnswerModel _$QuizAnswerModelFromJson(Map<String, dynamic> json) =>
    QuizAnswerModel(
      questionId: json['questionId'] as String,
      selectedOptionIndex: (json['selectedOptionIndex'] as num).toInt(),
      isCorrect: json['isCorrect'] as bool,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      timeToAnswer:
          Duration(microseconds: (json['timeToAnswer'] as num).toInt()),
    );

Map<String, dynamic> _$QuizAnswerModelToJson(QuizAnswerModel instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'selectedOptionIndex': instance.selectedOptionIndex,
      'isCorrect': instance.isCorrect,
      'answeredAt': instance.answeredAt.toIso8601String(),
      'timeToAnswer': instance.timeToAnswer.inMicroseconds,
    };
