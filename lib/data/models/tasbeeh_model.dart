import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tasbeeh_model.g.dart';

@JsonSerializable()
class TasbeehModel extends Equatable {
  final String arabic;
  @JsonKey(name: 'tajik_transliteration')
  final String tajikTransliteration;
  @JsonKey(name: 'tajik_translation')
  final String tajikTranslation;
  final String? description;
  final int? targetCount;

  const TasbeehModel({
    required this.arabic,
    required this.tajikTransliteration,
    required this.tajikTranslation,
    this.description,
    this.targetCount,
  });

  factory TasbeehModel.fromJson(Map<String, dynamic> json) =>
      _$TasbeehModelFromJson(json);

  Map<String, dynamic> toJson() => _$TasbeehModelToJson(this);

  TasbeehModel copyWith({
    String? arabic,
    String? tajikTransliteration,
    String? tajikTranslation,
    String? description,
    int? targetCount,
  }) {
    return TasbeehModel(
      arabic: arabic ?? this.arabic,
      tajikTransliteration: tajikTransliteration ?? this.tajikTransliteration,
      tajikTranslation: tajikTranslation ?? this.tajikTranslation,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
    );
  }

  @override
  List<Object?> get props => [
        arabic,
        tajikTransliteration,
        tajikTranslation,
        description,
        targetCount,
      ];

  @override
  String toString() {
    return 'TasbeehModel(arabic: $arabic, tajikTransliteration: $tajikTransliteration, tajikTranslation: $tajikTranslation, description: $description, targetCount: $targetCount)';
  }
}
