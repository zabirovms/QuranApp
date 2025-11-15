import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dua_model.g.dart';

@JsonSerializable()
class DuaModel extends Equatable {
  final int surah;
  final int verse;
  final String arabic;
  final String transliteration;
  final String tajik;
  final String? reference;
  final String? category;
  final String? description;
  final bool? isFavorite;
  final String? prophet;
  @JsonKey(name: 'prophet_arabic')
  final String? prophetArabic;

  const DuaModel({
    required this.surah,
    required this.verse,
    required this.arabic,
    required this.transliteration,
    required this.tajik,
    this.reference,
    this.category,
    this.description,
    this.isFavorite,
    this.prophet,
    this.prophetArabic,
  });

  factory DuaModel.fromJson(Map<String, dynamic> json) =>
      _$DuaModelFromJson(json);

  Map<String, dynamic> toJson() => _$DuaModelToJson(this);

  DuaModel copyWith({
    int? surah,
    int? verse,
    String? arabic,
    String? transliteration,
    String? tajik,
    String? reference,
    String? category,
    String? description,
    bool? isFavorite,
    String? prophet,
    String? prophetArabic,
  }) {
    return DuaModel(
      surah: surah ?? this.surah,
      verse: verse ?? this.verse,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      tajik: tajik ?? this.tajik,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      prophet: prophet ?? this.prophet,
      prophetArabic: prophetArabic ?? this.prophetArabic,
    );
  }

  @override
  List<Object?> get props => [
        surah,
        verse,
        arabic,
        transliteration,
        tajik,
        reference,
        category,
        description,
        isFavorite,
        prophet,
        prophetArabic,
      ];

  @override
  String toString() {
    return 'DuaModel(surah: $surah, verse: $verse, arabic: $arabic, transliteration: $transliteration, tajik: $tajik, reference: $reference, category: $category, description: $description, isFavorite: $isFavorite)';
  }
}
