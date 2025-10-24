import '../../models/surah_model.dart';
import '../../../core/utils/compressed_json_loader.dart';

class SurahLocalDataSource {
  static const String _surahsJsonPath = 'assets/data/alquran_cloud_complete_quran.json.gz';
  
  /// Load all surahs from local compressed JSON file
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      final Map<String, dynamic> jsonData = await CompressedJsonLoader.loadCompressedJsonAsMap(_surahsJsonPath);
      final List<dynamic> surahsJson = jsonData['data']['surahs'];
      
      return surahsJson.map((json) => SurahModel.fromAlQuranCloudJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load surahs from local compressed JSON: $e');
    }
  }
  
  /// Get a specific surah by number from local compressed JSON file
  Future<SurahModel?> getSurahByNumber(int number) async {
    try {
      final surahs = await getAllSurahs();
      for (final surah in surahs) {
        if (surah.number == number) {
          return surah;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load surah $number from local compressed JSON: $e');
    }
  }
}
