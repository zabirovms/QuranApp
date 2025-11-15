import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quran_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/quran/surah_list_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/surah_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final hasAnyBookmarks = ref.watch(bookmarkNotifierProvider(userId)).bookmarks.isNotEmpty;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle device back button
          if (GoRouter.of(context).canPop()) {
            GoRouter.of(context).pop();
          } else {
            // If no history, go to main menu
            context.go('/');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Қуръон'),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                // If no history, go to main menu
                context.go('/');
              }
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Ҷустуҷӯ',
          ),
          IconButton(
            icon: Icon(hasAnyBookmarks ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              context.push('/bookmarks');
            },
            tooltip: 'Захираҳо',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Танзимот',
          ),
        ],
      ),
        body: const _SurahsTab(),
      ),
    );
  }
}

class _SurahsTab extends ConsumerStatefulWidget {
  const _SurahsTab();

  @override
  ConsumerState<_SurahsTab> createState() => _SurahsTabState();
}

class _SurahsTabState extends ConsumerState<_SurahsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAscending = true; // true = 1-114, false = 114-1

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurahModel> _filterSurahs(List<SurahModel> surahs, String query) {
    if (query.isEmpty) return surahs;
    
    final lowerQuery = query.toLowerCase();
    return surahs.where((surah) {
      // Search by number
      if (surah.number.toString().contains(lowerQuery)) return true;
      
      // Search by Arabic name
      if (surah.nameArabic.toLowerCase().contains(lowerQuery)) return true;
      
      // Search by Tajik name
      if (surah.nameTajik.toLowerCase().contains(lowerQuery)) return true;
      
      // Search by English name
      if (surah.nameEnglish.toLowerCase().contains(lowerQuery)) return true;
      
      // Search by revelation type
      if (surah.revelationType.toLowerCase().contains(lowerQuery)) return true;
      
      return false;
    }).toList();
  }

  List<SurahModel> _sortSurahs(List<SurahModel> surahs) {
    final sorted = List<SurahModel>.from(surahs);
    sorted.sort((a, b) => _isAscending 
        ? a.number.compareTo(b.number) 
        : b.number.compareTo(a.number));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ҷустуҷӯи сураҳо...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // Surahs List
              Expanded(
                child: surahsAsync.when(
                  data: (surahs) {
                    if (surahs.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'Қуръон ёфт нашуд',
                        message: 'Дар ҳоли ҳозир ҳеҷ сурае дар барнома нест. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                        icon: Icons.menu_book,
                      );
                    }

                    final sortedSurahs = _sortSurahs(surahs);
                    final filteredSurahs = _filterSurahs(sortedSurahs, _searchQuery);
                    
                    if (filteredSurahs.isEmpty && _searchQuery.isNotEmpty) {
                      return EmptyStateWidget(
                        title: 'Сура ёфт нашуд',
                        message: 'Сурае бо "$_searchQuery" ёфт нашуд. Лутфан дар навъи дигар ҷустуҷӯ кунед.',
                        icon: Icons.search_off,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = filteredSurahs[index];
                        return SurahListItem(
                          surah: surah,
                          onTap: () => context.push('/surah/${surah.number}'),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingListWidget(
                    itemCount: 10,
                    itemHeight: 100,
                  ),
                  error: (error, stackTrace) => CustomErrorWidget(
                    title: 'Хатоги дар боргирӣ',
                    message: 'Қуръонро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                    onRetry: () {
                      ref.invalidate(surahsProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating Action Button for reordering
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 2,
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
            tooltip: _isAscending ? 'Ҷобаҷо кардан 114-1' : 'Ҷобаҷо кардан 1-114',
            child: Icon(
              _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
        ),
      ],
    );
  }
}

