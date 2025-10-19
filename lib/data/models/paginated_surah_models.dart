import 'package:equatable/equatable.dart';
import 'verse_model.dart';

class PaginatedSurahVerse extends Equatable {
  final VerseModel verse;
  final int pageNumber;
  final int juz;

  const PaginatedSurahVerse({
    required this.verse,
    required this.pageNumber,
    required this.juz,
  });

  @override
  List<Object?> get props => [verse, pageNumber, juz];
}

class SurahPage extends Equatable {
  final int pageNumber;
  final int surahNumber;
  final List<PaginatedSurahVerse> verses;
  final int juz;
  final bool isFirstPageOfSurah;
  final bool isLastPageOfSurah;

  const SurahPage({
    required this.pageNumber,
    required this.surahNumber,
    required this.verses,
    required this.juz,
    this.isFirstPageOfSurah = false,
    this.isLastPageOfSurah = false,
  });

  bool get hasVerses => verses.isNotEmpty;

  @override
  List<Object?> get props => [
        pageNumber,
        surahNumber,
        verses,
        juz,
        isFirstPageOfSurah,
        isLastPageOfSurah,
      ];
}

class PaginatedSurahData extends Equatable {
  final int surahNumber;
  final List<SurahPage> pages;
  final int firstPageNumber;
  final int lastPageNumber;
  final int totalPages;

  const PaginatedSurahData({
    required this.surahNumber,
    required this.pages,
    required this.firstPageNumber,
    required this.lastPageNumber,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [
        surahNumber,
        pages,
        firstPageNumber,
        lastPageNumber,
        totalPages,
      ];
}
