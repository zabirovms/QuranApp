// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgressModel _$UserProgressModelFromJson(Map<String, dynamic> json) =>
    UserProgressModel(
      userId: json['userId'] as String,
      wordProgress: (json['wordProgress'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, WordProgressModel.fromJson(e as Map<String, dynamic>)),
      ),
      surahProgress: Map<String, int>.from(json['surahProgress'] as Map),
      totalWordsLearned: (json['totalWordsLearned'] as num).toInt(),
      totalSessionsCompleted: (json['totalSessionsCompleted'] as num).toInt(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      lastStudyDate: DateTime.parse(json['lastStudyDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserProgressModelToJson(UserProgressModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'wordProgress': instance.wordProgress,
      'surahProgress': instance.surahProgress,
      'totalWordsLearned': instance.totalWordsLearned,
      'totalSessionsCompleted': instance.totalSessionsCompleted,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'lastStudyDate': instance.lastStudyDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

WordProgressModel _$WordProgressModelFromJson(Map<String, dynamic> json) =>
    WordProgressModel(
      wordId: json['wordId'] as String,
      correctCount: (json['correctCount'] as num).toInt(),
      incorrectCount: (json['incorrectCount'] as num).toInt(),
      firstStudied: DateTime.parse(json['firstStudied'] as String),
      lastStudied: DateTime.parse(json['lastStudied'] as String),
      isMastered: json['isMastered'] as bool,
      studyDates: (json['studyDates'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
    );

Map<String, dynamic> _$WordProgressModelToJson(WordProgressModel instance) =>
    <String, dynamic>{
      'wordId': instance.wordId,
      'correctCount': instance.correctCount,
      'incorrectCount': instance.incorrectCount,
      'firstStudied': instance.firstStudied.toIso8601String(),
      'lastStudied': instance.lastStudied.toIso8601String(),
      'isMastered': instance.isMastered,
      'studyDates':
          instance.studyDates.map((e) => e.toIso8601String()).toList(),
    };
