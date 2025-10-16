import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/api_service.dart';
import '../../data/repositories/supabase_quran_repository.dart';
import '../../data/datasources/remote/alquran_cloud_api.dart';
import '../pages/surah/surah_controller.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/usecases/get_all_surahs_usecase.dart';
import '../../domain/usecases/get_surah_usecase.dart';
import '../../domain/usecases/get_verses_usecase.dart';
import '../../domain/usecases/search_verses_usecase.dart';
import '../../domain/usecases/bookmark_usecase.dart';
import '../../data/models/surah_model.dart';
import '../../data/models/verse_model.dart';
import '../../data/models/bookmark_model.dart';

// Providers for dependencies
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final alquranCloudApiProvider = Provider<AlQuranCloudApi>((ref) => AlQuranCloudApi());

final surahControllerProvider = ChangeNotifierProvider.family<SurahController, int>((ref, surahNumber) {
  final api = ref.watch(apiServiceProvider);
  final aqc = ref.watch(alquranCloudApiProvider);
  final controller = SurahController(apiService: api, aqc: aqc);
  // Default audio edition can be persisted later via settings
  controller.load(surahNumber: surahNumber, audioEdition: 'ar.alafasy');
  return controller;
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return SupabaseQuranRepository(
    apiService: ref.watch(apiServiceProvider),
  );
});

// Use case providers
final getAllSurahsUseCaseProvider = Provider<GetAllSurahsUseCase>((ref) {
  return GetAllSurahsUseCase(ref.watch(quranRepositoryProvider));
});

final getSurahUseCaseProvider = Provider<GetSurahUseCase>((ref) {
  return GetSurahUseCase(ref.watch(quranRepositoryProvider));
});

final getVersesUseCaseProvider = Provider<GetVersesUseCase>((ref) {
  return GetVersesUseCase(ref.watch(quranRepositoryProvider));
});

final searchVersesUseCaseProvider = Provider<SearchVersesUseCase>((ref) {
  return SearchVersesUseCase(ref.watch(quranRepositoryProvider));
});

final bookmarkUseCaseProvider = Provider<BookmarkUseCase>((ref) {
  return BookmarkUseCase(ref.watch(quranRepositoryProvider));
});

// State providers
final surahsProvider = FutureProvider<List<SurahModel>>((ref) async {
  final useCase = ref.watch(getAllSurahsUseCaseProvider);
  return await useCase();
});

final surahProvider = FutureProvider.family<SurahModel?, int>((ref, surahNumber) async {
  final useCase = ref.watch(getSurahUseCaseProvider);
  return await useCase(surahNumber);
});

final versesProvider = FutureProvider.family<List<VerseModel>, int>((ref, surahNumber) async {
  final useCase = ref.watch(getVersesUseCaseProvider);
  return await useCase(surahNumber);
});

final searchResultsProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<VerseModel>>>((ref) => SearchNotifier(ref.watch(searchVersesUseCaseProvider)));

final bookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) async {
  final useCase = ref.watch(bookmarkUseCaseProvider);
  return await useCase.getBookmarksByUser('default_user');
});

// Search notifier
class SearchNotifier extends StateNotifier<AsyncValue<List<VerseModel>>> {
  final SearchVersesUseCase _searchUseCase;

  SearchNotifier(this._searchUseCase) : super(const AsyncValue.data([]));

  Future<void> search(String query, {String language = 'both', int? surahId}) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final results = await _searchUseCase(query, language: language, surahId: surahId);
      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

// Bookmark notifier (no user authentication needed)
class BookmarkNotifier extends StateNotifier<AsyncValue<List<BookmarkModel>>> {
  final BookmarkUseCase _bookmarkUseCase;

  BookmarkNotifier(this._bookmarkUseCase) : super(const AsyncValue.loading()) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _bookmarkUseCase.getBookmarksByUser('default_user');
      state = AsyncValue.data(bookmarks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    try {
      await _bookmarkUseCase.addBookmark(bookmark);
      await _loadBookmarks(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeBookmark(int bookmarkId) async {
    try {
      await _bookmarkUseCase.removeBookmark(bookmarkId);
      await _loadBookmarks(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Bookmark notifier provider
final bookmarkNotifierProvider = StateNotifierProvider<BookmarkNotifier, AsyncValue<List<BookmarkModel>>>((ref) => BookmarkNotifier(ref.watch(bookmarkUseCaseProvider)));
