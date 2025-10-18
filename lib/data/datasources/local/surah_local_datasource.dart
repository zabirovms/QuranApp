import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/surah_model.dart';

class SurahLocalDataSource {
  static const String _surahsJsonPath = 'assets/data/alquran_cloud_complete_quran.json';
  
  /// Load all surahs from local JSON file
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      final String jsonString = await rootBundle.loadString(_surahsJsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> surahsJson = jsonData['data']['surahs'];
      
      return surahsJson.map((json) => SurahModel.fromAlQuranCloudJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load surahs from local JSON: $e');
    }
  }
  
  /// Get a specific surah by number from local JSON file
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
      throw Exception('Failed to load surah $number from local JSON: $e');
    }
  }
}
