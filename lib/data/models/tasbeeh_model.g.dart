// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasbeeh_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasbeehModel _$TasbeehModelFromJson(Map<String, dynamic> json) => TasbeehModel(
      arabic: json['arabic'] as String,
      tajikTransliteration: json['tajik_transliteration'] as String,
      tajikTranslation: json['tajik_translation'] as String,
      description: json['description'] as String?,
      targetCount: (json['targetCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TasbeehModelToJson(TasbeehModel instance) =>
    <String, dynamic>{
      'arabic': instance.arabic,
      'tajik_transliteration': instance.tajikTransliteration,
      'tajik_translation': instance.tajikTranslation,
      'description': instance.description,
      'targetCount': instance.targetCount,
    };
