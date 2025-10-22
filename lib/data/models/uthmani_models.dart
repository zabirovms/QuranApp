import 'package:equatable/equatable.dart';

/// Model for a word in the Uthmani database
class UthmaniWord extends Equatable {
  final int id;
  final String location;
  final int surah;
  final int ayah;
  final int word;
  final String text;

  const UthmaniWord({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
  });

  factory UthmaniWord.fromMap(Map<String, dynamic> map) {
    return UthmaniWord(
      id: map['id'] as int,
      location: map['location'] as String,
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      word: map['word'] as int,
      text: map['text'] as String,
    );
  }

  @override
  List<Object?> get props => [id, location, surah, ayah, word, text];
}

/// Model for a line in the 15-line Mushaf layout
class MushafLine extends Equatable {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int firstWordId;
  final int lastWordId;
  final int? surahNumber;
  final List<UthmaniWord> words;

  const MushafLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.firstWordId,
    required this.lastWordId,
    this.surahNumber,
    this.words = const [],
  });

  factory MushafLine.fromMap(Map<String, dynamic> map) {
    return MushafLine(
      pageNumber: map['page_number'] as int,
      lineNumber: map['line_number'] as int,
      lineType: map['line_type'] as String,
      isCentered: (map['is_centered'] as int) == 1,
      firstWordId: _parseIntSafely(map['first_word_id']) ?? 0,
      lastWordId: _parseIntSafely(map['last_word_id']) ?? 0,
      surahNumber: _parseIntSafely(map['surah_number']),
    );
  }

  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  /// Get the text content of this line by joining all words
  String get text {
    return words.map((w) => w.text).join(' ');
  }

  /// Check if this line is a Surah name
  bool get isSurahName => lineType == 'surah_name';

  /// Check if this line is Bismillah
  bool get isBismillah => lineType == 'basmallah';

  /// Check if this line is a regular ayah
  bool get isAyah => lineType == 'ayah';

  @override
  List<Object?> get props => [
        pageNumber,
        lineNumber,
        lineType,
        isCentered,
        firstWordId,
        lastWordId,
        surahNumber,
        words,
      ];
}

/// Model for a complete Mushaf page with 15 lines
class MushafPage15Lines extends Equatable {
  final int pageNumber;
  final List<MushafLine> lines;
  final int juz;
  final List<int> surahsOnPage;

  const MushafPage15Lines({
    required this.pageNumber,
    required this.lines,
    required this.juz,
    required this.surahsOnPage,
  });

  /// Get all unique Surah numbers on this page
  List<int> get uniqueSurahs {
    return surahsOnPage.toSet().toList()..sort();
  }

  /// Get the first Surah number on this page
  int? get firstSurah {
    return uniqueSurahs.isNotEmpty ? uniqueSurahs.first : null;
  }

  /// Get the last Surah number on this page
  int? get lastSurah {
    return uniqueSurahs.isNotEmpty ? uniqueSurahs.last : null;
  }

  /// Check if this page starts a new Surah
  bool get hasSurahStart {
    return lines.any((line) => line.isSurahName);
  }

  /// Get all Surah names on this page
  List<String> get surahNames {
    return lines
        .where((line) => line.isSurahName)
        .map((line) => line.text)
        .toList();
  }

  @override
  List<Object?> get props => [pageNumber, lines, juz, surahsOnPage];
}

/// Model for Mushaf database info
class MushafInfo extends Equatable {
  final String name;
  final int numberOfPages;
  final int linesPerPage;
  final String fontName;

  const MushafInfo({
    required this.name,
    required this.numberOfPages,
    required this.linesPerPage,
    required this.fontName,
  });

  factory MushafInfo.fromMap(Map<String, dynamic> map) {
    return MushafInfo(
      name: map['name'] as String,
      numberOfPages: map['number_of_pages'] as int,
      linesPerPage: map['lines_per_page'] as int,
      fontName: map['font_name'] as String,
    );
  }

  @override
  List<Object?> get props => [name, numberOfPages, linesPerPage, fontName];
}
