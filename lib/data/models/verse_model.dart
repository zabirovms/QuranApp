import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verse_model.g.dart';

@JsonSerializable()
class VerseModel extends Equatable {
  final int id;
  @JsonKey(name: 'surah_id')
  final int surahId;
  @JsonKey(name: 'verse_number')
  final int verseNumber;
  @JsonKey(name: 'arabic_text')
  final String arabicText;
  @JsonKey(name: 'tajik_text')
  final String tajikText;
  final String? transliteration;
  final String? tafsir;
  @JsonKey(name: 'tj_2')
  final String? tj2;
  @JsonKey(name: 'tj_3')
  final String? tj3;
  final String? farsi;
  final String? russian;
  final int? page;
  final int? juz;
  @JsonKey(name: 'unique_key')
  final String uniqueKey;

  const VerseModel({
    required this.id,
    required this.surahId,
    required this.verseNumber,
    required this.arabicText,
    required this.tajikText,
    this.transliteration,
    this.tafsir,
    this.tj2,
    this.tj3,
    this.farsi,
    this.russian,
    this.page,
    this.juz,
    required this.uniqueKey,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) =>
      _$VerseModelFromJson(json);

  Map<String, dynamic> toJson() => _$VerseModelToJson(this);

  VerseModel copyWith({
    int? id,
    int? surahId,
    int? verseNumber,
    String? arabicText,
    String? tajikText,
    String? transliteration,
    String? tafsir,
    String? tj2,
    String? tj3,
    String? farsi,
    String? russian,
    int? page,
    int? juz,
    String? uniqueKey,
  }) {
    return VerseModel(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      tajikText: tajikText ?? this.tajikText,
      transliteration: transliteration ?? this.transliteration,
      tafsir: tafsir ?? this.tafsir,
      tj2: tj2 ?? this.tj2,
      tj3: tj3 ?? this.tj3,
      farsi: farsi ?? this.farsi,
      russian: russian ?? this.russian,
      page: page ?? this.page,
      juz: juz ?? this.juz,
      uniqueKey: uniqueKey ?? this.uniqueKey,
    );
  }

  // Helper method to get translation based on language
  String getTranslation(String language) {
    switch (language) {
      case 'tajik':
        return tajikText;
      case 'tj_2':
        return tj2 ?? tajikText;
      case 'tj_3':
        return tj3 ?? tajikText;
      case 'farsi':
        return farsi ?? tajikText;
      case 'russian':
        return russian ?? tajikText;
      default:
        return tajikText;
    }
  }

  @override
  List<Object?> get props => [
        id,
        surahId,
        verseNumber,
        arabicText,
        tajikText,
        transliteration,
        tafsir,
        tj2,
        tj3,
        farsi,
        russian,
        page,
        juz,
        uniqueKey,
      ];

  @override
  String toString() {
    return 'VerseModel(id: $id, surahId: $surahId, verseNumber: $verseNumber, arabicText: $arabicText, tajikText: $tajikText, transliteration: $transliteration, tafsir: $tafsir, tj2: $tj2, tj3: $tj3, farsi: $farsi, russian: $russian, page: $page, juz: $juz, uniqueKey: $uniqueKey)';
  }
}
