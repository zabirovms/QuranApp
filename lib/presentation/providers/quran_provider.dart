import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/datasources/remote/alquran_cloud_api.dart';
import '../../data/repositories/local_quran_repository.dart';
import '../../data/datasources/local/surah_local_datasource.dart';
import '../../data/datasources/local/verse_local_datasource.dart';
import '../../data/datasources/local/search_local_datasource.dart';
import '../../data/datasources/local/bookmark_local_datasource.dart';
import '../../data/datasources/local/word_by_word_local_datasource.dart';
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
final alquranCloudApiProvider = Provider<AlQuranCloudApi>((ref) => AlQuranCloudApi());


final surahLocalDataSourceProvider = Provider<SurahLocalDataSource>((ref) => SurahLocalDataSource());

final verseLocalDataSourceProvider = Provider<VerseLocalDataSource>((ref) => VerseLocalDataSource());

final searchLocalDataSourceProvider = Provider<SearchLocalDataSource>((ref) => SearchLocalDataSource());

final bookmarkLocalDataSourceProvider = Provider<BookmarkLocalDataSource>((ref) => BookmarkLocalDataSource());

final wordByWordLocalDataSourceProvider = Provider<WordByWordLocalDataSource>((ref) => WordByWordLocalDataSource());

final surahControllerProvider = ChangeNotifierProvider.family<SurahController, int>((ref, surahNumber) {
  final aqc = ref.watch(alquranCloudApiProvider);
  final wordByWordDataSource = ref.watch(wordByWordLocalDataSourceProvider);
  final verseDataSource = ref.watch(verseLocalDataSourceProvider);
  final surahDataSource = ref.watch(surahLocalDataSourceProvider);
  final controller = SurahController(
    aqc: aqc,
    wordByWordDataSource: wordByWordDataSource,
    verseDataSource: verseDataSource,
    surahDataSource: surahDataSource,
  );
  // Default audio edition can be persisted later via settings
  controller.load(surahNumber: surahNumber, audioEdition: 'ar.alafasy');
  return controller;
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return LocalQuranRepository(
    surahLocalDataSource: ref.watch(surahLocalDataSourceProvider),
    verseLocalDataSource: ref.watch(verseLocalDataSourceProvider),
    searchLocalDataSource: ref.watch(searchLocalDataSourceProvider),
    bookmarkLocalDataSource: ref.watch(bookmarkLocalDataSourceProvider),
    wordByWordLocalDataSource: ref.watch(wordByWordLocalDataSourceProvider),
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

// Connectivity status provider (true when online, false when offline)
// Note: This is kept for other features that might need it, but surahs now use local data
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Emit initial status
  final initial = await connectivity.checkConnectivity();
  yield initial != ConnectivityResult.none;
  // Emit changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield result != ConnectivityResult.none;
  }
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

// Legacy bookmark notifier - kept for backward compatibility
class LegacyBookmarkNotifier extends StateNotifier<AsyncValue<List<BookmarkModel>>> {
  final BookmarkUseCase _bookmarkUseCase;

  LegacyBookmarkNotifier(this._bookmarkUseCase) : super(const AsyncValue.loading()) {
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

// Legacy bookmark notifier provider
final legacyBookmarkNotifierProvider = StateNotifierProvider<LegacyBookmarkNotifier, AsyncValue<List<BookmarkModel>>>((ref) => LegacyBookmarkNotifier(ref.watch(bookmarkUseCaseProvider)));
