import '../datasources/local/word_by_word_local_datasource.dart';
import '../models/word_by_word_model.dart';

class WordByWordLocalRepository {
  final WordByWordLocalDataSource _dataSource;

  WordByWordLocalRepository({required WordByWordLocalDataSource dataSource})
      : _dataSource = dataSource;

  /// Get word-by-word data for a specific verse
  Future<List<WordByWordModel>> getWordByWordForVerse(int surahNumber, int verseNumber) async {
    return await _dataSource.getWordByWordForVerse(surahNumber, verseNumber);
  }

  /// Get word-by-word data for multiple verses by their unique keys
  Future<Map<String, List<WordByWordModel>>> getWordByWordByKeys(List<String> uniqueKeys) async {
    return await _dataSource.getWordByWordByKeys(uniqueKeys);
  }

  /// Get word-by-word data for an entire surah
  Future<Map<String, List<WordByWordModel>>> getWordByWordForSurah(int surahNumber) async {
    return await _dataSource.getWordByWordForSurah(surahNumber);
  }

  /// Get all word-by-word data
  Future<Map<String, List<WordByWordModel>>> getAllWordByWordData() async {
    return await _dataSource.getAllWordByWordData();
  }

  /// Clear cache
  void clearCache() {
    _dataSource.clearCache();
  }

  /// Get data statistics
  Future<Map<String, int>> getDataStatistics() async {
    return await _dataSource.getDataStatistics();
  }
}
