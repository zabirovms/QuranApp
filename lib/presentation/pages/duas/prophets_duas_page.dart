import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/prophet_dua_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import 'duas_page.dart'; // For shared providers

// Provider to group duas by prophet
final prophetsDuasGroupedProvider = FutureProvider<List<ProphetDuaModel>>((ref) async {
  final allDuas = await ref.watch(prophetsDuasProvider.future);
  
  // Group duas by prophet
  final Map<String, Map<int, List<int>>> prophetMap = {};
  final Map<String, String?> arabicNames = {};
  
  for (final dua in allDuas) {
    if (dua.prophet == null) continue;
    
    final prophetName = dua.prophet!;
    if (!prophetMap.containsKey(prophetName)) {
      prophetMap[prophetName] = {};
      arabicNames[prophetName] = dua.prophetArabic;
    }
    
    if (!prophetMap[prophetName]!.containsKey(dua.surah)) {
      prophetMap[prophetName]![dua.surah] = [];
    }
    
    if (!prophetMap[prophetName]![dua.surah]!.contains(dua.verse)) {
      prophetMap[prophetName]![dua.surah]!.add(dua.verse);
    }
  }
  
  // Convert to ProphetDuaModel list
  final List<ProphetDuaModel> prophets = [];
  for (final entry in prophetMap.entries) {
    final references = entry.value.entries.map((e) {
      return ProphetDuaReference(
        surah: e.key,
        verses: e.value..sort(),
      );
    }).toList();
    
    references.sort((a, b) => a.surah.compareTo(b.surah));
    
    prophets.add(ProphetDuaModel(
      name: entry.key,
      arabicName: arabicNames[entry.key],
      references: references,
    ));
  }
  
  return prophets;
});

class ProphetsDuasPage extends ConsumerStatefulWidget {
  const ProphetsDuasPage({super.key});

  @override
  ConsumerState<ProphetsDuasPage> createState() => _ProphetsDuasPageState();
}

class _ProphetsDuasPageState extends ConsumerState<ProphetsDuasPage> {
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
    // Search is handled in build method by filtering the list
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prophetsAsync = ref.watch(prophetsDuasGroupedProvider);
    final query = _searchController.text.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final searchWidth = _isSearchExpanded 
                ? availableWidth - 8
                : 40.0;
            
            return Row(
              children: [
                if (!_isSearchExpanded)
                  const Text('Пайғамбарон'),
                if (!_isSearchExpanded)
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
              ],
            );
          },
        ),
        centerTitle: false,
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
          // Filter by search query
          final filteredProphets = query.isEmpty
              ? prophets
              : prophets.where((p) {
                  return p.name.toLowerCase().contains(query) ||
                      (p.arabicName?.toLowerCase().contains(query) ?? false);
                }).toList();

          return _buildProphetsList(filteredProphets, query);
        },
        loading: () => const LoadingListWidget(
          itemCount: 10,
          itemHeight: 100,
        ),
        error: (error, stackTrace) => CustomErrorWidget(
          title: 'Хатоги дар боргирӣ',
          message: 'Дуоҳои пайғамбаронро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
          onRetry: () {
            ref.invalidate(prophetsDuasGroupedProvider);
          },
        ),
      ),
    );
  }

  Widget _buildProphetsList(List<ProphetDuaModel> prophets, String query) {
    if (prophets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Пайғамбарон ёфт нашуд',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Барои "$query" пайғамбаре ёфт нашуд.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
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
            context.push('/duas/prophets/detail', extra: prophet);
          },
        );
      },
    );
  }
}

class _ProphetCard extends StatelessWidget {
  final ProphetDuaModel prophet;
  final VoidCallback onTap;

  const _ProphetCard({
    required this.prophet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasReferences = prophet.references.isNotEmpty;

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
                      '${prophet.references.length} сура, ${prophet.references.fold<int>(0, (sum, ref) => sum + ref.verses.length)} оят',
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
