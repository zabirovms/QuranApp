import '../datasources/local/surah_local_datasource.dart';
import '../datasources/local/verse_local_datasource.dart';
import '../datasources/local/search_local_datasource.dart';
import '../datasources/local/bookmark_local_datasource.dart';
import '../datasources/local/word_by_word_local_datasource.dart';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../models/bookmark_model.dart';
import '../../domain/repositories/quran_repository.dart';

class LocalQuranRepository implements QuranRepository {
  final SurahLocalDataSource _surahLocalDataSource;
  final VerseLocalDataSource _verseLocalDataSource;
  final SearchLocalDataSource _searchLocalDataSource;
  final BookmarkLocalDataSource _bookmarkLocalDataSource;
  final WordByWordLocalDataSource _wordByWordLocalDataSource;

  LocalQuranRepository({
    required SurahLocalDataSource surahLocalDataSource,
    required VerseLocalDataSource verseLocalDataSource,
    required SearchLocalDataSource searchLocalDataSource,
    required BookmarkLocalDataSource bookmarkLocalDataSource,
    required WordByWordLocalDataSource wordByWordLocalDataSource,
  }) : _surahLocalDataSource = surahLocalDataSource,
       _verseLocalDataSource = verseLocalDataSource,
       _searchLocalDataSource = searchLocalDataSource,
       _bookmarkLocalDataSource = bookmarkLocalDataSource,
       _wordByWordLocalDataSource = wordByWordLocalDataSource;

  // Surah operations - now using local data
  @override
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      return await _surahLocalDataSource.getAllSurahs();
    } catch (e) {
      throw Exception('Failed to fetch surahs from local data: $e');
    }
  }

  @override
  Future<SurahModel?> getSurahByNumber(int number) async {
    try {
      return await _surahLocalDataSource.getSurahByNumber(number);
    } catch (e) {
      throw Exception('Failed to fetch surah from local data: $e');
    }
  }

  // Verse operations - now using local data
  @override
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      return await _verseLocalDataSource.getVersesBySurah(surahNumber);
    } catch (e) {
      throw Exception('Failed to fetch verses from local data: $e');
    }
  }

  @override
  Future<VerseModel?> getVerseByKey(String uniqueKey) async {
    try {
      return await _verseLocalDataSource.getVerseByKey(uniqueKey);
    } catch (e) {
      throw Exception('Failed to fetch verse from local data: $e');
    }
  }

  @override
  Future<List<VerseModel>> searchVerses(String query, {String language = 'both', int? surahId}) async {
    try {
      return await _searchLocalDataSource.searchVerses(
        query,
        language: language,
        surahId: surahId,
      );
    } catch (e) {
      throw Exception('Failed to search verses from local data: $e');
    }
  }

  // Bookmark operations - now using local SQLite database
  @override
  Future<int> addBookmark(BookmarkModel bookmark) async {
    try {
      return await _bookmarkLocalDataSource.addBookmark(bookmark);
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  @override
  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    try {
      return await _bookmarkLocalDataSource.getBookmarksByUser(userId);
    } catch (e) {
      throw Exception('Failed to get bookmarks: $e');
    }
  }

  @override
  Future<bool> removeBookmark(int bookmarkId) async {
    try {
      return await _bookmarkLocalDataSource.removeBookmark(bookmarkId);
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  // Word analysis operations
  @override
  Future<List<Map<String, dynamic>>> getWordAnalysisByVerse(int verseId) async {
    try {
      // Parse verseId to get surah and verse numbers
      // Assuming verseId format is like "1:1" or we need to find the verse first
      final verse = await _verseLocalDataSource.getVerseByKey(verseId.toString());
      if (verse == null) {
        return [];
      }
      
      final words = await _wordByWordLocalDataSource.getWordByWordForVerse(verse.surahId, verse.verseNumber);
      
      // Convert to the expected format
      return words.map((word) => {
        'word_number': word.wordNumber,
        'arabic': word.arabic,
        'farsi': word.farsi,
        'unique_key': word.uniqueKey,
      }).toList();
    } catch (e) {
      throw Exception('Failed to get word analysis from local data: $e');
    }
  }

  // Search history operations
  @override
  Future<int> addSearchHistory(String userId, String query) async {
    throw UnimplementedError('Search history not available locally yet');
  }

  @override
  Future<List<Map<String, dynamic>>> getSearchHistoryByUser(String userId) async {
    throw UnimplementedError('Search history not available locally yet');
  }

  // Utility operations
  @override
  Future<void> clearAllData() async {
    throw UnimplementedError('Data clearing not available locally yet');
  }

  @override
  Future<void> clearUserData(String userId) async {
    throw UnimplementedError('User data clearing not available locally yet');
  }

  @override
  Future<int> getDatabaseSize() async {
    throw UnimplementedError('Database size not available locally yet');
  }
}
