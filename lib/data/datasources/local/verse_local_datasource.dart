import '../../models/verse_model.dart';
import '../../../core/utils/compressed_json_loader.dart';

class VerseLocalDataSource {
  static const String _arabicJsonPath = 'assets/data/alquran_cloud_complete_quran.json.gz';
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json.gz';
  static const String _russianJsonPath = 'assets/data/quran_ru.json.gz';
  static const String _tj2JsonPath = 'assets/data/quran_tj_2_AbuAlomuddin.json.gz';
  static const String _tj3JsonPath = 'assets/data/quran_tj_3_PioneersTranslationCenter.json.gz';
  static const String _farsiJsonPath = 'assets/data/quran_farsi_Farsi.json.gz';
  
  // Load Farsi translations from JSON file
  Future<Map<int, String>> _loadFarsiTranslations(int surahNumber) async {
    try {
      final Map<String, dynamic> farsiData = await CompressedJsonLoader.loadCompressedJsonAsMap(_farsiJsonPath);
      
      final Map<int, String> farsiMap = {};
      final surahKey = surahNumber.toString();
      if (farsiData.containsKey(surahKey)) {
        final List<dynamic> verses = farsiData[surahKey] as List;
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            farsiMap[verseNum] = text;
          }
        }
      }
      return farsiMap;
    } catch (e) {
      // If Farsi file doesn't exist or fails to load, return empty map
      return {};
    }
  }
  
  // Load tj_2 translations from JSON file
  Future<Map<int, String>> _loadTj2Translations(int surahNumber) async {
    try {
      final Map<String, dynamic> tj2Data = await CompressedJsonLoader.loadCompressedJsonAsMap(_tj2JsonPath);
      
      final Map<int, String> tj2Map = {};
      final surahKey = surahNumber.toString();
      if (tj2Data.containsKey(surahKey)) {
        final List<dynamic> verses = tj2Data[surahKey] as List;
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            tj2Map[verseNum] = text;
          }
        }
      }
      return tj2Map;
    } catch (e) {
      // If tj_2 file doesn't exist or fails to load, return empty map
      return {};
    }
  }
  
  // Load tj_3 translations from JSON file
  Future<Map<int, String>> _loadTj3Translations(int surahNumber) async {
    try {
      final Map<String, dynamic> tj3Data = await CompressedJsonLoader.loadCompressedJsonAsMap(_tj3JsonPath);
      
      final Map<int, String> tj3Map = {};
      final surahKey = surahNumber.toString();
      if (tj3Data.containsKey(surahKey)) {
        final List<dynamic> verses = tj3Data[surahKey] as List;
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            tj3Map[verseNum] = text;
          }
        }
      }
      return tj3Map;
    } catch (e) {
      // If tj_3 file doesn't exist or fails to load, return empty map
      return {};
    }
  }
  
  // Load Russian translations from JSON file
  Future<Map<int, String>> _loadRussianTranslations(int surahNumber) async {
    try {
      final Map<String, dynamic> russianData = await CompressedJsonLoader.loadCompressedJsonAsMap(_russianJsonPath);
      
      final Map<int, String> russianMap = {};
      final surahKey = surahNumber.toString();
      if (russianData.containsKey(surahKey)) {
        final List<dynamic> verses = russianData[surahKey] as List;
        for (var verseData in verses) {
          // The JSON has 'verse' field which is the verse number within the surah (1-indexed)
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            russianMap[verseNum] = text;
          }
        }
      }
      return russianMap;
    } catch (e) {
      // If Russian file doesn't exist or fails to load, return empty map
      // Log error for debugging but don't throw
      print('Error loading Russian translations for surah $surahNumber: $e');
      return {};
    }
  }

  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      // Load Arabic text from compressed file
      final Map<String, dynamic> arabicData = await CompressedJsonLoader.loadCompressedJsonAsMap(_arabicJsonPath);
      
      // Load translations from compressed file
      final Map<String, dynamic> translationsData = await CompressedJsonLoader.loadCompressedJsonAsMap(_translationsJsonPath);
      
      // Load Russian translations
      final Map<int, String> russianTranslations = await _loadRussianTranslations(surahNumber);
      
      // Load tj_2 and tj_3 translations
      final Map<int, String> tj2Translations = await _loadTj2Translations(surahNumber);
      final Map<int, String> tj3Translations = await _loadTj3Translations(surahNumber);
      // Load Farsi translations
      final Map<int, String> farsiTranslations = await _loadFarsiTranslations(surahNumber);
      
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
        
        // Get Russian translation if available
        final russianText = russianTranslations[verseNumber];
        
        // Get tj_2 and tj_3 translations from local files
        final tj2Text = tj2Translations[verseNumber];
        final tj3Text = tj3Translations[verseNumber];
        final farsiText = farsiTranslations[verseNumber];
        
        final verse = VerseModel(
          id: arabicAyah['number'] as int,
          surahId: surahNumber,
          verseNumber: verseNumber,
          arabicText: arabicAyah['text'] as String,
          tajikText: translation?['tajik_text'] as String? ?? '',
          transliteration: translation?['transliteration'] as String? ?? '',
          tj2: tj2Text ?? translation?['tj_2'] as String?,
          tj3: tj3Text ?? translation?['tj_3'] as String?,
          farsi: farsiText ?? translation?['farsi'] as String?,
          russian: russianText ?? translation?['russian'] as String?,
          tafsir: translation?['tafsir'] as String?,
          page: arabicAyah['page'] as int?,
          juz: arabicAyah['juz'] as int?,
          uniqueKey: '${surahNumber}:${verseNumber}',
        );
        
        return verse;
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
