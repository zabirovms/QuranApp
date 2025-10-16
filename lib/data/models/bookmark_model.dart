import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bookmark_model.g.dart';

@JsonSerializable()
class BookmarkModel extends Equatable {
  final int id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'verse_id')
  final int verseId;
  @JsonKey(name: 'verse_key')
  final String verseKey;
  @JsonKey(name: 'surah_number')
  final int surahNumber;
  @JsonKey(name: 'verse_number')
  final int verseNumber;
  @JsonKey(name: 'arabic_text')
  final String arabicText;
  @JsonKey(name: 'tajik_text')
  final String tajikText;
  @JsonKey(name: 'surah_name')
  final String surahName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const BookmarkModel({
    required this.id,
    required this.userId,
    required this.verseId,
    required this.verseKey,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.tajikText,
    required this.surahName,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkModelToJson(this);

  BookmarkModel copyWith({
    int? id,
    String? userId,
    int? verseId,
    String? verseKey,
    int? surahNumber,
    int? verseNumber,
    String? arabicText,
    String? tajikText,
    String? surahName,
    DateTime? createdAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      verseId: verseId ?? this.verseId,
      verseKey: verseKey ?? this.verseKey,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      tajikText: tajikText ?? this.tajikText,
      surahName: surahName ?? this.surahName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        verseId,
        verseKey,
        surahNumber,
        verseNumber,
        arabicText,
        tajikText,
        surahName,
        createdAt,
      ];

  @override
  String toString() {
    return 'BookmarkModel(id: $id, userId: $userId, verseId: $verseId, verseKey: $verseKey, surahNumber: $surahNumber, verseNumber: $verseNumber, arabicText: $arabicText, tajikText: $tajikText, surahName: $surahName, createdAt: $createdAt)';
  }
}
