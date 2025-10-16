import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'word_learning_model.g.dart';

@JsonSerializable()
class WordLearningModel extends Equatable {
  final int rank;
  final String word;
  @JsonKey(name: 'translation_tajik')
  final String translationTajik;
  @JsonKey(name: 'transliteration_tajik')
  final String transliterationTajik;
  final String example;
  @JsonKey(name: 'example_transliteration')
  final String exampleTransliteration;
  @JsonKey(name: 'example_translation')
  final String exampleTranslation;
  final String reference;
  final int? difficulty;
  final bool? isLearned;
  final int? timesStudied;
  final DateTime? lastStudied;

  const WordLearningModel({
    required this.rank,
    required this.word,
    required this.translationTajik,
    required this.transliterationTajik,
    required this.example,
    required this.exampleTransliteration,
    required this.exampleTranslation,
    required this.reference,
    this.difficulty,
    this.isLearned,
    this.timesStudied,
    this.lastStudied,
  });

  factory WordLearningModel.fromJson(Map<String, dynamic> json) =>
      _$WordLearningModelFromJson(json);

  Map<String, dynamic> toJson() => _$WordLearningModelToJson(this);

  WordLearningModel copyWith({
    int? rank,
    String? word,
    String? translationTajik,
    String? transliterationTajik,
    String? example,
    String? exampleTransliteration,
    String? exampleTranslation,
    String? reference,
    int? difficulty,
    bool? isLearned,
    int? timesStudied,
    DateTime? lastStudied,
  }) {
    return WordLearningModel(
      rank: rank ?? this.rank,
      word: word ?? this.word,
      translationTajik: translationTajik ?? this.translationTajik,
      transliterationTajik: transliterationTajik ?? this.transliterationTajik,
      example: example ?? this.example,
      exampleTransliteration: exampleTransliteration ?? this.exampleTransliteration,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      reference: reference ?? this.reference,
      difficulty: difficulty ?? this.difficulty,
      isLearned: isLearned ?? this.isLearned,
      timesStudied: timesStudied ?? this.timesStudied,
      lastStudied: lastStudied ?? this.lastStudied,
    );
  }

  @override
  List<Object?> get props => [
        rank,
        word,
        translationTajik,
        transliterationTajik,
        example,
        exampleTransliteration,
        exampleTranslation,
        reference,
        difficulty,
        isLearned,
        timesStudied,
        lastStudied,
      ];

  @override
  String toString() {
    return 'WordLearningModel(rank: $rank, word: $word, translationTajik: $translationTajik, transliterationTajik: $transliterationTajik, example: $example, exampleTransliteration: $exampleTransliteration, exampleTranslation: $exampleTranslation, reference: $reference, difficulty: $difficulty, isLearned: $isLearned, timesStudied: $timesStudied, lastStudied: $lastStudied)';
  }
}
