import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'word_analysis_model.g.dart';

@JsonSerializable()
class WordAnalysisModel extends Equatable {
  final int id;
  @JsonKey(name: 'verse_id')
  final int verseId;
  @JsonKey(name: 'word_position')
  final int wordPosition;
  @JsonKey(name: 'word_text')
  final String wordText;
  final String? translation;
  final String? transliteration;
  final String? root;
  @JsonKey(name: 'part_of_speech')
  final String? partOfSpeech;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const WordAnalysisModel({
    required this.id,
    required this.verseId,
    required this.wordPosition,
    required this.wordText,
    this.translation,
    this.transliteration,
    this.root,
    this.partOfSpeech,
    this.createdAt,
  });

  factory WordAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$WordAnalysisModelFromJson(json);

  Map<String, dynamic> toJson() => _$WordAnalysisModelToJson(this);

  WordAnalysisModel copyWith({
    int? id,
    int? verseId,
    int? wordPosition,
    String? wordText,
    String? translation,
    String? transliteration,
    String? root,
    String? partOfSpeech,
    DateTime? createdAt,
  }) {
    return WordAnalysisModel(
      id: id ?? this.id,
      verseId: verseId ?? this.verseId,
      wordPosition: wordPosition ?? this.wordPosition,
      wordText: wordText ?? this.wordText,
      translation: translation ?? this.translation,
      transliteration: transliteration ?? this.transliteration,
      root: root ?? this.root,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        verseId,
        wordPosition,
        wordText,
        translation,
        transliteration,
        root,
        partOfSpeech,
        createdAt,
      ];

  @override
  String toString() {
    return 'WordAnalysisModel(id: $id, verseId: $verseId, wordPosition: $wordPosition, wordText: $wordText, translation: $translation, transliteration: $transliteration, root: $root, partOfSpeech: $partOfSpeech, createdAt: $createdAt)';
  }
}
