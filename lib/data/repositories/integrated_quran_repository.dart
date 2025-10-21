import 'package:dio/dio.dart';

import '../datasources/remote/alquran_cloud_api.dart';
import '../datasources/local/word_by_word_local_datasource.dart';
import '../datasources/local/verse_local_datasource.dart';
import '../datasources/local/surah_local_datasource.dart';
import '../models/alquran_cloud_models.dart';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../models/word_by_word_model.dart';

/// Repository that merges local data (translations, Arabic text) with
/// AlQuran Cloud (audio only) and local word-by-word data for the Surah page.
class IntegratedQuranRepository {
  IntegratedQuranRepository({
    required AlQuranCloudApi aqc,
    required WordByWordLocalDataSource wordByWordDataSource,
    required VerseLocalDataSource verseDataSource,
    required SurahLocalDataSource surahDataSource,
  }) : _aqc = aqc,
       _wordByWordDataSource = wordByWordDataSource,
       _verseDataSource = verseDataSource,
       _surahDataSource = surahDataSource;

  final AlQuranCloudApi _aqc;
  final WordByWordLocalDataSource _wordByWordDataSource;
  final VerseLocalDataSource _verseDataSource;
  final SurahLocalDataSource _surahDataSource;

  Future<SurahModel?> getSurahMeta(int surahNumber) async {
    return await _surahDataSource.getSurahByNumber(surahNumber);
  }

  Future<List<VerseModel>> getSupabaseVerses(int surahNumber) async {
    return await _verseDataSource.getVersesBySurah(surahNumber);
  }

  Future<Map<String, List<WordByWordModel>>> getWordByWordForSurah(int surahNumber) async {
    try {
      // Use local datasource instead of Supabase API
      return await _wordByWordDataSource.getWordByWordForSurah(surahNumber);
    } catch (e) {
      // Return empty map if local data fails
      return <String, List<WordByWordModel>>{};
    }
  }

  Future<(List<AqcAyah>, List<AqcAyah>)> getArabicAndAudio(int surahNumber, String audioEdition) async {
    try {
      final combined = await _aqc.getSurahCombined(surahNumber: surahNumber, audioEdition: audioEdition);
      final body = combined.data as Map<String, dynamic>;
      final data = body['data'];
      // combined returns a List of two editions (text + audio)
      final editions = (data as List).cast<Map<String, dynamic>>().map(SurahEdition.fromJson).toList();
      editions.sort((a, b) => a.editionIdentifier.compareTo(b.editionIdentifier));
      final textEdition = editions.firstWhere((e) => e.editionIdentifier.contains('quran-uthmani'), orElse: () => editions.first);
      final audioEd = editions.firstWhere((e) => e.editionIdentifier == audioEdition, orElse: () => editions.last);
      return (textEdition.ayahs, audioEd.ayahs);
    } on DioException {
      // Fallback: fetch separately
      final arabicRes = await _aqc.getSurahArabic(surahNumber: surahNumber);
      final audioRes = await _aqc.getSurahAudio(surahNumber: surahNumber, audioEdition: audioEdition);
      final arabicData = (arabicRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final audioData = (audioRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final textEdition = SurahEdition.fromJson(arabicData);
      final audioEditionParsed = SurahEdition.fromJson(audioData);
      return (textEdition.ayahs, audioEditionParsed.ayahs);
    }
  }

}


