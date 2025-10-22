import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'word_by_word_model.dart';

part 'quiz_question_model.g.dart';

/// Model for quiz questions using WBW data
@JsonSerializable()
class QuizQuestionModel extends Equatable {
  final String id;
  final String arabicWord;
  final String correctTranslation;
  final String transliteration;
  final List<String> options;
  final int correctOptionIndex;
  final String surahReference;
  final int verseNumber;
  final int wordNumber;
  final String uniqueKey;
  final DateTime createdAt;

  const QuizQuestionModel({
    required this.id,
    required this.arabicWord,
    required this.correctTranslation,
    required this.transliteration,
    required this.options,
    required this.correctOptionIndex,
    required this.surahReference,
    required this.verseNumber,
    required this.wordNumber,
    required this.uniqueKey,
    required this.createdAt,
  });

  factory QuizQuestionModel.fromWordByWord({
    required WordByWordModel wbw,
    required List<String> wrongOptions,
    required String surahReference,
  }) {
    final allOptions = [wbw.farsi ?? '', ...wrongOptions];
    allOptions.shuffle();
    final correctIndex = allOptions.indexOf(wbw.farsi ?? '');

    return QuizQuestionModel(
      id: '${wbw.uniqueKey}_${wbw.wordNumber}',
      arabicWord: wbw.arabic,
      correctTranslation: wbw.farsi ?? '',
      transliteration: '', // Will be populated from additional data if available
      options: allOptions,
      correctOptionIndex: correctIndex,
      surahReference: surahReference,
      verseNumber: int.parse(wbw.uniqueKey.split(':')[1]),
      wordNumber: wbw.wordNumber,
      uniqueKey: wbw.uniqueKey,
      createdAt: DateTime.now(),
    );
  }

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionModelToJson(this);

  QuizQuestionModel copyWith({
    String? id,
    String? arabicWord,
    String? correctTranslation,
    String? transliteration,
    List<String>? options,
    int? correctOptionIndex,
    String? surahReference,
    int? verseNumber,
    int? wordNumber,
    String? uniqueKey,
    DateTime? createdAt,
  }) {
    return QuizQuestionModel(
      id: id ?? this.id,
      arabicWord: arabicWord ?? this.arabicWord,
      correctTranslation: correctTranslation ?? this.correctTranslation,
      transliteration: transliteration ?? this.transliteration,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      surahReference: surahReference ?? this.surahReference,
      verseNumber: verseNumber ?? this.verseNumber,
      wordNumber: wordNumber ?? this.wordNumber,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        arabicWord,
        correctTranslation,
        transliteration,
        options,
        correctOptionIndex,
        surahReference,
        verseNumber,
        wordNumber,
        uniqueKey,
        createdAt,
      ];
}
