import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/dua_model.dart';
import '../../../data/datasources/local/json_data_source.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

// Providers
final duasDataProvider = FutureProvider<List<DuaModel>>((ref) async {
  final jsonDataSource = JsonDataSource();
  return await jsonDataSource.getDuasData();
});

final duasSearchProvider = StateNotifierProvider<DuasSearchNotifier, DuasSearchState>((ref) => DuasSearchNotifier());

// Search state model
class DuasSearchState {
  final String query;
  final List<DuaModel> filteredDuas;
  final bool isSearching;

  DuasSearchState({
    this.query = '',
    this.filteredDuas = const [],
    this.isSearching = false,
  });

  DuasSearchState copyWith({
    String? query,
    List<DuaModel>? filteredDuas,
    bool? isSearching,
  }) {
    return DuasSearchState(
      query: query ?? this.query,
      filteredDuas: filteredDuas ?? this.filteredDuas,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

// Search notifier
class DuasSearchNotifier extends StateNotifier<DuasSearchState> {
  DuasSearchNotifier() : super(DuasSearchState());

  void search(String query, List<DuaModel> allDuas) {
    if (query.isEmpty) {
      state = state.copyWith(
        query: query,
        filteredDuas: allDuas,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    final filtered = allDuas.where((dua) {
      final lowerQuery = query.toLowerCase();
      return dua.arabic.toLowerCase().contains(lowerQuery) ||
          dua.transliteration.toLowerCase().contains(lowerQuery) ||
          dua.tajik.toLowerCase().contains(lowerQuery) ||
          (dua.reference?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    state = state.copyWith(
      query: query,
      filteredDuas: filtered,
      isSearching: false,
    );
  }

  void clearSearch(List<DuaModel> allDuas) {
    state = state.copyWith(
      query: '',
      filteredDuas: allDuas,
      isSearching: false,
    );
  }
}

class DuasPage extends ConsumerStatefulWidget {
  const DuasPage({super.key});

  @override
  ConsumerState<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends ConsumerState<DuasPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duasDataAsync = ref.watch(duasDataProvider);
    final searchState = ref.watch(duasSearchProvider);

    return duasDataAsync.when(
      data: (allDuas) {
        // Split duas into tabs
        final quraniDuas = allDuas; // all duas for first tab
        final otherDuas = allDuas.where((dua) => dua.reference != 'Qur\'an').toList(); // empty list for second tab


        final tabController = TabController(length: 2, vsync: this);

        // Initialize search if empty
        if (searchState.filteredDuas.isEmpty && searchState.query.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(duasSearchProvider.notifier).clearSearch(quraniDuas);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Дуоҳо'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).go('/'); // navigate to home if no page to pop
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _searchFocusNode.requestFocus(); // focus your search field
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Tabs
              TabBar(
                controller: tabController,
                tabs: const [
                  Tab(text: 'Қуръонӣ'),
                  Tab(text: 'Дигар'),
                ],
              ),

              // Search & Tab content
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _buildTabContent(quraniDuas, searchState),
                    _buildTabContent(otherDuas, searchState, isOtherTab: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: LoadingWidget())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: CustomErrorWidget(
            message: 'Хатогии боргирӣ: $error',
            onRetry: () => ref.refresh(duasDataProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<DuaModel> duas, DuasSearchState searchState, {bool isOtherTab = false}) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Ҷустуҷӯи дуо...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchState.query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(duasSearchProvider.notifier).clearSearch(duas);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (query) {
              ref.read(duasSearchProvider.notifier).search(query, duas);
            },
          ),
        ),

        // Results count
        if (searchState.query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Ҷавобҳо: ${searchState.filteredDuas.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(duasSearchProvider.notifier).clearSearch(duas);
                  },
                  child: const Text('Тоза кардан'),
                ),
              ],
            ),
          ),

        // Duas list
        Expanded(
          child: searchState.isSearching
              ? const Center(child: CircularProgressIndicator())
              : searchState.filteredDuas.isEmpty
                  ? _buildEmptyState(isOtherTab)
                  : _buildDuasList(searchState.filteredDuas),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isOtherTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isOtherTab ? 'Ҳанӯз дуое нест' : 'Дуо ёфт нашуд',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOtherTab
                ? 'Дар ҳоли ҳозир дуое барои ин категория нест'
                : 'Лутфан калимаҳои дигар кӯшиш кунед',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDuasList(List<DuaModel> duas) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: duas.length,
      itemBuilder: (context, index) {
        final dua = duas[index];
        return DuaCard(
          dua: dua,
          onTap: () => _showDuaDetail(dua),
        );
      },
    );
  }

  void _showDuaDetail(DuaModel dua) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DuaDetailSheet(dua: dua),
    );
  }
}

class DuaCard extends StatelessWidget {
  final DuaModel dua;
  final VoidCallback? onTap;

  const DuaCard({
    super.key,
    required this.dua,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dua.reference ?? 'Reference not available',
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
              Text(
                dua.arabic,
                style: const TextStyle(fontSize: 20, height: 1.6),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text(
                dua.transliteration,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Text(
                dua.tajik,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DuaDetailSheet extends StatelessWidget {
  final DuaModel dua;

  const DuaDetailSheet({
    super.key,
    required this.dua,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        dua.reference ?? 'Reference not available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  dua.arabic,
                  style: const TextStyle(fontSize: 24, height: 1.8),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                Text(
                  dua.transliteration,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  dua.tajik,
                  style: const TextStyle(fontSize: 18, height: 1.6, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Дуо нусхабардорӣ шуд')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Нусхабардорӣ'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Мубодила карда шуд')),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Мубодила'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
