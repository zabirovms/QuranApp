import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/prophet_model.dart';
import '../../providers/prophet_provider.dart';
import '../../providers/prophet_search_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class ProphetsPage extends ConsumerStatefulWidget {
  const ProphetsPage({super.key});

  @override
  ConsumerState<ProphetsPage> createState() => _ProphetsPageState();
}

class _ProphetsPageState extends ConsumerState<ProphetsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    final prophetsAsync = ref.read(prophetsProvider);
    prophetsAsync.whenData((prophets) {
      ref.read(prophetSearchProvider.notifier).search(value, prophets);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final prophetsAsync = ref.read(prophetsProvider);
    prophetsAsync.whenData((prophets) {
      ref.read(prophetSearchProvider.notifier).clearSearch(prophets);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prophetsAsync = ref.watch(prophetsProvider);
    final searchState = ref.watch(prophetSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final searchWidth = _isSearchExpanded ? (availableWidth * 0.6).clamp(200.0, 300.0) : 40.0;
            
            return Row(
              children: [
                if (!_isSearchExpanded)
                  const Text('Пайғамбарон'),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: searchWidth,
                  child: _isSearchExpanded
                      ? TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Ҷустуҷӯи пайғамбар...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _clearSearch();
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _isSearchExpanded = false;
                                    });
                                    _searchController.clear();
                                    _clearSearch();
                                    _searchFocusNode.unfocus();
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            _handleSearch(value);
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            setState(() {
                              _isSearchExpanded = true;
                            });
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _searchFocusNode.requestFocus();
                            });
                          },
                        ),
                ),
                const SizedBox(width: 8),
                // Sort dropdown
                Builder(
                  builder: (context) {
                    final currentSort = searchState.sortOrder;
                    return PopupMenuButton<ProphetSortOrder>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Ҷобаҷогузорӣ',
                      offset: const Offset(0, 45), // Position below the icon
                      onSelected: (value) {
                        prophetsAsync.whenData((prophets) {
                          ref.read(prophetSearchProvider.notifier).setSortOrder(value, prophets);
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<ProphetSortOrder>(
                          value: ProphetSortOrder.chronological,
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: currentSort == ProphetSortOrder.chronological
                                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Хронология',
                              style: TextStyle(
                                fontWeight: currentSort == ProphetSortOrder.chronological
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: currentSort == ProphetSortOrder.chronological
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        PopupMenuItem<ProphetSortOrder>(
                          value: ProphetSortOrder.aToZ,
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: currentSort == ProphetSortOrder.aToZ
                                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'А-Я',
                              style: TextStyle(
                                fontWeight: currentSort == ProphetSortOrder.aToZ
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: currentSort == ProphetSortOrder.aToZ
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/');
            }
          },
        ),
      ),
      body: prophetsAsync.when(
        data: (prophets) {
          // Initialize search state with all prophets if not already initialized
          if (searchState.filteredProphets.isEmpty && searchState.query.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(prophetSearchProvider.notifier).initializeProphets(prophets);
            });
          }

          // Always use filtered prophets from state (they include sort order)
          // If empty, it means we need to initialize, so apply sort directly
          final displayProphets = searchState.filteredProphets.isNotEmpty 
              ? searchState.filteredProphets 
              : _applySortOrder(prophets, searchState.sortOrder);

          return _buildProphetsList(displayProphets, searchState.query);
        },
        loading: () => const LoadingListWidget(
          itemCount: 10,
          itemHeight: 100,
        ),
        error: (error, stackTrace) => CustomErrorWidget(
          title: 'Хатоги дар боргирӣ',
          message: 'Пайғамбаронро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
          onRetry: () {
            ref.invalidate(prophetsProvider);
          },
        ),
      ),
    );
  }

  List<ProphetModel> _applySortOrder(List<ProphetModel> prophets, ProphetSortOrder sortOrder) {
    final sorted = List<ProphetModel>.from(prophets);
    switch (sortOrder) {
      case ProphetSortOrder.chronological:
        // Keep original order
        break;
      case ProphetSortOrder.aToZ:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return sorted;
  }

  Widget _buildProphetsList(List<ProphetModel> prophets, String query) {
    if (prophets.isEmpty) {
      return EmptyStateWidget(
        title: 'Пайғамбарон ёфт нашуд',
        message: query.isNotEmpty
            ? 'Барои "$query" пайғамбаре ёфт нашуд.'
            : 'Дар ҳоли ҳозир ҳеҷ пайғамбаре дар рӯйхат нест.',
        icon: Icons.person_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: prophets.length,
      itemBuilder: (context, index) {
        final prophet = prophets[index];
        return _ProphetCard(
          prophet: prophet,
          onTap: () {
            context.push('/prophets/detail', extra: prophet);
          },
        );
      },
    );
  }
}

class _ProphetCard extends StatelessWidget {
  final ProphetModel prophet;
  final VoidCallback onTap;

  const _ProphetCard({
    required this.prophet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasReferences = prophet.references != null && prophet.references!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Tajik name
                  Expanded(
                    child: Text(
                      prophet.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
              if (hasReferences) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${prophet.references!.length} сура, ${prophet.references!.fold<int>(0, (sum, ref) => sum + ref.verses.length)} оят',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Ишорат мавҷуд нест',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
