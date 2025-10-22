// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizQuestionModel _$QuizQuestionModelFromJson(Map<String, dynamic> json) =>
    QuizQuestionModel(
      id: json['id'] as String,
      arabicWord: json['arabicWord'] as String,
      correctTranslation: json['correctTranslation'] as String,
      transliteration: json['transliteration'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctOptionIndex: (json['correctOptionIndex'] as num).toInt(),
      surahReference: json['surahReference'] as String,
      verseNumber: (json['verseNumber'] as num).toInt(),
      wordNumber: (json['wordNumber'] as num).toInt(),
      uniqueKey: json['uniqueKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$QuizQuestionModelToJson(QuizQuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'arabicWord': instance.arabicWord,
      'correctTranslation': instance.correctTranslation,
      'transliteration': instance.transliteration,
      'options': instance.options,
      'correctOptionIndex': instance.correctOptionIndex,
      'surahReference': instance.surahReference,
      'verseNumber': instance.verseNumber,
      'wordNumber': instance.wordNumber,
      'uniqueKey': instance.uniqueKey,
      'createdAt': instance.createdAt.toIso8601String(),
    };
