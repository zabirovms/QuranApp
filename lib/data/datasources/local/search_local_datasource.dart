import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/verse_model.dart';

class SearchLocalDataSource {
  static const String _arabicJsonPath = 'assets/data/alquran_cloud_complete_quran.json';
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json';
  static const String _recentTermsKey = 'recent_search_terms';
  
  List<VerseModel>? _cachedVerses;
  List<_VerseIndexEntry>? _index; // precomputed normalized index for fast search

  static const int _maxResults = 200; // cap to avoid heavy UI rebuilds
  
  // Cache all verses for fast searching
  Future<List<VerseModel>> _getAllVerses() async {
    if (_cachedVerses != null) {
      return _cachedVerses!;
    }
    
    try {
      // Load Arabic text from alquran_cloud_complete_quran.json
      final String arabicResponse = await rootBundle.loadString(_arabicJsonPath);
      final Map<String, dynamic> arabicData = json.decode(arabicResponse);
      
      // Load translations from quran_mirror_with_translations.json
      final String translationsResponse = await rootBundle.loadString(_translationsJsonPath);
      final Map<String, dynamic> translationsData = json.decode(translationsResponse);
      
      final List<VerseModel> allVerses = [];
      
      // Get Arabic surahs
      final List<dynamic> arabicSurahs = arabicData['data']['surahs'];
      
      // Get translation surahs
      final List<dynamic> translationSurahs = translationsData['data']['surahs'];
      
      // Create a map of translations by surah number for quick lookup
      final Map<int, Map<int, Map<String, dynamic>>> translationMap = {};
      for (final surahData in translationSurahs) {
        final surahNumber = surahData['number'] as int;
        final List<dynamic> ayahs = surahData['ayahs'] as List;
        translationMap[surahNumber] = {};
        for (var ayah in ayahs) {
          translationMap[surahNumber]![ayah['number'] as int] = ayah;
        }
      }
      
      for (final arabicSurahData in arabicSurahs) {
        final surahNumber = arabicSurahData['number'] as int;
        final List<dynamic> arabicAyahs = arabicSurahData['ayahs'] as List;
        
        for (var arabicAyah in arabicAyahs) {
          final verseNumber = arabicAyah['numberInSurah'] as int;
          final translation = translationMap[surahNumber]?[arabicAyah['numberInSurah']];
          
          final verse = VerseModel(
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
          allVerses.add(verse);
        }
      }
      
      _cachedVerses = allVerses;
      // Build index lazily after verses load
      _buildIndex(allVerses);
      return allVerses;
    } catch (e) {
      throw Exception('Failed to load verses for search: $e');
    }
  }

  void _buildIndex(List<VerseModel> verses) {
    // Build normalized fields once to avoid regex/split on every keystroke
    // Exclude tafsir from index to improve performance and reduce memory usage
    _index = verses.map((v) => _VerseIndexEntry(
      verse: v,
      arabic: _normalizeText(v.arabicText),
      translit: _normalizeText(v.transliteration ?? ''),
      tajik: _normalizeText(v.tajikText),
      tafsir: '', // Not used in search anymore
    )).toList(growable: false);
  }

  // Persist a searched term for recent history (most-recent first, unique, capped)
  Future<void> saveSearchedTerm(String term, {int maxItems = 20}) async {
    final normalized = term.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_recentTermsKey) ?? <String>[];
    // Remove any existing occurrence (case-insensitive compare)
    existing.removeWhere((t) => t.toLowerCase() == normalized.toLowerCase());
    // Insert at front
    existing.insert(0, normalized);
    // Cap size
    if (existing.length > maxItems) {
      existing.removeRange(maxItems, existing.length);
    }
    await prefs.setStringList(_recentTermsKey, existing);
  }

  // Retrieve recent search terms (without triggering heavy data loads)
  Future<List<String>> getRecentSearchedTerms({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_recentTermsKey) ?? <String>[];
    if (existing.length <= limit) return existing;
    return existing.sublist(0, limit);
  }
  
  // Normalize text for better matching
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '') // Keep Arabic and alphanumeric
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
  
  
  // Search verses with advanced matching
  Future<List<VerseModel>> searchVerses(
    String query, {
    String language = 'both',
    int? surahId,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    if (query.trim().length < 2) {
      return [];
    }
    
    final allVerses = await _getAllVerses();
    _index ?? _buildIndex(allVerses);
    final List<VerseModel> results = [];
    
    final normalizedQuery = _normalizeText(query);

    for (final entry in _index!) {
      final verse = entry.verse;
      // Filter by surah if specified
      if (surahId != null && verse.surahId != surahId) {
        continue;
      }
      
      bool matches = false;
      
      // Search based on language preference
      switch (language.toLowerCase()) {
        case 'arabic':
          matches = entry.arabic.contains(normalizedQuery);
          break;
        case 'transliteration':
          matches = entry.translit.contains(normalizedQuery);
          break;
        case 'tajik':
          matches = entry.tajik.contains(normalizedQuery);
          break;
        case 'both':
        default:
          // Search in Arabic, transliteration, and Tajik only - tafsir excluded
          matches = entry.arabic.contains(normalizedQuery) ||
                    entry.translit.contains(normalizedQuery) ||
                    entry.tajik.contains(normalizedQuery);
          break;
      }
      
      if (matches) {
        results.add(verse);
        if (results.length >= _maxResults) break; // cap results early
      }
    }
    
    // Sort results by relevance (exact matches first, then partial matches)
    results.sort((a, b) {
      final queryLower = query.toLowerCase();
      
      // Check for exact matches in different fields (excluding tafsir)
      final aExact = a.arabicText.toLowerCase().contains(queryLower) ||
                     (a.transliteration?.toLowerCase().contains(queryLower) ?? false) ||
                     a.tajikText.toLowerCase().contains(queryLower);
      
      final bExact = b.arabicText.toLowerCase().contains(queryLower) ||
                     (b.transliteration?.toLowerCase().contains(queryLower) ?? false) ||
                     b.tajikText.toLowerCase().contains(queryLower);
      
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      // If both are exact or both are partial, sort by surah and verse number
      if (a.surahId != b.surahId) {
        return a.surahId.compareTo(b.surahId);
      }
      return a.verseNumber.compareTo(b.verseNumber);
    });
    
    return results;
  }
  
  // Get search suggestions based on partial query
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().length < 2) {
      return [];
    }
    
    final allVerses = await _getAllVerses();
    _index ?? _buildIndex(allVerses);
    final Set<String> suggestions = {};
    final qNorm = _normalizeText(query);
    
    // Build suggestions only from transliteration and Tajik; skip tafsir/arabic
    // Scan a limited number of verses for suggestions to keep fast
    int scanned = 0;
    for (final entry in _index!) {
      // Stop after scanning a subset (e.g., 1500 entries)
      if (scanned++ > 1500) break;
      if (suggestions.length >= 20) break;

      void takeWords(String normalizedSource, String originalSource) {
        if (normalizedSource.isEmpty || originalSource.isEmpty) return;
        final words = originalSource.split(RegExp(r'\s+'));
        for (final word in words) {
          if (suggestions.length >= 20) break;
          final nw = _normalizeText(word);
          if (nw.length >= 3 && nw.contains(qNorm)) {
            suggestions.add(word.trim());
          }
        }
      }

      takeWords(entry.translit, entry.verse.transliteration ?? '');
      takeWords(entry.tajik, entry.verse.tajikText);
    }
    
    return suggestions.toList()..sort();
  }
  
  // Clear cache (useful for memory management)
  void clearCache() {
    _cachedVerses = null;
  }
}

class _VerseIndexEntry {
  final VerseModel verse;
  final String arabic;
  final String translit;
  final String tajik;
  final String tafsir;

  _VerseIndexEntry({
    required this.verse,
    required this.arabic,
    required this.translit,
    required this.tajik,
    required this.tafsir,
  });
}
