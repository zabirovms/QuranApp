import '../../models/verse_model.dart';
import '../../../core/utils/compressed_json_loader.dart';

class VerseLocalDataSource {
  static const String _arabicJsonPath = 'assets/data/alquran_cloud_complete_quran.json.gz';
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json.gz';
  
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      // Load Arabic text from compressed file
      final Map<String, dynamic> arabicData = await CompressedJsonLoader.loadCompressedJsonAsMap(_arabicJsonPath);
      
      // Load translations from compressed file
      final Map<String, dynamic> translationsData = await CompressedJsonLoader.loadCompressedJsonAsMap(_translationsJsonPath);
      
      // Get Arabic verses
      final List<dynamic> arabicSurahs = arabicData['data']['surahs'];
      final arabicSurahData = arabicSurahs.firstWhere(
        (surah) => surah['number'] == surahNumber,
        orElse: () => null,
      );
      
      // Get translation verses
      final List<dynamic> translationSurahs = translationsData['data']['surahs'];
      final translationSurahData = translationSurahs.firstWhere(
        (surah) => surah['number'] == surahNumber,
        orElse: () => null,
      );
      
      if (arabicSurahData == null || translationSurahData == null) {
        return [];
      }
      
      final List<dynamic> arabicAyahs = arabicSurahData['ayahs'] as List;
      final List<dynamic> translationAyahs = translationSurahData['ayahs'] as List;
      
      // Create a map of translations by verse number for quick lookup
      final Map<int, Map<String, dynamic>> translationMap = {};
      for (var ayah in translationAyahs) {
        translationMap[ayah['number'] as int] = ayah;
      }
      
      return arabicAyahs.map((arabicAyah) {
        final verseNumber = arabicAyah['numberInSurah'] as int;
        final translation = translationMap[arabicAyah['numberInSurah']];
        
        return VerseModel(
          id: arabicAyah['number'] as int,
          surahId: surahNumber,
          verseNumber: verseNumber,
          arabicText: arabicAyah['text'] as String,
          tajikText: translation?['tajik_text'] as String? ?? '',
          transliteration: translation?['transliteration'] as String? ?? '',
          farsi: null, // Not available in this data source
          russian: null, // Not available in this data source
          tafsir: translation?['tafsir'] as String?,
          page: arabicAyah['page'] as int?,
          juz: arabicAyah['juz'] as int?,
          uniqueKey: '${surahNumber}:${verseNumber}',
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
