import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/verse_model.dart';
import '../../domain/usecases/bookmark_usecase.dart';
import 'quran_provider.dart';

// Bookmark state
class BookmarkState {
  final List<BookmarkModel> bookmarks;
  final bool isLoading;
  final String? error;
  final Map<String, bool> bookmarkStatus; // verseKey -> isBookmarked

  BookmarkState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
    this.bookmarkStatus = const {},
  });

  BookmarkState copyWith({
    List<BookmarkModel>? bookmarks,
    bool? isLoading,
    String? error,
    Map<String, bool>? bookmarkStatus,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      bookmarkStatus: bookmarkStatus ?? this.bookmarkStatus,
    );
  }
}

// Bookmark notifier
class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final BookmarkUseCase _bookmarkUseCase;
  final String _userId;

  BookmarkNotifier(this._bookmarkUseCase, this._userId) : super(BookmarkState()) {
    _loadBookmarks();
  }

  // Load all bookmarks for the user
  Future<void> _loadBookmarks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final bookmarks = await _bookmarkUseCase.getBookmarksByUser(_userId);
      final bookmarkStatus = <String, bool>{};
      
      for (final bookmark in bookmarks) {
        bookmarkStatus[bookmark.verseKey] = true;
      }
      
      state = state.copyWith(
        bookmarks: bookmarks,
        isLoading: false,
        bookmarkStatus: bookmarkStatus,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refresh bookmarks
  Future<void> refreshBookmarks() async {
    await _loadBookmarks();
  }

  // Add bookmark from verse
  Future<bool> addBookmark(VerseModel verse, String surahName) async {
    try {
      await _bookmarkUseCase.addBookmarkFromVerse(verse, _userId, surahName);
      
      // Update local state
      final newBookmark = BookmarkModel(
        id: 0, // Will be updated when we refresh
        userId: _userId,
        verseId: verse.id,
        verseKey: verse.uniqueKey,
        surahNumber: verse.surahId,
        verseNumber: verse.verseNumber,
        arabicText: verse.arabicText,
        tajikText: verse.tajikText,
        surahName: surahName,
        createdAt: DateTime.now(),
      );
      
      final updatedBookmarks = [...state.bookmarks, newBookmark];
      final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
      updatedStatus[verse.uniqueKey] = true;
      
      state = state.copyWith(
        bookmarks: updatedBookmarks,
        bookmarkStatus: updatedStatus,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Remove bookmark
  Future<bool> removeBookmark(int bookmarkId) async {
    try {
      final success = await _bookmarkUseCase.removeBookmark(bookmarkId);
      
      if (success) {
        // Update local state
        final updatedBookmarks = state.bookmarks.where((b) => b.id != bookmarkId).toList();
        final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
        
        // Find the removed bookmark to update status
        final removedBookmark = state.bookmarks.firstWhere((b) => b.id == bookmarkId);
        updatedStatus[removedBookmark.verseKey] = false;
        
        state = state.copyWith(
          bookmarks: updatedBookmarks,
          bookmarkStatus: updatedStatus,
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Toggle bookmark (add if not exists, remove if exists)
  Future<bool> toggleBookmark(VerseModel verse, String surahName) async {
    final isCurrentlyBookmarked = state.bookmarkStatus[verse.uniqueKey] ?? false;
    
    if (isCurrentlyBookmarked) {
      // Find and remove the bookmark
      final bookmark = state.bookmarks.firstWhere(
        (b) => b.verseKey == verse.uniqueKey,
        orElse: () => throw Exception('Bookmark not found'),
      );
      return await removeBookmark(bookmark.id);
    } else {
      // Add new bookmark
      return await addBookmark(verse, surahName);
    }
  }

  // Check if verse is bookmarked
  bool isVerseBookmarked(String verseKey) {
    return state.bookmarkStatus[verseKey] ?? false;
  }

  // Get bookmarks by surah
  List<BookmarkModel> getBookmarksBySurah(int surahNumber) {
    return state.bookmarks.where((b) => b.surahNumber == surahNumber).toList();
  }

  // Get bookmark count
  int get bookmarkCount => state.bookmarks.length;

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    try {
      for (final bookmark in state.bookmarks) {
        await _bookmarkUseCase.removeBookmark(bookmark.id);
      }
      
      state = state.copyWith(
        bookmarks: [],
        bookmarkStatus: {},
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Provider for bookmark notifier
final bookmarkNotifierProvider = StateNotifierProvider.family<BookmarkNotifier, BookmarkState, String>((ref, userId) {
  final bookmarkUseCase = ref.watch(bookmarkUseCaseProvider);
  return BookmarkNotifier(bookmarkUseCase, userId);
});

// Provider for bookmark use case
final bookmarkUseCaseProvider = Provider<BookmarkUseCase>((ref) {
  return BookmarkUseCase(ref.watch(quranRepositoryProvider));
});

// Convenience providers
final bookmarksProvider = Provider.family<List<BookmarkModel>, String>((ref, userId) {
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarks;
});

final bookmarkCountProvider = Provider.family<int, String>((ref, userId) {
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarks.length;
});

final isVerseBookmarkedProvider = Provider.family<bool, (String, String)>((ref, params) {
  final (userId, verseKey) = params;
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarkStatus[verseKey] ?? false;
});

// Provider for bookmarks by surah
final bookmarksBySurahProvider = Provider.family<List<BookmarkModel>, (String, int)>((ref, params) {
  final (userId, surahNumber) = params;
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarks
      .where((b) => b.surahNumber == surahNumber)
      .toList();
});
