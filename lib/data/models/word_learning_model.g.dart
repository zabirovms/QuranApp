// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_learning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordLearningModel _$WordLearningModelFromJson(Map<String, dynamic> json) =>
    WordLearningModel(
      rank: (json['rank'] as num).toInt(),
      word: json['word'] as String,
      translationTajik: json['translation_tajik'] as String,
      transliterationTajik: json['transliteration_tajik'] as String,
      example: json['example'] as String,
      exampleTransliteration: json['example_transliteration'] as String,
      exampleTranslation: json['example_translation'] as String,
      reference: json['reference'] as String,
      difficulty: (json['difficulty'] as num?)?.toInt(),
      isLearned: json['isLearned'] as bool?,
      timesStudied: (json['timesStudied'] as num?)?.toInt(),
      lastStudied: json['lastStudied'] == null
          ? null
          : DateTime.parse(json['lastStudied'] as String),
    );

Map<String, dynamic> _$WordLearningModelToJson(WordLearningModel instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'word': instance.word,
      'translation_tajik': instance.translationTajik,
      'transliteration_tajik': instance.transliterationTajik,
      'example': instance.example,
      'example_transliteration': instance.exampleTransliteration,
      'example_translation': instance.exampleTranslation,
      'reference': instance.reference,
      'difficulty': instance.difficulty,
      'isLearned': instance.isLearned,
      'timesStudied': instance.timesStudied,
      'lastStudied': instance.lastStudied?.toIso8601String(),
    };
