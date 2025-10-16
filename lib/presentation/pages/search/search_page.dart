import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/verse_model.dart';
import '../../../domain/repositories/quran_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../providers/quran_provider.dart';

// Providers
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) => SearchNotifier(ref.read(quranRepositoryProvider)));

// Search state
class SearchState {
  final String query;
  final List<VerseModel> results;
  final bool isLoading;
  final String? error;
  final List<String> searchHistory;
  final String selectedFilter;

  SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.searchHistory = const [],
    this.selectedFilter = 'all',
  });

  SearchState copyWith({
    String? query,
    List<VerseModel>? results,
    bool? isLoading,
    String? error,
    List<String>? searchHistory,
    String? selectedFilter,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchHistory: searchHistory ?? this.searchHistory,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final QuranRepository _repository;

  SearchNotifier(this._repository) : super(SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        results: [],
        isLoading: false,
        error: null,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
    );

    try {
      final results = await _repository.searchVerses(query);
      
      // Add to search history
      final newHistory = [query, ...state.searchHistory.where((h) => h != query).take(9)];
      
      state = state.copyWith(
        results: results,
        isLoading: false,
        searchHistory: newHistory,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Хатоги дар ҷустуҷӯ: $e',
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(
      query: '',
      results: [],
      error: null,
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void removeFromHistory(String query) {
    final newHistory = state.searchHistory.where((h) => h != query).toList();
    state = state.copyWith(searchHistory: newHistory);
  }

  void clearHistory() {
    state = state.copyWith(searchHistory: []);
  }
}

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  
  const SearchPage({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ҷустуҷӯ'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            } catch (e) {
              GoRouter.of(context).go('/');
            }
          },
        ),
        actions: [
          if (searchState.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).clearSearch();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Ҷустуҷӯи оятҳо...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchState.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (_) {},
              onSubmitted: (query) {
                ref.read(searchProvider.notifier).search(query);
              },
            ),
          ),

          // Filter chips
          if (searchState.query.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Ҳама', searchState.selectedFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('arabic', 'Арабӣ', searchState.selectedFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('translation', 'Тарҷума', searchState.selectedFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('transliteration', 'Транслитератсия', searchState.selectedFilter),
                  ],
                ),
              ),
            ),

          // Results
          Expanded(
            child: _buildResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String selectedFilter) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(searchProvider.notifier).setFilter(value);
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (searchState.error != null) {
      return Center(
        child: CustomErrorWidget(
          message: searchState.error!,
          onRetry: () => ref.read(searchProvider.notifier).search(searchState.query),
        ),
      );
    }

    if (searchState.query.isEmpty) {
      return _buildSearchSuggestions(searchState);
    }

    if (searchState.results.isEmpty) {
      return _buildNoResults(searchState.query);
    }

    return _buildSearchResults(searchState.results);
  }

  Widget _buildSearchSuggestions(SearchState searchState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ҷустуҷӯи оятҳо',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оятеро бо калимаҳои арабӣ, тарҷума ё транслитератсия ҷустуҷӯ кунед',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          if (searchState.searchHistory.isNotEmpty) ...[
            Text(
              'Ҷустуҷӯҳои қаблӣ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: searchState.searchHistory.map((query) {
                return InputChip(
                  label: Text(query),
                  onPressed: () {
                    _searchController.text = query;
                    ref.read(searchProvider.notifier).search(query);
                  },
                  onDeleted: () {
                    ref.read(searchProvider.notifier).removeFromHistory(query);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.read(searchProvider.notifier).clearHistory();
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Тоза кардани таърих'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Оят ёфт нашуд',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ҷустуҷӯи "$query" ҳеҷ натиҷае надод',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              ref.read(searchProvider.notifier).clearSearch();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Ҷустуҷӯи нав'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<VerseModel> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final verse = results[index];
        return SearchResultCard(
          verse: verse,
          onTap: () => _navigateToVerse(verse),
        );
      },
    );
  }

  void _navigateToVerse(VerseModel verse) {
    context.go('/surah/${verse.surahId}/verse/${verse.verseNumber}');
  }
}

class SearchResultCard extends StatelessWidget {
  final VerseModel verse;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.verse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Surah and verse reference
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Сураи ${verse.surahId}, Ояти ${verse.verseNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Arabic text
              Text(
                verse.arabicText,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.6,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Translation
              Text(
                verse.tajikText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}