// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_analysis_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordAnalysisModel _$WordAnalysisModelFromJson(Map<String, dynamic> json) =>
    WordAnalysisModel(
      id: (json['id'] as num).toInt(),
      verseId: (json['verse_id'] as num).toInt(),
      wordPosition: (json['word_position'] as num).toInt(),
      wordText: json['word_text'] as String,
      translation: json['translation'] as String?,
      transliteration: json['transliteration'] as String?,
      root: json['root'] as String?,
      partOfSpeech: json['part_of_speech'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WordAnalysisModelToJson(WordAnalysisModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'verse_id': instance.verseId,
      'word_position': instance.wordPosition,
      'word_text': instance.wordText,
      'translation': instance.translation,
      'transliteration': instance.transliteration,
      'root': instance.root,
      'part_of_speech': instance.partOfSpeech,
      'created_at': instance.createdAt?.toIso8601String(),
    };
