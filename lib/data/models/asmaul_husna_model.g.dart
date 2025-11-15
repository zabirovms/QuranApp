// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asmaul_husna_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsmaulHusnaModel _$AsmaulHusnaModelFromJson(Map<String, dynamic> json) =>
    AsmaulHusnaModel(
      name: json['name'] as String,
      number: (json['number'] as num).toInt(),
      found: json['found'] as String,
      tajik: TajikInfo.fromJson(json['tajik'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AsmaulHusnaModelToJson(AsmaulHusnaModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'number': instance.number,
      'found': instance.found,
      'tajik': instance.tajik,
    };

TajikInfo _$TajikInfoFromJson(Map<String, dynamic> json) => TajikInfo(
      transliteration: json['transliteration'] as String,
      meaning: json['meaning'] as String,
    );

Map<String, dynamic> _$TajikInfoToJson(TajikInfo instance) => <String, dynamic>{
      'transliteration': instance.transliteration,
      'meaning': instance.meaning,
    };
