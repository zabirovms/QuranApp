import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'asmaul_husna_model.g.dart';

@JsonSerializable()
class AsmaulHusnaModel extends Equatable {
  final String name; // Arabic name
  final int number;
  final String found; // Quranic references
  final TajikInfo tajik;

  const AsmaulHusnaModel({
    required this.name,
    required this.number,
    required this.found,
    required this.tajik,
  });

  factory AsmaulHusnaModel.fromJson(Map<String, dynamic> json) =>
      _$AsmaulHusnaModelFromJson(json);

  Map<String, dynamic> toJson() => _$AsmaulHusnaModelToJson(this);

  @override
  List<Object?> get props => [name, number, found, tajik];

  @override
  String toString() {
    return 'AsmaulHusnaModel(name: $name, number: $number, found: $found, tajik: $tajik)';
  }
}

@JsonSerializable()
class TajikInfo extends Equatable {
  final String transliteration;
  final String meaning;

  const TajikInfo({
    required this.transliteration,
    required this.meaning,
  });

  factory TajikInfo.fromJson(Map<String, dynamic> json) =>
      _$TajikInfoFromJson(json);

  Map<String, dynamic> toJson() => _$TajikInfoToJson(this);

  @override
  List<Object?> get props => [transliteration, meaning];
}

