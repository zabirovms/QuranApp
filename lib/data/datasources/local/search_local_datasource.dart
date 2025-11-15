import 'package:shared_preferences/shared_preferences.dart';
import '../../models/verse_model.dart';
import '../../../core/utils/compressed_json_loader.dart';

class SearchLocalDataSource {
  static const String _arabicJsonPath = 'assets/data/alquran_cloud_complete_quran.json.gz';
  static const String _translationsJsonPath = 'assets/data/quran_mirror_with_translations.json.gz';
  static const String _russianJsonPath = 'assets/data/quran_ru.json.gz';
  static const String _tj2JsonPath = 'assets/data/quran_tj_2_AbuAlomuddin.json.gz';
  static const String _tj3JsonPath = 'assets/data/quran_tj_3_PioneersTranslationCenter.json.gz';
  static const String _farsiJsonPath = 'assets/data/quran_farsi_Farsi.json.gz';
  static const String _recentTermsKey = 'recent_search_terms';
  
  List<VerseModel>? _cachedVerses;
  List<_VerseIndexEntry>? _index; // precomputed normalized index for fast search

  static const int _maxResults = 200; // cap to avoid heavy UI rebuilds
  
  // Load Russian translations from JSON file
  Future<Map<String, Map<int, String>>> _loadAllRussianTranslations() async {
    try {
      final Map<String, dynamic> russianData = await CompressedJsonLoader.loadCompressedJsonAsMap(_russianJsonPath);
      
      final Map<String, Map<int, String>> allRussianMap = {};
      for (final entry in russianData.entries) {
        final surahKey = entry.key;
        final List<dynamic> verses = entry.value as List;
        final Map<int, String> surahMap = {};
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            surahMap[verseNum] = text;
          }
        }
        allRussianMap[surahKey] = surahMap;
      }
      return allRussianMap;
    } catch (e) {
      // If Russian file doesn't exist or fails to load, return empty map
      return {};
    }
  }
  
  // Load tj_2 translations from JSON file
  Future<Map<String, Map<int, String>>> _loadAllTj2Translations() async {
    try {
      final Map<String, dynamic> tj2Data = await CompressedJsonLoader.loadCompressedJsonAsMap(_tj2JsonPath);
      
      final Map<String, Map<int, String>> allTj2Map = {};
      for (final entry in tj2Data.entries) {
        final surahKey = entry.key;
        final List<dynamic> verses = entry.value as List;
        final Map<int, String> surahMap = {};
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            surahMap[verseNum] = text;
          }
        }
        allTj2Map[surahKey] = surahMap;
      }
      return allTj2Map;
    } catch (e) {
      return {};
    }
  }
  
  // Load tj_3 translations from JSON file
  Future<Map<String, Map<int, String>>> _loadAllTj3Translations() async {
    try {
      final Map<String, dynamic> tj3Data = await CompressedJsonLoader.loadCompressedJsonAsMap(_tj3JsonPath);
      
      final Map<String, Map<int, String>> allTj3Map = {};
      for (final entry in tj3Data.entries) {
        final surahKey = entry.key;
        final List<dynamic> verses = entry.value as List;
        final Map<int, String> surahMap = {};
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            surahMap[verseNum] = text;
          }
        }
        allTj3Map[surahKey] = surahMap;
      }
      return allTj3Map;
    } catch (e) {
      return {};
    }
  }

  // Load Farsi translations from JSON file
  Future<Map<String, Map<int, String>>> _loadAllFarsiTranslations() async {
    try {
      final Map<String, dynamic> farsiData = await CompressedJsonLoader.loadCompressedJsonAsMap(_farsiJsonPath);
      
      final Map<String, Map<int, String>> allFarsiMap = {};
      for (final entry in farsiData.entries) {
        final surahKey = entry.key;
        final List<dynamic> verses = entry.value as List;
        final Map<int, String> surahMap = {};
        for (var verseData in verses) {
          final verseNum = verseData['verse'] as int?;
          final text = verseData['text'] as String?;
          if (verseNum != null && text != null && text.isNotEmpty) {
            surahMap[verseNum] = text;
          }
        }
        allFarsiMap[surahKey] = surahMap;
      }
      return allFarsiMap;
    } catch (e) {
      return {};
    }
  }

  // Cache all verses for fast searching
  Future<List<VerseModel>> _getAllVerses() async {
    if (_cachedVerses != null) {
      return _cachedVerses!;
    }
    
    try {
      // Load Arabic text from compressed file
      final Map<String, dynamic> arabicData = await CompressedJsonLoader.loadCompressedJsonAsMap(_arabicJsonPath);
      
      // Load translations from compressed file
      final Map<String, dynamic> translationsData = await CompressedJsonLoader.loadCompressedJsonAsMap(_translationsJsonPath);
      
      // Load Russian translations
      final Map<String, Map<int, String>> russianTranslations = await _loadAllRussianTranslations();
      
      // Load tj_2 and tj_3 translations
      final Map<String, Map<int, String>> tj2Translations = await _loadAllTj2Translations();
      final Map<String, Map<int, String>> tj3Translations = await _loadAllTj3Translations();
      // Load Farsi translations
      final Map<String, Map<int, String>> farsiTranslations = await _loadAllFarsiTranslations();
      
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
        
        // Get Russian translations for this surah
        final surahRussianMap = russianTranslations[surahNumber.toString()] ?? {};
        
        // Get tj_2 and tj_3 translations for this surah
        final surahTj2Map = tj2Translations[surahNumber.toString()] ?? {};
        final surahTj3Map = tj3Translations[surahNumber.toString()] ?? {};
        final surahFarsiMap = farsiTranslations[surahNumber.toString()] ?? {};
        
        for (var arabicAyah in arabicAyahs) {
          final verseNumber = arabicAyah['numberInSurah'] as int;
          final translation = translationMap[surahNumber]?[arabicAyah['numberInSurah']];
          
          // Get Russian translation if available
          final russianText = surahRussianMap[verseNumber];
          
          // Get tj_2 and tj_3 translations from local files
          final tj2Text = surahTj2Map[verseNumber];
          final tj3Text = surahTj3Map[verseNumber];
          final farsiText = surahFarsiMap[verseNumber];
          
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
          allVerses.add(verse);
        }
      }
      
      _cachedVerses = allVerses;
      // Build index after verses load
      _buildIndex(allVerses);
      return allVerses;
    } catch (e) {
      throw Exception('Failed to load verses for search: $e');
    }
  }

  void _buildIndex(List<VerseModel> verses) {
    // Build normalized fields once to avoid regex/split on every keystroke
    // Include all translations for comprehensive search
    _index = verses.map((v) => _VerseIndexEntry(
      verse: v,
      arabic: _normalizeText(v.arabicText),
      translit: _normalizeText(v.transliteration ?? ''),
      tajik: _normalizeText(v.tajikText),
      tj2: _normalizeText(v.tj2 ?? ''),
      tj3: _normalizeText(v.tj3 ?? ''),
      farsi: _normalizeText(v.farsi ?? ''),
      russian: _normalizeText(v.russian ?? ''),
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
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF\u0400-\u04FF]'), '') // Keep Arabic, Cyrillic (Tajik/Russian), and alphanumeric
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
    if (_index == null) {
      _buildIndex(allVerses);
    }
    final List<VerseModel> results = [];
    
    final normalizedQuery = _normalizeText(query);
    
    // Ensure normalized query is not empty
    if (normalizedQuery.isEmpty) {
      return [];
    }
    
    // Ensure index is not null
    if (_index == null || _index!.isEmpty) {
      return [];
    }

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
        case 'tj_2':
          matches = entry.tj2.contains(normalizedQuery);
          break;
        case 'tj_3':
          matches = entry.tj3.contains(normalizedQuery);
          break;
        case 'farsi':
          matches = entry.farsi.contains(normalizedQuery);
          break;
        case 'russian':
          matches = entry.russian.contains(normalizedQuery);
          break;
        case 'both':
        default:
          // Search in Arabic, transliteration, and all translations
          matches = entry.arabic.contains(normalizedQuery) ||
                    entry.translit.contains(normalizedQuery) ||
                    entry.tajik.contains(normalizedQuery) ||
                    entry.tj2.contains(normalizedQuery) ||
                    entry.tj3.contains(normalizedQuery) ||
                    entry.farsi.contains(normalizedQuery) ||
                    entry.russian.contains(normalizedQuery);
          break;
      }
      
      // Only add if it actually matches
      if (matches) {
        results.add(verse);
        if (results.length >= _maxResults) break; // cap results early
      }
    }
    
    // Sort results by relevance (exact matches first, then partial matches)
    results.sort((a, b) {
      final queryLower = query.toLowerCase();
      
      // Check for exact matches in different fields (all translations)
      final aExact = a.arabicText.toLowerCase().contains(queryLower) ||
                     (a.transliteration?.toLowerCase().contains(queryLower) ?? false) ||
                     a.tajikText.toLowerCase().contains(queryLower) ||
                     (a.tj2?.toLowerCase().contains(queryLower) ?? false) ||
                     (a.tj3?.toLowerCase().contains(queryLower) ?? false) ||
                     (a.farsi?.toLowerCase().contains(queryLower) ?? false) ||
                     (a.russian?.toLowerCase().contains(queryLower) ?? false);
      
      final bExact = b.arabicText.toLowerCase().contains(queryLower) ||
                     (b.transliteration?.toLowerCase().contains(queryLower) ?? false) ||
                     b.tajikText.toLowerCase().contains(queryLower) ||
                     (b.tj2?.toLowerCase().contains(queryLower) ?? false) ||
                     (b.tj3?.toLowerCase().contains(queryLower) ?? false) ||
                     (b.farsi?.toLowerCase().contains(queryLower) ?? false) ||
                     (b.russian?.toLowerCase().contains(queryLower) ?? false);
      
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
  final String tj2;
  final String tj3;
  final String farsi;
  final String russian;
  final String tafsir;

  _VerseIndexEntry({
    required this.verse,
    required this.arabic,
    required this.translit,
    required this.tajik,
    required this.tj2,
    required this.tj3,
    required this.farsi,
    required this.russian,
    required this.tafsir,
  });
}
