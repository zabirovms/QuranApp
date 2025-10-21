/// AlQuran Cloud API models for Arabic text and audio data
class AqcAyah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int hizbQuarter;
  final int ruku;
  final int manzil;
  final int page;
  final String? audioUrl;

  AqcAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.hizbQuarter,
    required this.ruku,
    required this.manzil,
    required this.page,
    this.audioUrl,
  });

  factory AqcAyah.fromJson(Map<String, dynamic> json) {
    return AqcAyah(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      hizbQuarter: json['hizbQuarter'] as int,
      ruku: json['ruku'] as int,
      manzil: json['manzil'] as int,
      page: json['page'] as int,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'hizbQuarter': hizbQuarter,
      'ruku': ruku,
      'manzil': manzil,
      'page': page,
      'audioUrl': audioUrl,
    };
  }
}

class SurahEdition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format;
  final String type;
  final String direction;
  final List<AqcAyah> ayahs;
  final String editionIdentifier;

  SurahEdition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.type,
    required this.direction,
    required this.ayahs,
    required this.editionIdentifier,
  });

  factory SurahEdition.fromJson(Map<String, dynamic> json) {
    return SurahEdition(
      identifier: json['identifier'] as String,
      language: json['language'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      format: json['format'] as String,
      type: json['type'] as String,
      direction: json['direction'] as String,
      ayahs: (json['ayahs'] as List)
          .map((ayah) => AqcAyah.fromJson(ayah as Map<String, dynamic>))
          .toList(),
      editionIdentifier: json['editionIdentifier'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'language': language,
      'name': name,
      'englishName': englishName,
      'format': format,
      'type': type,
      'direction': direction,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
      'editionIdentifier': editionIdentifier,
    };
  }
}
