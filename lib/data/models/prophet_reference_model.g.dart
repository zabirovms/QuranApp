// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prophet_reference_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProphetReferenceModel _$ProphetReferenceModelFromJson(
        Map<String, dynamic> json) =>
    ProphetReferenceModel(
      surah: (json['surah'] as num).toInt(),
      verses: (json['verses'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      verseData: (json['verse_data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, VerseData.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ProphetReferenceModelToJson(
        ProphetReferenceModel instance) =>
    <String, dynamic>{
      'surah': instance.surah,
      'verses': instance.verses,
      'verse_data': instance.verseData,
    };

VerseData _$VerseDataFromJson(Map<String, dynamic> json) => VerseData(
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String?,
      tajik: json['tajik'] as String,
    );

Map<String, dynamic> _$VerseDataToJson(VerseData instance) => <String, dynamic>{
      'arabic': instance.arabic,
      'transliteration': instance.transliteration,
      'tajik': instance.tajik,
    };
