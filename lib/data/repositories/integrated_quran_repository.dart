import 'package:dio/dio.dart';

import '../datasources/remote/alquran_cloud_api.dart';
import '../datasources/remote/api_service.dart';
import '../models/alquran_cloud_models.dart';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../models/word_by_word_model.dart';

/// Repository that merges Supabase (translations, tafsir, wbw) with
/// AlQuran Cloud (Arabic text, audio, markers) for the Surah page.
class IntegratedQuranRepository {
  IntegratedQuranRepository({required ApiService apiService, required AlQuranCloudApi aqc})
      : _apiService = apiService,
        _aqc = aqc;

  final ApiService _apiService;
  final AlQuranCloudApi _aqc;

  Future<SurahModel?> getSurahMeta(int surahNumber) async {
    final res = await _apiService.getSurahByNumber(surahNumber);
    final data = res.data;
    if (data == null) return null;
    return SurahModel.fromJson(data);
  }

  Future<List<VerseModel>> getSupabaseVerses(int surahNumber) async {
    final res = await _apiService.getVersesBySurah(surahNumber);
    final list = (res.data as List?) ?? const [];
    return list.map((e) => VerseModel.fromJson(e)).toList();
  }

  Future<Map<String, List<WordByWordModel>>> getWordByWordForSurah(int surahNumber) async {
    final verses = await getSupabaseVerses(surahNumber);
    final keys = verses.map((v) => v.uniqueKey).toList();
    final res = await _apiService.getWordByWordByKeys(keys);
    final list = (res.data as List?) ?? const [];
    final items = list.map((e) => WordByWordModel.fromJson(e)).toList();
    final grouped = <String, List<WordByWordModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.uniqueKey, () => []).add(item);
    }
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.wordNumber.compareTo(b.wordNumber));
    }
    return grouped;
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


