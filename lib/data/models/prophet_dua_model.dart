import 'package:equatable/equatable.dart';

class ProphetDuaModel extends Equatable {
  final String name;
  final String? arabicName;
  final List<ProphetDuaReference> references;

  const ProphetDuaModel({
    required this.name,
    this.arabicName,
    required this.references,
  });

  @override
  List<Object?> get props => [name, arabicName, references];
}

class ProphetDuaReference extends Equatable {
  final int surah;
  final List<int> verses;

  const ProphetDuaReference({
    required this.surah,
    required this.verses,
  });

  @override
  List<Object?> get props => [surah, verses];
}

