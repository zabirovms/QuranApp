import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/word_by_word_model.dart';

class WordByWordLocalDataSource {
  static const String _jsonPath = 'assets/data/word_by_word_translations.json';
  
  Map<String, List<WordByWordModel>>? _cachedData;

  /// Load all word-by-word data from local JSON file
  Future<Map<String, List<WordByWordModel>>> getAllWordByWordData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> data = jsonData['data'] as Map<String, dynamic>;
      
      final Map<String, List<WordByWordModel>> result = {};
      
      for (final surahEntry in data.entries) {
        final surahNumber = surahEntry.key;
        final verses = surahEntry.value as Map<String, dynamic>;
        
        for (final verseEntry in verses.entries) {
          final verseNumber = verseEntry.key;
          final words = verseEntry.value as List<dynamic>;
          
          final uniqueKey = '$surahNumber:$verseNumber';
          final wordModels = words.map((wordJson) => WordByWordModel.fromJson(wordJson)).toList();
          
          // Sort by word number to ensure correct order
          wordModels.sort((a, b) => a.wordNumber.compareTo(b.wordNumber));
          
          result[uniqueKey] = wordModels;
        }
      }
      
      _cachedData = result;
      return result;
    } catch (e) {
      throw Exception('Failed to load word-by-word data from local JSON: $e');
    }
  }

  /// Get word-by-word data for a specific verse
  Future<List<WordByWordModel>> getWordByWordForVerse(int surahNumber, int verseNumber) async {
    try {
      final allData = await getAllWordByWordData();
      final uniqueKey = '$surahNumber:$verseNumber';
      return allData[uniqueKey] ?? [];
    } catch (e) {
      throw Exception('Failed to load word-by-word data for verse $surahNumber:$verseNumber: $e');
    }
  }

  /// Get word-by-word data for multiple verses by their unique keys
  Future<Map<String, List<WordByWordModel>>> getWordByWordByKeys(List<String> uniqueKeys) async {
    try {
      final allData = await getAllWordByWordData();
      final Map<String, List<WordByWordModel>> result = {};
      
      for (final key in uniqueKeys) {
        if (allData.containsKey(key)) {
          result[key] = allData[key]!;
        }
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to load word-by-word data for keys: $e');
    }
  }

  /// Get word-by-word data for an entire surah
  Future<Map<String, List<WordByWordModel>>> getWordByWordForSurah(int surahNumber) async {
    try {
      final allData = await getAllWordByWordData();
      final Map<String, List<WordByWordModel>> result = {};
      
      for (final entry in allData.entries) {
        if (entry.key.startsWith('$surahNumber:')) {
          result[entry.key] = entry.value;
        }
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to load word-by-word data for surah $surahNumber: $e');
    }
  }

  /// Clear cache (useful for memory management)
  void clearCache() {
    _cachedData = null;
  }

  /// Get statistics about the loaded data
  Future<Map<String, int>> getDataStatistics() async {
    try {
      final allData = await getAllWordByWordData();
      int totalVerses = allData.length;
      int totalWords = 0;
      
      for (final words in allData.values) {
        totalWords += words.length;
      }
      
      return {
        'total_verses': totalVerses,
        'total_words': totalWords,
      };
    } catch (e) {
      return {
        'total_verses': 0,
        'total_words': 0,
      };
    }
  }
}
