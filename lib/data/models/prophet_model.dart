import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'prophet_reference_model.dart';

part 'prophet_model.g.dart';

@JsonSerializable()
class ProphetModel extends Equatable {
  final String name;
  final String arabic;
  final List<ProphetReferenceModel>? references;

  const ProphetModel({
    required this.name,
    required this.arabic,
    this.references,
  });

  factory ProphetModel.fromJson(Map<String, dynamic> json) =>
      _$ProphetModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProphetModelToJson(this);

  ProphetModel copyWith({
    String? name,
    String? arabic,
    List<ProphetReferenceModel>? references,
  }) {
    return ProphetModel(
      name: name ?? this.name,
      arabic: arabic ?? this.arabic,
      references: references ?? this.references,
    );
  }

  @override
  List<Object?> get props => [name, arabic, references];

  @override
  String toString() {
    return 'ProphetModel(name: $name, arabic: $arabic, references: $references)';
  }
}

