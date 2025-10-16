// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerseModel _$VerseModelFromJson(Map<String, dynamic> json) => VerseModel(
      id: (json['id'] as num).toInt(),
      surahId: (json['surah_id'] as num).toInt(),
      verseNumber: (json['verse_number'] as num).toInt(),
      arabicText: json['arabic_text'] as String,
      tajikText: json['tajik_text'] as String,
      transliteration: json['transliteration'] as String?,
      tafsir: json['tafsir'] as String?,
      tj2: json['tj_2'] as String?,
      tj3: json['tj_3'] as String?,
      farsi: json['farsi'] as String?,
      russian: json['russian'] as String?,
      page: (json['page'] as num?)?.toInt(),
      juz: (json['juz'] as num?)?.toInt(),
      uniqueKey: json['unique_key'] as String,
    );

Map<String, dynamic> _$VerseModelToJson(VerseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'surah_id': instance.surahId,
      'verse_number': instance.verseNumber,
      'arabic_text': instance.arabicText,
      'tajik_text': instance.tajikText,
      'transliteration': instance.transliteration,
      'tafsir': instance.tafsir,
      'tj_2': instance.tj2,
      'tj_3': instance.tj3,
      'farsi': instance.farsi,
      'russian': instance.russian,
      'page': instance.page,
      'juz': instance.juz,
      'unique_key': instance.uniqueKey,
    };
