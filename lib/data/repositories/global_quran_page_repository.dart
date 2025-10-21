import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse_model.dart';
import '../models/surah_model.dart';

class GlobalQuranPageRepository {
  static const String _mushafJsonPath = 'assets/data/alquran_cloud_complete_quran.json';
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json';
  
  final Map<int, QuranPage> _pageCache = {};
  final Map<int, int> _surahFirstPageCache = {};
  List<SurahModel>? _allSurahs;

  Future<QuranPage> getPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    final mushafJsonString = await rootBundle.loadString(_mushafJsonPath);
    final mushafData = json.decode(mushafJsonString) as Map<String, dynamic>;
    final dataSection = mushafData['data'] as Map<String, dynamic>;
    final mushafSurahsList = dataSection['surahs'] as List<dynamic>;

    final versesJsonString = await rootBundle.loadString(_translationsJsonPath);
    final versesData = json.decode(versesJsonString) as Map<String, dynamic>;
    final translationsData = versesData['data'] as Map<String, dynamic>;
    final translationSurahsList = translationsData['surahs'] as List<dynamic>;

    final verses = <VerseModel>[];
    final surahsOnPage = <int>{};
    int juz = 1;

    for (final translationSurahJson in translationSurahsList) {
      final translationSurahData = translationSurahJson as Map<String, dynamic>;
      final surahNumber = translationSurahData['number'] as int;
      final translationAyahsList = translationSurahData['ayahs'] as List<dynamic>;

      for (final translationAyahJson in translationAyahsList) {
        final translationAyahData = translationAyahJson as Map<String, dynamic>;
        final verseNumber = translationAyahData['number'] as int;
        
        // Find the corresponding verse in the mushaf data
        final mushafSurahData = mushafSurahsList.firstWhere(
          (s) => (s as Map<String, dynamic>)['number'] == surahNumber,
        ) as Map<String, dynamic>;
        final mushafAyahs = mushafSurahData['ayahs'] as List<dynamic>;
        
        final mushafAyah = mushafAyahs.firstWhere(
          (a) => (a as Map<String, dynamic>)['numberInSurah'] == verseNumber,
        ) as Map<String, dynamic>;
        
        final ayahPage = mushafAyah['page'] as int;

        if (ayahPage == pageNumber) {
          final verse = VerseModel(
            id: mushafAyah['number'] as int,
            surahId: surahNumber,
            verseNumber: verseNumber,
            arabicText: (mushafAyah['text'] as String).trim(),
            tajikText: translationAyahData['tajik_text'] as String? ?? '',
            transliteration: translationAyahData['transliteration'] as String?,
            tafsir: translationAyahData['tafsir'] as String?,
            page: ayahPage,
            juz: mushafAyah['juz'] as int,
            uniqueKey: '$surahNumber:$verseNumber',
          );

          verses.add(verse);
          surahsOnPage.add(surahNumber);
          juz = mushafAyah['juz'] as int;
        }
      }
    }

    verses.sort((a, b) {
      final surahCompare = a.surahId.compareTo(b.surahId);
      if (surahCompare != 0) return surahCompare;
      return a.verseNumber.compareTo(b.verseNumber);
    });

    final page = QuranPage(
      pageNumber: pageNumber,
      verses: verses,
      surahsOnPage: surahsOnPage.toList()..sort(),
      juz: juz,
    );

    _pageCache[pageNumber] = page;
    return page;
  }

  Future<int> getFirstPageOfSurah(int surahNumber) async {
    if (_surahFirstPageCache.containsKey(surahNumber)) {
      return _surahFirstPageCache[surahNumber]!;
    }

    final mushafJsonString = await rootBundle.loadString(_mushafJsonPath);
    final mushafData = json.decode(mushafJsonString) as Map<String, dynamic>;
    final dataSection = mushafData['data'] as Map<String, dynamic>;
    final mushafSurahsList = dataSection['surahs'] as List<dynamic>;

    if (surahNumber < 1 || surahNumber > mushafSurahsList.length) {
      return 1;
    }

    final surahData = mushafSurahsList[surahNumber - 1] as Map<String, dynamic>;
    final ayahsList = surahData['ayahs'] as List<dynamic>;

    if (ayahsList.isEmpty) {
      return 1;
    }

    final firstAyah = ayahsList[0] as Map<String, dynamic>;
    final firstPage = firstAyah['page'] as int;

    _surahFirstPageCache[surahNumber] = firstPage;
    return firstPage;
  }

  Future<SurahModel?> getSurahInfo(int surahNumber) async {
    if (_allSurahs == null) {
      await _loadAllSurahs();
    }

    if (surahNumber < 1 || surahNumber > _allSurahs!.length) {
      return null;
    }

    return _allSurahs![surahNumber - 1];
  }

  Future<void> _loadAllSurahs() async {
    final mushafJsonString = await rootBundle.loadString(_mushafJsonPath);
    final mushafData = json.decode(mushafJsonString) as Map<String, dynamic>;
    final dataSection = mushafData['data'] as Map<String, dynamic>;
    final mushafSurahsList = dataSection['surahs'] as List<dynamic>;

    _allSurahs = mushafSurahsList.map((surahJson) {
      final surahData = surahJson as Map<String, dynamic>;
      final ayahsList = surahData['ayahs'] as List<dynamic>;
      
      return SurahModel(
        id: surahData['number'] as int,          // <-- required
        number: surahData['number'] as int,
        nameArabic: surahData['name'] as String,
        nameTajik: surahData['name_tajik'] as String,
        nameEnglish: surahData['name'] as String,
        revelationType: surahData['revelationType'] as String,
        versesCount: ayahsList.length,
        description: surahData['description'] as String?,
      );
    }).toList();
  }

  int get totalPages => 604;

  void clearCache() {
    _pageCache.clear();
    _surahFirstPageCache.clear();
    _allSurahs = null;
  }
}

class QuranPage {
  final int pageNumber;
  final List<VerseModel> verses;
  final List<int> surahsOnPage;
  final int juz;

  const QuranPage({
    required this.pageNumber,
    required this.verses,
    required this.surahsOnPage,
    required this.juz,
  });

  bool get hasVerses => verses.isNotEmpty;
  
  bool get hasMultipleSurahs => surahsOnPage.length > 1;
  
  List<int> get surahStartIndices {
    final indices = <int>[];
    for (var i = 0; i < verses.length; i++) {
      if (verses[i].verseNumber == 1) {
        indices.add(i);
      }
    }
    return indices;
  }
}
