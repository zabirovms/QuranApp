import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/dua_model.dart';
import '../../../core/utils/compressed_json_loader.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import 'duas_page.dart'; // For shared widgets and providers

// Provider for rabbano duas - simplified to only use pre-populated JSON data
final rabbanoDuasProvider = FutureProvider<List<DuaModel>>((ref) async {
  // Load directly from pre-populated JSON file (all data is already there)
  try {
    final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList('assets/data/quranic_duas.json');
    if (jsonList.isEmpty) {
      throw Exception('Duas JSON file is empty or has no data');
    }
    
    final allDuas = jsonList.map((json) {
      try {
        return DuaModel.fromJson(json);
      } catch (e) {
        return null;
      }
    }).whereType<DuaModel>().toList();
    
    if (allDuas.isEmpty) {
      throw Exception('No valid duas found in JSON file after parsing');
    }
    
    return allDuas;
  } catch (e) {
    if (e.toString().contains('does not exist') || e.toString().contains('empty')) {
      throw Exception('Duas JSON file does not exist or has empty data. Please ensure assets/data/quranic_duas.json exists.');
    }
    throw Exception('Failed to load duas JSON file: $e');
  }
});

class RabbanoDuasPage extends ConsumerStatefulWidget {
  const RabbanoDuasPage({super.key});

  @override
  ConsumerState<RabbanoDuasPage> createState() => _RabbanoDuasPageState();
}

class _RabbanoDuasPageState extends ConsumerState<RabbanoDuasPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _surahTabController;
  bool _isSearchExpanded = false;
  List<int> _surahNumbers = [];
  Map<int, List<DuaModel>> _duasBySurah = {};

  @override
  void initState() {
    super.initState();
    _surahTabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _surahTabController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    final rabbanoDuasAsync = ref.read(rabbanoDuasProvider);
    rabbanoDuasAsync.whenData((rabbanoDuas) {
      ref.read(duasSearchProvider.notifier).searchQuranicDuas(value, rabbanoDuas);
    });
  }

  void _clearSearch() {
    final rabbanoDuasAsync = ref.read(rabbanoDuasProvider);
    rabbanoDuasAsync.whenData((rabbanoDuas) {
      ref.read(duasSearchProvider.notifier).clearSearch(rabbanoDuas, []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rabbanoDuasAsync = ref.watch(rabbanoDuasProvider);
    final searchState = ref.watch(duasSearchProvider);

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
                  const Text('Раббано'),
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
                            hintText: 'Ҷустуҷӯи дуоҳои Раббано...',
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
      body: rabbanoDuasAsync.when(
        data: (rabbanoDuas) {
          // Initialize search only once
          if (!searchState.isQuranicInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(duasSearchProvider.notifier).initializeQuranicDuas(rabbanoDuas);
            });
          }

          // Group duas by surah and update surah tab controller
          _updateSurahTabs(rabbanoDuas);

          // Build the tab structure with surah tabs
          return _buildRabbanoTabWithSurahTabs(rabbanoDuas, searchState);
        },
        loading: () => const Center(
          child: LoadingCircularWidget(size: 50),
        ),
        error: (error, stack) => Center(
          child: CustomErrorWidget(
            message: 'Хатогии зеркашӣ: $error',
            onRetry: () => ref.refresh(rabbanoDuasProvider),
          ),
        ),
      ),
    );
  }

  void _updateSurahTabs(List<DuaModel> duas) {
    final duasBySurah = <int, List<DuaModel>>{};
    for (final dua in duas) {
      if (!duasBySurah.containsKey(dua.surah)) {
        duasBySurah[dua.surah] = [];
      }
      duasBySurah[dua.surah]!.add(dua);
    }
    
    final surahNumbers = duasBySurah.keys.toList()..sort();
    
    if (surahNumbers != _surahNumbers) {
      final newLength = surahNumbers.length + 1;
      
      if (_surahTabController.length != newLength) {
        final oldIndex = _surahTabController.index;
        _surahTabController.dispose();
        _surahTabController = TabController(length: newLength, vsync: this);
        if (oldIndex < newLength) {
          _surahTabController.index = oldIndex;
        }
      }
      
      setState(() {
        _surahNumbers = surahNumbers;
        _duasBySurah = duasBySurah;
      });
    }
  }

  String _getSurahName(int surahNumber) {
    final surahNames = {
      1: 'Ал-Фотиҳа', 2: 'Ал-Бақара', 3: 'Оли Имрон', 4: 'Ан-Нисо', 5: 'Ал-Маида',
      6: 'Ал-Анъом', 7: 'Ал-Аъроф', 8: 'Ал-Анфол', 9: 'Ат-Тавба', 10: 'Юнус',
      11: 'Ҳуд', 12: 'Юсуф', 13: 'Ар-Раъд', 14: 'Иброҳим', 15: 'Ал-Ҳиҷр',
      16: 'Ан-Наҳл', 17: 'Ал-Исро', 18: 'Ал-Каҳф', 19: 'Марям', 20: 'Тоҳо',
      21: 'Ал-Анбиё', 22: 'Ал-Ҳаҷҷ', 23: 'Ал-Муъминун', 24: 'Ан-Нур', 25: 'Ал-Фурқон',
      26: 'Аш-Шуъаро', 27: 'Ан-Намл', 28: 'Ал-Қасас', 29: 'Ал-Анкабут', 30: 'Ар-Рум',
      31: 'Луқмон', 32: 'Ас-Саҷда', 33: 'Ал-Аҳзоб', 34: 'Сабаъ', 35: 'Фотир',
      36: 'Ясин', 37: 'Ас-Соффот', 38: 'Сод', 39: 'Аз-Зумар', 40: 'Ғофир',
      41: 'Фуссилат', 42: 'Аш-Шуро', 43: 'Аз-Зухруф', 44: 'Ад-Духон', 45: 'Ал-Ҷосия',
      46: 'Ал-Аҳқоф', 47: 'Муҳаммад', 48: 'Ал-Фатҳ', 49: 'Ал-Ҳуҷурот', 50: 'Қоф',
      51: 'Аз-Зориёт', 52: 'Ат-Тур', 53: 'Ан-Наҷм', 54: 'Ал-Қамар', 55: 'Ар-Раҳмон',
      56: 'Ал-Воқиа', 57: 'Ал-Ҳадид', 58: 'Ал-Муҷодала', 59: 'Ал-Ҳашр', 60: 'Ал-Мумтаҳана',
      61: 'Ас-Сафф', 62: 'Ал-Ҷумъа', 63: 'Ал-Мунофиқун', 64: 'Ат-Тағобун', 65: 'Ат-Талақ',
      66: 'Ат-Таҳрим', 67: 'Ал-Мулк', 68: 'Ал-Қалам', 69: 'Ал-Ҳоққа', 70: 'Ал-Маъориҷ',
      71: 'Нуҳ', 72: 'Ал-Ҷинн', 73: 'Ал-Муззаммил', 74: 'Ал-Муддассир', 75: 'Ал-Қиёма',
      76: 'Ал-Инсон', 77: 'Ал-Мурсалот', 78: 'Ан-Набоъ', 79: 'Ан-Назиъот', 80: 'Абаса',
      81: 'Ат-Таквир', 82: 'Ал-Инфитор', 83: 'Ал-Мутоффифин', 84: 'Ал-Иншиқоқ', 85: 'Ал-Буруҷ',
      86: 'Ат-Ториқ', 87: 'Ал-Аъло', 88: 'Ал-Ғошия', 89: 'Ал-Фаҷр', 90: 'Ал-Балад',
      91: 'Аш-Шамс', 92: 'Ал-Лайл', 93: 'Аз-Зуҳо', 94: 'Ал-Иншироҳ', 95: 'Ат-Тин',
      96: 'Ал-Алақ', 97: 'Ал-Қадр', 98: 'Ал-Байина', 99: 'Аз-Залзала', 100: 'Ал-Одиёт',
      101: 'Ал-Қориа', 102: 'Ат-Такосур', 103: 'Ал-Аср', 104: 'Ал-Ҳумаза', 105: 'Ал-Фил',
      106: 'Қурайш', 107: 'Ал-Маъун', 108: 'Ал-Кавсар', 109: 'Ал-Кофирун', 110: 'Ан-Наср',
      111: 'Ал-Масад', 112: 'Ал-Ихлос', 113: 'Ал-Фалақ', 114: 'Ан-Нас',
    };
    return surahNames[surahNumber] ?? 'Сураи $surahNumber';
  }

  Widget _buildRabbanoTabWithSurahTabs(List<DuaModel> allDuas, DuasSearchState searchState) {
    if (_surahNumbers.isEmpty) {
      return const Center(child: LoadingCircularWidget());
    }

    return Column(
      children: [
        TabBar(
          controller: _surahTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: [
            const Tab(text: 'Ҳама'),
            ..._surahNumbers.map((surahNum) => Tab(text: _getSurahName(surahNum))),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _surahTabController,
            children: [
              _buildDuasListForSurah(null, allDuas, searchState),
              ..._surahNumbers.map((surahNum) {
                final duas = _duasBySurah[surahNum] ?? [];
                return _buildDuasListForSurah(surahNum, duas, searchState);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuasListForSurah(int? surahNumber, List<DuaModel> duas, DuasSearchState searchState) {
    List<DuaModel> displayDuas = duas;
    if (searchState.query.isNotEmpty && searchState.isQuranicInitialized) {
      displayDuas = duas.where((dua) {
        final lowerQuery = searchState.query.toLowerCase();
        return dua.arabic.toLowerCase().contains(lowerQuery) ||
            dua.transliteration.toLowerCase().contains(lowerQuery) ||
            dua.tajik.toLowerCase().contains(lowerQuery) ||
            '${dua.surah}:${dua.verse}'.contains(lowerQuery);
      }).toList();
    }

    if (displayDuas.isEmpty) {
      return _buildEmptyState();
    }

    return _buildQuranicDuasList(displayDuas);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Дуоҳо ёфт нашуд',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranicDuasList(List<DuaModel> duas) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: duas.length,
      itemBuilder: (context, index) {
        final dua = duas[index];
        return QuranicDuaCard(
          dua: dua,
          onTap: () => context.push('/surah/${dua.surah}/verse/${dua.verse}'),
        );
      },
    );
  }
}

