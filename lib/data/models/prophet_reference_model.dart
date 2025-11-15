import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'prophet_reference_model.g.dart';

@JsonSerializable()
class ProphetReferenceModel extends Equatable {
  final int surah;
  final List<int> verses;
  @JsonKey(name: 'verse_data')
  final Map<String, VerseData>? verseData;

  const ProphetReferenceModel({
    required this.surah,
    required this.verses,
    this.verseData,
  });

  factory ProphetReferenceModel.fromJson(Map<String, dynamic> json) =>
      _$ProphetReferenceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProphetReferenceModelToJson(this);

  @override
  List<Object?> get props => [surah, verses, verseData];
}

@JsonSerializable()
class VerseData extends Equatable {
  final String arabic;
  final String? transliteration;
  @JsonKey(name: 'tajik')
  final String tajik;

  const VerseData({
    required this.arabic,
    this.transliteration,
    required this.tajik,
  });

  factory VerseData.fromJson(Map<String, dynamic> json) =>
      _$VerseDataFromJson(json);

  Map<String, dynamic> toJson() => _$VerseDataToJson(this);

  @override
  List<Object?> get props => [arabic, transliteration, tajik];
}

