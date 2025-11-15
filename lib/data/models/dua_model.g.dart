// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dua_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuaModel _$DuaModelFromJson(Map<String, dynamic> json) => DuaModel(
      surah: (json['surah'] as num).toInt(),
      verse: (json['verse'] as num).toInt(),
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      tajik: json['tajik'] as String,
      reference: json['reference'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      isFavorite: json['isFavorite'] as bool?,
      prophet: json['prophet'] as String?,
      prophetArabic: json['prophet_arabic'] as String?,
    );

Map<String, dynamic> _$DuaModelToJson(DuaModel instance) => <String, dynamic>{
      'surah': instance.surah,
      'verse': instance.verse,
      'arabic': instance.arabic,
      'transliteration': instance.transliteration,
      'tajik': instance.tajik,
      'reference': instance.reference,
      'category': instance.category,
      'description': instance.description,
      'isFavorite': instance.isFavorite,
      'prophet': instance.prophet,
      'prophet_arabic': instance.prophetArabic,
    };
