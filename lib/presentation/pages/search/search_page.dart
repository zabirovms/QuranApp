import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../providers/search_provider.dart';
import '../../providers/quran_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  
  const SearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    
    // Focus on search field when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      
      // Perform initial search if query is provided
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        ref.read(searchNotifierProvider.notifier).search(widget.initialQuery!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ҷустуҷӯ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (searchState.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchNotifierProvider.notifier).clearSearch();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search input with suggestions
          _buildSearchInput(searchState),
          
          // Filter chips
          _buildFilterChips(searchState),
          
          // Results
          Expanded(
            child: _buildResults(searchState, surahsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(SearchState searchState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Ҷустуҷӯ дар Қуръон...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              // Use debounced search to avoid lag while typing
              ref.read(searchNotifierProvider.notifier).search(value);
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              ref.read(searchNotifierProvider.notifier).search(value);
            },
          ),
          
          // Suggestions removed per request to reduce UI noise and work
        ],
      ),
    );
  }

  Widget _buildFilterChips(SearchState searchState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Ҳама',
              'both',
              searchState.selectedFilter,
              Icons.search,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Арабӣ',
              'arabic',
              searchState.selectedFilter,
              Icons.language,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Транслитератсия',
              'transliteration',
              searchState.selectedFilter,
              Icons.translate,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Тоҷикӣ',
              'tajik',
              searchState.selectedFilter,
              Icons.translate,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Тафсир',
              'tafsir',
              searchState.selectedFilter,
              Icons.menu_book,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, IconData icon) {
    final isSelected = selectedValue == value;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(searchNotifierProvider.notifier).updateFilter(value);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildResults(SearchState searchState, AsyncValue<List<dynamic>> surahsAsync) {
    if (searchState.query.isEmpty) {
      return _buildEmptyState();
    }

    if (searchState.isLoading) {
      return const Center(
        child: LoadingWidget(height: 100),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: CustomErrorWidget(
          title: 'Хатоги дар ҷустуҷӯ',
          message: searchState.error!,
          onRetry: () {
            ref.read(searchNotifierProvider.notifier).search(searchState.query);
          },
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Ҳеҷ натиҷае ёфт нашуд',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ҷустуҷӯи дигарро санҷед',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${searchState.results.length} натиҷа ёфт шуд',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: searchState.results.length,
            itemBuilder: (context, index) {
              final verse = searchState.results[index];
              final surahName = surahsAsync.maybeWhen(
                data: (surahs) {
                  try {
                    return surahs.firstWhere((s) => s.number == verse.surahId).nameTajik;
                  } catch (e) {
                    return 'Сураи ${verse.surahId}';
                  }
                },
                orElse: () => 'Сураи ${verse.surahId}',
              );

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  child: InkWell(
                    onTap: () {
                      context.go('/quran/${verse.surahId}/verse/${verse.verseNumber}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Surah and verse info
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${verse.surahId}:${verse.verseNumber}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  surahName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Arabic text
                          Text(
                            verse.arabicText,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Amiri',
                              height: 1.8,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Transliteration
                          if (verse.transliteration?.isNotEmpty == true)
                            Text(
                              verse.transliteration!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          
                          const SizedBox(height: 8),
                          
                          // Tajik translation
                          Text(
                            verse.tajikText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Ҷустуҷӯ дар Қуръон',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Дар ҳамаи забонҳо ҷустуҷӯ кунед',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Quick search chips removed as requested
}