import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/prophet_model.dart';

enum ProphetSortOrder {
  chronological, // As they appear in JSON (chronological order)
  aToZ, // A-Z by Tajik name
}

class ProphetSearchState {
  final String query;
  final ProphetSortOrder sortOrder;
  final List<ProphetModel> filteredProphets;
  final bool isSearching;

  ProphetSearchState({
    this.query = '',
    this.sortOrder = ProphetSortOrder.chronological,
    this.filteredProphets = const [],
    this.isSearching = false,
  });

  ProphetSearchState copyWith({
    String? query,
    ProphetSortOrder? sortOrder,
    List<ProphetModel>? filteredProphets,
    bool? isSearching,
  }) {
    return ProphetSearchState(
      query: query ?? this.query,
      sortOrder: sortOrder ?? this.sortOrder,
      filteredProphets: filteredProphets ?? this.filteredProphets,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class ProphetSearchNotifier extends StateNotifier<ProphetSearchState> {
  ProphetSearchNotifier() : super(ProphetSearchState());

  void initializeProphets(List<ProphetModel> allProphets) {
    if (state.filteredProphets.isEmpty) {
      _applyFilters(allProphets, state.query, state.sortOrder);
    }
  }

  void search(String query, List<ProphetModel> allProphets) {
    state = state.copyWith(query: query, isSearching: true);
    _applyFilters(allProphets, query, state.sortOrder);
  }

  void setSortOrder(ProphetSortOrder sortOrder, List<ProphetModel> allProphets) {
    // Update sort order and apply filters with current query
    _applyFilters(allProphets, state.query, sortOrder);
  }

  void _applyFilters(List<ProphetModel> allProphets, String query, ProphetSortOrder sortOrder) {
    List<ProphetModel> filtered = allProphets;

    // Apply search filter
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = allProphets.where((prophet) {
        return prophet.name.toLowerCase().contains(lowerQuery) ||
            prophet.arabic.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply sort order
    switch (sortOrder) {
      case ProphetSortOrder.chronological:
        // Keep original order (as in JSON)
        break;
      case ProphetSortOrder.aToZ:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    state = state.copyWith(
      sortOrder: sortOrder, // Update sort order in state
      filteredProphets: filtered,
      isSearching: false,
    );
  }

  void clearSearch(List<ProphetModel> allProphets) {
    state = state.copyWith(query: '');
    _applyFilters(allProphets, '', state.sortOrder);
  }
}

final prophetSearchProvider = StateNotifierProvider.autoDispose<ProphetSearchNotifier, ProphetSearchState>((ref) {
  return ProphetSearchNotifier();
});

