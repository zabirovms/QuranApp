import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/paginated_surah_models.dart';
import '../models/verse_model.dart';

class PaginatedSurahRepository {
  static const String _jsonPath = 'assets/data/alquran_cloud_complete_quran.json';
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json';
  
  final Map<int, PaginatedSurahData> _surahCache = {};
  final Map<String, SurahPage> _pageCache = {};

  Future<PaginatedSurahData> getSurahPaginatedData(int surahNumber) async {
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    final mushafJsonString = await rootBundle.loadString(_jsonPath);
    final mushafData = json.decode(mushafJsonString) as Map<String, dynamic>;
    final dataSection = mushafData['data'] as Map<String, dynamic>;
    final surahsList = dataSection['surahs'] as List<dynamic>;

    final versesJsonString = await rootBundle.loadString(_translationsJsonPath);
    final versesData = json.decode(versesJsonString) as Map<String, dynamic>;
    final translationsData = versesData['data'] as Map<String, dynamic>;
    final surahKey = surahNumber.toString();

    if (surahNumber < 1 || surahNumber > surahsList.length) {
      throw Exception('Invalid surah number: $surahNumber');
    }

    final surahJson = surahsList[surahNumber - 1] as Map<String, dynamic>;
    final ayahsList = surahJson['ayahs'] as List<dynamic>;

    final surahTranslations = translationsData.containsKey(surahKey)
        ? (translationsData[surahKey] as Map<String, dynamic>)['ayahs'] as List
        : [];

    final Map<int, SurahPage> pageMap = {};

    for (final ayahJson in ayahsList) {
      final ayahData = ayahJson as Map<String, dynamic>;
      final verseNumber = ayahData['numberInSurah'] as int;
      final pageNumber = ayahData['page'] as int;
      final juz = ayahData['juz'] as int;

      final translationData = surahTranslations.firstWhere(
        (v) => v['number'] == verseNumber,
        orElse: () => null,
      );

      final verse = VerseModel(
        id: ayahData['number'] as int,
        surahId: surahNumber,
        verseNumber: verseNumber,
        arabicText: (ayahData['text'] as String).trim(),
        tajikText: translationData?['tajik_text'] as String? ?? '',
        transliteration: translationData?['transliteration'] as String?,
        tafsir: translationData?['tafsir'] as String?,
        page: pageNumber,
        juz: juz,
        uniqueKey: '$surahNumber:$verseNumber',
      );

      if (!pageMap.containsKey(pageNumber)) {
        pageMap[pageNumber] = SurahPage(
          pageNumber: pageNumber,
          surahNumber: surahNumber,
          verses: [],
          juz: juz,
        );
      }

      pageMap[pageNumber]!.verses.add(
        PaginatedSurahVerse(
          verse: verse,
          pageNumber: pageNumber,
          juz: juz,
        ),
      );
    }

    final sortedPages = pageMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final pages = sortedPages.map((entry) {
      final isFirst = entry.key == sortedPages.first.key;
      final isLast = entry.key == sortedPages.last.key;
      
      return SurahPage(
        pageNumber: entry.value.pageNumber,
        surahNumber: entry.value.surahNumber,
        verses: entry.value.verses,
        juz: entry.value.juz,
        isFirstPageOfSurah: isFirst,
        isLastPageOfSurah: isLast,
      );
    }).toList();

    final paginatedData = PaginatedSurahData(
      surahNumber: surahNumber,
      pages: pages,
      firstPageNumber: pages.first.pageNumber,
      lastPageNumber: pages.last.pageNumber,
      totalPages: pages.length,
    );

    _surahCache[surahNumber] = paginatedData;
    return paginatedData;
  }

  Future<SurahPage> getSurahPage(int surahNumber, int pageNumber) async {
    final cacheKey = '$surahNumber:$pageNumber';
    
    if (_pageCache.containsKey(cacheKey)) {
      return _pageCache[cacheKey]!;
    }

    final data = await getSurahPaginatedData(surahNumber);
    final page = data.pages.firstWhere(
      (p) => p.pageNumber == pageNumber,
      orElse: () => throw Exception('Page $pageNumber not found in surah $surahNumber'),
    );

    _pageCache[cacheKey] = page;
    return page;
  }

  Future<int> getPageNumberForVerse(int surahNumber, int verseNumber) async {
    final data = await getSurahPaginatedData(surahNumber);
    
    for (final page in data.pages) {
      for (final paginatedVerse in page.verses) {
        if (paginatedVerse.verse.verseNumber == verseNumber) {
          return page.pageNumber;
        }
      }
    }

    return data.firstPageNumber;
  }

  void clearCache() {
    _surahCache.clear();
    _pageCache.clear();
  }
}
