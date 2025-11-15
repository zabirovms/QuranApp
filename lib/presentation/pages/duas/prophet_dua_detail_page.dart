import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/prophet_dua_model.dart';
import '../../../data/models/dua_model.dart';
import '../../providers/quran_provider.dart';
import 'duas_page.dart'; // For prophetsDuasProvider
import '../../../shared/widgets/loading_widget.dart';

class ProphetDuaDetailPage extends ConsumerStatefulWidget {
  final ProphetDuaModel prophet;

  const ProphetDuaDetailPage({
    super.key,
    required this.prophet,
  });

  @override
  ConsumerState<ProphetDuaDetailPage> createState() => _ProphetDuaDetailPageState();
}

class _ProphetDuaDetailPageState extends ConsumerState<ProphetDuaDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<int>> _surahVersesMap = {};
  Map<int, Map<int, DuaModel>> _surahVerseDataMap = {}; // Map surah -> verse -> DuaModel
  List<int> _surahNumbers = [];
  // Scroll controllers to preserve scroll position when state updates
  final ScrollController _allTabScrollController = ScrollController();
  final Map<int, ScrollController> _surahTabScrollControllers = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller with temporary length, will be updated when data loads
    _tabController = TabController(length: 1, vsync: this);
  }
  
  void _loadDataFromJson(List<DuaModel> allDuas) {
    // Filter duas for this prophet
    final prophetDuas = allDuas.where((dua) => 
      dua.prophet == widget.prophet.name
    ).toList();
    
    // Group by surah and verse
    for (final dua in prophetDuas) {
      if (!_surahVersesMap.containsKey(dua.surah)) {
        _surahVersesMap[dua.surah] = [];
        _surahVerseDataMap[dua.surah] = {};
      }
      if (!_surahVersesMap[dua.surah]!.contains(dua.verse)) {
        _surahVersesMap[dua.surah]!.add(dua.verse);
      }
      _surahVerseDataMap[dua.surah]![dua.verse] = dua;
    }
    
    // Sort verses for each surah
    for (final surah in _surahVersesMap.keys) {
      _surahVersesMap[surah]!.sort();
    }
    
    _surahNumbers = _surahVersesMap.keys.toList()..sort();
    
    // Update tab controller length
    final newLength = _surahNumbers.length + 1;
    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allTabScrollController.dispose();
    for (final controller in _surahTabScrollControllers.values) {
      controller.dispose();
    }
    _surahTabScrollControllers.clear();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allDuasAsync = ref.watch(prophetsDuasProvider);

    return allDuasAsync.when(
      data: (allDuas) {
        // Load data from JSON if not already loaded
        if (_surahNumbers.isEmpty) {
          _loadDataFromJson(allDuas);
        }

        // Check if there are any references
        if (_surahNumbers.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.prophet.name),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    GoRouter.of(context).pop();
                  } else {
                    GoRouter.of(context).go('/duas/prophets');
                  }
                },
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ишорат мавҷуд нест',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Барои ин пайғамбар ишорате дар Қуръон мавҷуд нест.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.prophet.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).go('/duas/prophets');
                }
              },
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                const Tab(text: 'Ҳама'),
                ..._surahNumbers.map((surahNum) {
                  return Tab(text: _getSurahName(surahNum));
                }),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // "All" tab - shows all verses from all surahs
              _buildAllVersesTab(),
              // Individual surah tabs
              ..._surahNumbers.map((surahNum) {
                return _buildSurahTab(surahNum, _surahVersesMap[surahNum]!);
              }),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(widget.prophet.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/duas/prophets');
              }
            },
          ),
        ),
        body: const Center(child: LoadingCircularWidget()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: Text(widget.prophet.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/duas/prophets');
              }
            },
          ),
        ),
        body: Center(
          child: Text('Хатоги дар боргирӣ: $error'),
        ),
      ),
    );
  }

  Widget _buildAllVersesTab() {
    return ListView.builder(
      controller: _allTabScrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _surahNumbers.length,
      itemBuilder: (context, index) {
        final surahNumber = _surahNumbers[index];
        final verseNumbers = _surahVersesMap[surahNumber]!;
        final verseDataMap = _surahVerseDataMap[surahNumber];
        
        return _SurahVersesSection(
          surahNumber: surahNumber,
          verseNumbers: verseNumbers,
          verseDataMap: verseDataMap,
          isNested: true,
          onVerseTap: (surahNum, verseNum) {
            context.push('/surah/$surahNum/verse/$verseNum');
          },
        );
      },
    );
  }

  Widget _buildSurahTab(int surahNumber, List<int> verseNumbers) {
    // Get or create scroll controller for this surah tab
    if (!_surahTabScrollControllers.containsKey(surahNumber)) {
      _surahTabScrollControllers[surahNumber] = ScrollController();
    }
    
    final verseDataMap = _surahVerseDataMap[surahNumber];
    
    return _SurahVersesSection(
      surahNumber: surahNumber,
      verseNumbers: verseNumbers,
      verseDataMap: verseDataMap,
      isNested: false,
      scrollController: _surahTabScrollControllers[surahNumber],
      onVerseTap: (surahNum, verseNum) {
        context.push('/surah/$surahNum/verse/$verseNum');
      },
    );
  }
}

class _SurahVersesSection extends ConsumerWidget {
  final int surahNumber;
  final List<int> verseNumbers;
  final Map<int, DuaModel>? verseDataMap; // Map verse -> DuaModel from JSON
  final bool isNested; // If true, use Column; if false, use ListView
  final ScrollController? scrollController; // To preserve scroll position
  final void Function(int surahNum, int verseNum) onVerseTap;

  const _SurahVersesSection({
    required this.surahNumber,
    required this.verseNumbers,
    this.verseDataMap,
    this.isNested = false,
    this.scrollController,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahProvider(surahNumber));

    // Use only pre-populated data from prophets_duas.json
    if (verseDataMap == null || verseDataMap!.isEmpty) {
      return const SizedBox.shrink();
    }

    return surahAsync.when(
      data: (surah) {
        final children = [
          // Surah header - only show in "All" tab (when isNested is true)
          if (isNested)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$surahNumber',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      surah?.nameTajik ?? 'Сураи $surahNumber',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${verseNumbers.length} оят',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          // Simple verse widgets from JSON data
          ...verseNumbers.map((verseNum) {
            final dua = verseDataMap![verseNum];
            if (dua == null) {
              return const SizedBox.shrink();
            }
            
            return _SimpleVerseWidget(
              surahNumber: surahNumber,
              verseNumber: verseNum,
              arabic: dua.arabic.trim(),
              tajik: dua.tajik.isNotEmpty ? dua.tajik : '',
              transliteration: dua.transliteration,
              onTap: () => onVerseTap(surahNumber, verseNum),
            );
          }),
        ];

        // If nested (inside another ListView), return Column
        // Otherwise, return ListView
        if (isNested) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
        } else {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            children: children,
          );
        }
      },
      loading: () => const LoadingCircularWidget(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

// Simple verse widget that only shows Arabic, Tajik, and transliteration
class _SimpleVerseWidget extends StatelessWidget {
  final int surahNumber;
  final int verseNumber;
  final String arabic;
  final String tajik;
  final String? transliteration;
  final VoidCallback onTap;

  const _SimpleVerseWidget({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabic,
    required this.tajik,
    this.transliteration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verse number with surah:verse format
            Text(
              '$surahNumber:$verseNumber',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            // Arabic text
            Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  arabic,
                  style: theme.textTheme.titleLarge?.copyWith(
                    height: 1.4,
                    fontSize: 22,
                    fontFamily: 'Amiri',
                    letterSpacing: 0.0,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // Transliteration
            if (transliteration != null && transliteration!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                transliteration!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            // Tajik translation
            if (tajik.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tajik,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
            const SizedBox(height: 12),
            // Button to view in full surah at the bottom
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Дар сура дидан'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

