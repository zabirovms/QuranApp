// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prophet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProphetModel _$ProphetModelFromJson(Map<String, dynamic> json) => ProphetModel(
      name: json['name'] as String,
      arabic: json['arabic'] as String,
      references: (json['references'] as List<dynamic>?)
          ?.map(
              (e) => ProphetReferenceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProphetModelToJson(ProphetModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'arabic': instance.arabic,
      'references': instance.references,
    };
