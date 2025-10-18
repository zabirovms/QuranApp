import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'surah_model.g.dart';

@JsonSerializable()
class SurahModel extends Equatable {
  final int id;
  final int number;
  @JsonKey(name: 'name_arabic')
  final String nameArabic;
  @JsonKey(name: 'name_tajik')
  final String nameTajik;
  @JsonKey(name: 'name_english')
  final String nameEnglish;
  @JsonKey(name: 'revelation_type')
  final String revelationType;
  @JsonKey(name: 'verses_count')
  final int versesCount;
  final String? description;

  const SurahModel({
    required this.id,
    required this.number,
    required this.nameArabic,
    required this.nameTajik,
    required this.nameEnglish,
    required this.revelationType,
    required this.versesCount,
    this.description,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) =>
      _$SurahModelFromJson(json);

  /// Factory method for AlQuran Cloud JSON format
  factory SurahModel.fromAlQuranCloudJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['number'] as int,
      number: json['number'] as int,
      nameArabic: json['name'] as String,
      nameTajik: json['name_tajik'] as String,
      nameEnglish: '', // Not available in new format
      revelationType: json['revelationType'] as String,
      versesCount: (json['ayahs'] as List).length,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$SurahModelToJson(this);

  SurahModel copyWith({
    int? id,
    int? number,
    String? nameArabic,
    String? nameTajik,
    String? nameEnglish,
    String? revelationType,
    int? versesCount,
    String? description,
  }) {
    return SurahModel(
      id: id ?? this.id,
      number: number ?? this.number,
      nameArabic: nameArabic ?? this.nameArabic,
      nameTajik: nameTajik ?? this.nameTajik,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      revelationType: revelationType ?? this.revelationType,
      versesCount: versesCount ?? this.versesCount,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        id,
        number,
        nameArabic,
        nameTajik,
        nameEnglish,
        revelationType,
        versesCount,
        description,
      ];

  @override
  String toString() {
    return 'SurahModel(id: $id, number: $number, nameArabic: $nameArabic, nameTajik: $nameTajik, nameEnglish: $nameEnglish, revelationType: $revelationType, versesCount: $versesCount, description: $description)';
  }
}
