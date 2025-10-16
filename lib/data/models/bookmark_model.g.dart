// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkModel _$BookmarkModelFromJson(Map<String, dynamic> json) =>
    BookmarkModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      verseId: (json['verse_id'] as num).toInt(),
      verseKey: json['verse_key'] as String,
      surahNumber: (json['surah_number'] as num).toInt(),
      verseNumber: (json['verse_number'] as num).toInt(),
      arabicText: json['arabic_text'] as String,
      tajikText: json['tajik_text'] as String,
      surahName: json['surah_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BookmarkModelToJson(BookmarkModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'verse_id': instance.verseId,
      'verse_key': instance.verseKey,
      'surah_number': instance.surahNumber,
      'verse_number': instance.verseNumber,
      'arabic_text': instance.arabicText,
      'tajik_text': instance.tajikText,
      'surah_name': instance.surahName,
      'created_at': instance.createdAt.toIso8601String(),
    };
