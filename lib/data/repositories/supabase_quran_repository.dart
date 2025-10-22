import '../datasources/remote/api_service.dart';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../models/bookmark_model.dart';
import '../../domain/repositories/quran_repository.dart';

class SupabaseQuranRepository implements QuranRepository {
  final ApiService _apiService;

  SupabaseQuranRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  // Surah operations
  @override
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      final response = await _apiService.getAllSurahs();
      final surahsData = response.data as List;
      
      return surahsData.map((surah) => SurahModel.fromJson(surah)).toList();
    } catch (e) {
      throw Exception('Failed to fetch surahs from API: $e');
    }
  }

  @override
  Future<SurahModel?> getSurahByNumber(int number) async {
    try {
      final response = await _apiService.getSurahByNumber(number);
      final surahData = response.data;

      if (surahData == null) return null;

      // Supabase returns an array for filtered selects. Handle both array and object.
      if (surahData is List) {
        if (surahData.isEmpty) return null;
        final first = surahData.first as Map<String, dynamic>;
        return SurahModel.fromJson(first);
      }
      if (surahData is Map<String, dynamic>) {
        return SurahModel.fromJson(surahData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch surah from API: $e');
    }
  }

  @override
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      final response = await _apiService.getVersesBySurah(surahNumber);
      final versesData = response.data as List;
      
      return versesData.map((verse) => VerseModel.fromJson(verse)).toList();
    } catch (e) {
      throw Exception('Failed to fetch verses from API: $e');
    }
  }

  @override
  Future<List<VerseModel>> searchVerses(String query, {String language = 'both', int? surahId}) async {
    try {
      final response = await _apiService.searchVerses(query, language: language, surahId: surahId);
      final versesData = response.data as List;
      
      return versesData.map((verse) => VerseModel.fromJson(verse)).toList();
    } catch (e) {
      throw Exception('Failed to search verses from API: $e');
    }
  }

  // Bookmark operations (keep local for user data)
  @override
  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    try {
      final response = await _apiService.getBookmarksByUser(userId);
      final bookmarksData = response.data as List;
      
      return bookmarksData.map((bookmark) => BookmarkModel.fromJson(bookmark)).toList();
    } catch (e) {
      // If API fails, return empty list (no local fallback)
      return [];
    }
  }

  @override
  Future<int> addBookmark(BookmarkModel bookmark) async {
    try {
      // Conform to table schema: only user_id, verse_id, created_at
      final payload = {
        'user_id': bookmark.userId,
        'verse_id': bookmark.verseId,
        'created_at': bookmark.createdAt.toIso8601String(),
      };
      final response = await _apiService.addBookmark(payload);
      // Supabase may return inserted row array; handle both map/array
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return data.first['id'] ?? 0;
      }
      if (data is Map<String, dynamic>) {
        return data['id'] ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  @override
  Future<bool> removeBookmark(int bookmarkId) async {
    try {
      await _apiService.removeBookmark(bookmarkId);
      return true;
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  @override
  Future<bool> removeBookmarkByVerseKey(String userId, String verseKey) async {
    try {
      // Get all bookmarks for user and find the one with matching verse key
      final bookmarks = await getBookmarksByUser(userId);
      final bookmark = bookmarks.firstWhere(
        (b) => b.verseKey == verseKey,
        orElse: () => throw Exception('Bookmark not found'),
      );
      
      return await removeBookmark(bookmark.id);
    } catch (e) {
      throw Exception('Failed to remove bookmark by verse key: $e');
    }
  }

  @override
  Future<VerseModel?> getVerseByKey(String uniqueKey) async {
    try {
      // Parse uniqueKey (format: "surahNumber:verseNumber")
      final parts = uniqueKey.split(':');
      if (parts.length != 2) return null;
      
      final surahNumber = int.tryParse(parts[0]);
      final verseNumber = int.tryParse(parts[1]);
      if (surahNumber == null || verseNumber == null) return null;
      
      final verses = await getVersesBySurah(surahNumber);
      return verses.firstWhere(
        (verse) => verse.verseNumber == verseNumber,
        orElse: () => throw StateError('Verse not found'),
      );
    } catch (e) {
      throw Exception('Failed to get verse by key from Supabase: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWordAnalysisByVerse(int verseId) async {
    try {
      // This would require a word analysis API endpoint
      // For now, return empty list as this feature might not be implemented yet
      return [];
    } catch (e) {
      throw Exception('Failed to get word analysis from Supabase: $e');
    }
  }

  @override
  Future<int> addSearchHistory(String userId, String query) async {
    try {
      final response = await _apiService.addSearchHistory({
        'user_id': userId,
        'query': query,
        'created_at': DateTime.now().toIso8601String(),
      });
      return response.data['id'] ?? 0;
    } catch (e) {
      throw Exception('Failed to add search history to Supabase: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSearchHistoryByUser(String userId) async {
    try {
      final response = await _apiService.getSearchHistoryByUser(userId);
      final historyData = response.data['data'] as List;
      return historyData.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get search history from Supabase: $e');
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      // This would clear all data in Supabase
      // For now, just clear user-specific data
      await clearUserData('default_user');
    } catch (e) {
      throw Exception('Failed to clear all data from Supabase: $e');
    }
  }

  @override
  Future<void> clearUserData(String userId) async {
    try {
      // Clear user bookmarks and search history
      await _apiService.clearUserBookmarks(userId);
      await _apiService.clearUserSearchHistory(userId);
    } catch (e) {
      throw Exception('Failed to clear user data from Supabase: $e');
    }
  }

  @override
  Future<int> getDatabaseSize() async {
    try {
      // This would require a database size API endpoint
      // For now, return 0 as this might not be implemented
      return 0;
    } catch (e) {
      throw Exception('Failed to get database size from Supabase: $e');
    }
  }
}
