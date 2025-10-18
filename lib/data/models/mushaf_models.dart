import 'package:equatable/equatable.dart';

class MushafVerse extends Equatable {
  final int number;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String arabicText;
  final int page;
  final int juz;
  final int? ruku;
  final int? hizbQuarter;
  final bool sajda;

  const MushafVerse({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.arabicText,
    required this.page,
    required this.juz,
    this.ruku,
    this.hizbQuarter,
    required this.sajda,
  });

  String get arabicVerseNumber {
    return _toArabicNumerals(numberInSurah);
  }

  static String _toArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join('');
  }

  @override
  List<Object?> get props => [
        number,
        numberInSurah,
        surahNumber,
        surahName,
        arabicText,
        page,
        juz,
        ruku,
        hizbQuarter,
        sajda,
      ];
}

class MushafPage extends Equatable {
  final int pageNumber;
  final List<MushafVerse> verses;
  final List<int> surahsOnPage;
  final int juz;

  const MushafPage({
    required this.pageNumber,
    required this.verses,
    required this.surahsOnPage,
    required this.juz,
  });

  bool get hasSurahStart {
    return verses.any((v) => v.numberInSurah == 1);
  }

  List<int> get surahStartIndices {
    final indices = <int>[];
    for (var i = 0; i < verses.length; i++) {
      if (verses[i].numberInSurah == 1) {
        indices.add(i);
      }
    }
    return indices;
  }

  @override
  List<Object?> get props => [pageNumber, verses, surahsOnPage, juz];
}

class MushafData extends Equatable {
  final List<MushafSurah> surahs;
  final Map<int, MushafPage> pageCache;

  const MushafData({
    required this.surahs,
    required this.pageCache,
  });

  @override
  List<Object?> get props => [surahs, pageCache];
}

class MushafSurah extends Equatable {
  final int number;
  final String nameArabic;
  final String nameTajik;
  final String revelationType;
  final String? description;
  final List<MushafVerse> verses;

  const MushafSurah({
    required this.number,
    required this.nameArabic,
    required this.nameTajik,
    required this.revelationType,
    this.description,
    required this.verses,
  });

  @override
  List<Object?> get props => [
        number,
        nameArabic,
        nameTajik,
        revelationType,
        description,
        verses,
      ];
}
