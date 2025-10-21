import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/verse_model.dart';

class VerseLocalDataSource {
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json';
  
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      final String response = await rootBundle.loadString(_translationsJsonPath);
      final Map<String, dynamic> jsonData = json.decode(response);
      final Map<String, dynamic> data = jsonData['data'] as Map<String, dynamic>;
      
      final surahKey = surahNumber.toString();
      if (!data.containsKey(surahKey)) {
        return [];
      }
      
      final surah = data[surahKey] as Map<String, dynamic>;
      final versesList = surah['ayahs'] as List;
      
      return versesList.map((verseJson) {
        return VerseModel(
          id: 0, // Not available in local data
          surahId: surahNumber,
          verseNumber: verseJson['number'] as int,
          arabicText: '', // Not available in translations file
          tajikText: verseJson['tajik_text'] as String? ?? '',
          transliteration: verseJson['transliteration'] as String? ?? '',
          farsi: null, // Not available in local data
          russian: null, // Not available in local data
          tafsir: verseJson['tafsir'] as String?, // Now available in local data
          uniqueKey: '${surahNumber}:${verseJson['number']}',
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load verses for surah $surahNumber from local JSON: $e');
    }
  }

  Future<VerseModel?> getVerseByKey(String uniqueKey) async {
    try {
      final parts = uniqueKey.split(':');
      if (parts.length != 2) return null;
      
      final surahNumber = int.tryParse(parts[0]);
      final verseNumber = int.tryParse(parts[1]);
      
      if (surahNumber == null || verseNumber == null) return null;
      
      final verses = await getVersesBySurah(surahNumber);
      return verses.where((v) => v.verseNumber == verseNumber).firstOrNull;
    } catch (e) {
      throw Exception('Failed to load verse $uniqueKey from local JSON: $e');
    }
  }
}
