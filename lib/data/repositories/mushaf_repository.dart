import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mushaf_models.dart';

class MushafRepository {
  static const String _jsonPath = 'assets/data/alquran_cloud_complete_quran.json';
  
  MushafData? _cachedData;
  final Map<int, MushafPage> _pageCache = {};

  Future<MushafData> loadMushafData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    final jsonString = await rootBundle.loadString(_jsonPath);
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final dataSection = jsonData['data'] as Map<String, dynamic>;
    final surahsList = dataSection['surahs'] as List<dynamic>;

    final surahs = <MushafSurah>[];
    
    for (final surahJson in surahsList) {
      final surahData = surahJson as Map<String, dynamic>;
      final surahNumber = surahData['number'] as int;
      final nameArabic = surahData['name'] as String;
      final nameTajik = surahData['name_tajik'] as String;
      final revelationType = surahData['revelationType'] as String;
      final description = surahData['description'] as String?;
      final ayahsList = surahData['ayahs'] as List<dynamic>;

      final verses = <MushafVerse>[];
      
      for (final ayahJson in ayahsList) {
        final ayahData = ayahJson as Map<String, dynamic>;
        
        final verse = MushafVerse(
          number: ayahData['number'] as int,
          numberInSurah: ayahData['numberInSurah'] as int,
          surahNumber: surahNumber,
          surahName: nameArabic,
          arabicText: (ayahData['text'] as String).trim(),
          page: ayahData['page'] as int,
          juz: ayahData['juz'] as int,
          ruku: ayahData['ruku'] as int?,
          hizbQuarter: ayahData['hizbQuarter'] as int?,
          sajda: ayahData['sajda'] is bool 
              ? ayahData['sajda'] as bool 
              : false,
        );
        
        verses.add(verse);
      }

      surahs.add(MushafSurah(
        number: surahNumber,
        nameArabic: nameArabic,
        nameTajik: nameTajik,
        revelationType: revelationType,
        description: description,
        verses: verses,
      ));
    }

    _cachedData = MushafData(
      surahs: surahs,
      pageCache: {},
    );

    return _cachedData!;
  }

  Future<MushafPage> getPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    final data = await loadMushafData();
    final verses = <MushafVerse>[];
    final surahsOnPage = <int>{};

    for (final surah in data.surahs) {
      for (final verse in surah.verses) {
        if (verse.page == pageNumber) {
          verses.add(verse);
          surahsOnPage.add(verse.surahNumber);
        }
      }
    }

    verses.sort((a, b) {
      final surahCompare = a.surahNumber.compareTo(b.surahNumber);
      if (surahCompare != 0) return surahCompare;
      return a.numberInSurah.compareTo(b.numberInSurah);
    });

    final page = MushafPage(
      pageNumber: pageNumber,
      verses: verses,
      surahsOnPage: surahsOnPage.toList()..sort(),
      juz: verses.isNotEmpty ? verses.first.juz : 1,
    );

    _pageCache[pageNumber] = page;
    return page;
  }

  Future<List<MushafPage>> getPageRange(int startPage, int endPage) async {
    final pages = <MushafPage>[];
    for (int i = startPage; i <= endPage; i++) {
      pages.add(await getPage(i));
    }
    return pages;
  }

  Future<int> getPageForVerse(int surahNumber, int verseNumber) async {
    final data = await loadMushafData();
    
    if (surahNumber < 1 || surahNumber > data.surahs.length) {
      return 1;
    }

    final surah = data.surahs[surahNumber - 1];
    if (verseNumber < 1 || verseNumber > surah.verses.length) {
      return surah.verses.first.page;
    }

    return surah.verses[verseNumber - 1].page;
  }

  int get totalPages => 604;

  void clearCache() {
    _pageCache.clear();
  }
}
