import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verse_model.dart';
import '../../data/datasources/local/search_local_datasource.dart';
import '../../domain/usecases/search_verses_usecase.dart';
import 'quran_provider.dart';

// Search state
class SearchState {
  final String query;
  final List<VerseModel> results;
  final bool isLoading;
  final String? error;
  final List<String> suggestions;
  final String selectedFilter;
  final int? selectedSurahId;

  SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.suggestions = const [],
    this.selectedFilter = 'both',
    this.selectedSurahId,
  });

  SearchState copyWith({
    String? query,
    List<VerseModel>? results,
    bool? isLoading,
    String? error,
    List<String>? suggestions,
    String? selectedFilter,
    int? selectedSurahId,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      suggestions: suggestions ?? this.suggestions,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedSurahId: selectedSurahId ?? this.selectedSurahId,
    );
  }
}

// Enhanced search notifier with instant search
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchVersesUseCase _searchUseCase;
  final SearchLocalDataSource _searchDataSource;
  Timer? _debounceTimer;
  Timer? _suggestionTimer;

  SearchNotifier(this._searchUseCase, this._searchDataSource) : super(SearchState());

  // Debounced search with instant results
  void search(String query) {
    // Cancel previous timers
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    // Update query immediately for UI responsiveness
    state = state.copyWith(query: query);

    if (query.trim().isEmpty) {
      state = state.copyWith(
        results: [],
        suggestions: [],
        isLoading: false,
        error: null,
      );
      return;
    }

    if (query.trim().length < 2) {
      state = state.copyWith(
        results: [],
        suggestions: [],
        isLoading: false,
        error: null,
      );
      return;
    }

    // Show loading state
    state = state.copyWith(isLoading: true, error: null);

    // Debounce search to avoid too many requests
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        // Save only the searched term (not results)
        await _searchDataSource.saveSearchedTerm(query.trim());

        final results = await _searchUseCase(
          query,
          language: state.selectedFilter,
          surahId: state.selectedSurahId,
        );

        state = state.copyWith(
          results: results,
          isLoading: false,
          error: null,
        );
      } catch (e) {
        state = state.copyWith(
          results: [],
          isLoading: false,
          error: e.toString(),
        );
      }
    });

    // Get suggestions with a shorter delay
    _suggestionTimer = Timer(const Duration(milliseconds: 150), () async {
      try {
        final suggestions = await _searchDataSource.getSearchSuggestions(query);
        state = state.copyWith(suggestions: suggestions);
      } catch (e) {
        // Don't update state for suggestion errors
      }
    });
  }

  // Instant search without debouncing (for real-time search)
  void searchInstant(String query) {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    state = state.copyWith(query: query);

    if (query.trim().isEmpty) {
      state = state.copyWith(
        results: [],
        suggestions: [],
        isLoading: false,
        error: null,
      );
      return;
    }

    if (query.trim().length < 2) {
      state = state.copyWith(
        results: [],
        suggestions: [],
        isLoading: false,
        error: null,
      );
      return;
    }

    // Perform instant search
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final results = await _searchUseCase(
        query,
        language: state.selectedFilter,
        surahId: state.selectedSurahId,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        results: [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Update search filter
  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    
    // Re-search with new filter if there's a query
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  // Update surah filter
  void updateSurahFilter(int? surahId) {
    state = state.copyWith(selectedSurahId: surahId);
    
    // Re-search with new surah filter if there's a query
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  // Clear search
  void clearSearch() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    
    state = SearchState();
  }

  // Select suggestion
  void selectSuggestion(String suggestion) {
    search(suggestion);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }
}

// Provider for search notifier (autoDispose to avoid persisting results when leaving the page)
final searchNotifierProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  final searchUseCase = ref.watch(searchVersesUseCaseProvider);
  final searchDataSource = ref.watch(searchLocalDataSourceProvider);
  return SearchNotifier(searchUseCase, searchDataSource);
});

// Provider for search suggestions
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  final searchDataSource = ref.watch(searchLocalDataSourceProvider);
  return await searchDataSource.getSearchSuggestions(query);
});
