import 'package:dio/dio.dart';

/// AlQuran Cloud API client for fetching Arabic text and audio data
class AlQuranCloudApi {
  final Dio _dio;

  AlQuranCloudApi() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.alquran.cloud/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Get Arabic text for a surah
  Future<Response> getSurahArabic({required int surahNumber}) async {
    return await _dio.get('/surah/$surahNumber/quran-uthmani');
  }

  /// Get audio data for a surah
  Future<Response> getSurahAudio({required int surahNumber, required String audioEdition}) async {
    return await _dio.get('/surah/$surahNumber/$audioEdition');
  }

  /// Get combined Arabic text and audio data
  Future<Response> getSurahCombined({required int surahNumber, required String audioEdition}) async {
    return await _dio.get('/surah/$surahNumber/quran-uthmani,$audioEdition');
  }

  /// Get verse audio
  Future<Response> getVerseAudio({required int surahNumber, required int verseNumber, required String audioEdition}) async {
    return await _dio.get('/ayah/$surahNumber:$verseNumber/$audioEdition');
  }
}
