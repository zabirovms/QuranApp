import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/prophet_model.dart';
import '../../../data/models/prophet_reference_model.dart';
import '../../providers/quran_provider.dart';
import '../../../data/services/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../../shared/widgets/loading_widget.dart';

class ProphetDetailPage extends ConsumerStatefulWidget {
  final ProphetModel prophet;

  const ProphetDetailPage({
    super.key,
    required this.prophet,
  });

  @override
  ConsumerState<ProphetDetailPage> createState() => _ProphetDetailPageState();
}

class _ProphetDetailPageState extends ConsumerState<ProphetDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<int>> _surahVersesMap = {};
  Map<int, ProphetReferenceModel> _surahReferenceMap = {}; // Map surah -> reference for verse_data access
  List<int> _surahNumbers = [];
  // Scroll controllers to preserve scroll position when state updates
  final ScrollController _allTabScrollController = ScrollController();
  final Map<int, ScrollController> _surahTabScrollControllers = {};

  @override
  void initState() {
    super.initState();
    
    // Group references by surah number
    final references = widget.prophet.references ?? [];
    for (final ref in references) {
      if (!_surahVersesMap.containsKey(ref.surah)) {
        _surahVersesMap[ref.surah] = [];
        _surahReferenceMap[ref.surah] = ref; // Store reference for verse_data access
      }
      _surahVersesMap[ref.surah]!.addAll(ref.verses);
    }
    
    // Remove duplicates and sort verses for each surah
    for (final surah in _surahVersesMap.keys) {
      _surahVersesMap[surah] = _surahVersesMap[surah]!.toSet().toList()..sort();
    }
    
    _surahNumbers = _surahVersesMap.keys.toList()..sort();
    
    // Initialize tab controller: 1 for "All" + number of surahs
    _tabController = TabController(length: _surahNumbers.length + 1, vsync: this);
    
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
      1: 'Ал-Фотиҳа',
      2: 'Ал-Бақара',
      3: 'Оли Имрон',
      4: 'Ан-Нисо',
      5: 'Ал-Маида',
      6: 'Ал-Анъом',
      7: 'Ал-Аъроф',
      8: 'Ал-Анфол',
      9: 'Ат-Тавба',
      10: 'Юнус',
      11: 'Ҳуд',
      12: 'Юсуф',
      13: 'Ар-Раъд',
      14: 'Иброҳим',
      15: 'Ал-Ҳиҷр',
      16: 'Ан-Наҳл',
      17: 'Ал-Исро',
      18: 'Ал-Каҳф',
      19: 'Марям',
      20: 'Тоҳо',
      21: 'Ал-Анбиё',
      22: 'Ал-Ҳаҷҷ',
      23: 'Ал-Муъминун',
      24: 'Ан-Нур',
      25: 'Ал-Фурқон',
      26: 'Аш-Шуъаро',
      27: 'Ан-Намл',
      28: 'Ал-Қасас',
      29: 'Ал-Анкабут',
      30: 'Ар-Рум',
      31: 'Луқмон',
      32: 'Ас-Саҷда',
      33: 'Ал-Аҳзоб',
      34: 'Сабаъ',
      35: 'Фотир',
      36: 'Ясин',
      37: 'Ас-Соффот',
      38: 'Сод',
      39: 'Аз-Зумар',
      40: 'Ғофир',
      41: 'Фуссилат',
      42: 'Аш-Шуро',
      43: 'Аз-Зухруф',
      44: 'Ад-Духон',
      45: 'Ал-Ҷосия',
      46: 'Ал-Аҳқоф',
      47: 'Муҳаммад',
      48: 'Ал-Фатҳ',
      49: 'Ал-Ҳуҷурот',
      50: 'Қоф',
      51: 'Аз-Зориёт',
      52: 'Ат-Тур',
      53: 'Ан-Наҷм',
      54: 'Ал-Қамар',
      55: 'Ар-Раҳмон',
      56: 'Ал-Воқиа',
      57: 'Ал-Ҳадид',
      58: 'Ал-Муҷодала',
      59: 'Ал-Ҳашр',
      60: 'Ал-Мумтаҳана',
      61: 'Ас-Сафф',
      62: 'Ал-Ҷумъа',
      63: 'Ал-Мунофиқун',
      64: 'Ат-Тағобун',
      65: 'Ат-Талақ',
      66: 'Ат-Таҳрим',
      67: 'Ал-Мулк',
      68: 'Ал-Қалам',
      69: 'Ал-Ҳоққа',
      70: 'Ал-Маъориҷ',
      71: 'Нуҳ',
      72: 'Ал-Ҷинн',
      73: 'Ал-Муззаммил',
      74: 'Ал-Муддассир',
      75: 'Ал-Қиёма',
      76: 'Ал-Инсон',
      77: 'Ал-Мурсалот',
      78: 'Ан-Набоъ',
      79: 'Ан-Назиъот',
      80: 'Абаса',
      81: 'Ат-Таквир',
      82: 'Ал-Инфитор',
      83: 'Ал-Мутоффифин',
      84: 'Ал-Иншиқоқ',
      85: 'Ал-Буруҷ',
      86: 'Ат-Ториқ',
      87: 'Ал-Аъло',
      88: 'Ал-Ғошия',
      89: 'Ал-Фаҷр',
      90: 'Ал-Балад',
      91: 'Аш-Шамс',
      92: 'Ал-Лайл',
      93: 'Аз-Зуҳо',
      94: 'Ал-Иншироҳ',
      95: 'Ат-Тин',
      96: 'Ал-Алақ',
      97: 'Ал-Қадр',
      98: 'Ал-Байина',
      99: 'Аз-Залзала',
      100: 'Ал-Одиёт',
      101: 'Ал-Қориа',
      102: 'Ат-Такосур',
      103: 'Ал-Аср',
      104: 'Ал-Ҳумаза',
      105: 'Ал-Фил',
      106: 'Қурайш',
      107: 'Ал-Маъун',
      108: 'Ал-Кавсар',
      109: 'Ал-Кофирун',
      110: 'Ан-Наср',
      111: 'Ал-Масад',
      112: 'Ал-Ихлос',
      113: 'Ал-Фалақ',
      114: 'Ан-Нас',
    };
    
    return surahNames[surahNumber] ?? 'Сураи $surahNumber';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if there are references
    final references = widget.prophet.references ?? [];
    if (references.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.prophet.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/prophets');
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
              GoRouter.of(context).go('/prophets');
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
            final ref = _surahReferenceMap[surahNum];
            return _buildSurahTab(surahNum, _surahVersesMap[surahNum]!, ref);
          }),
        ],
      ),
      bottomNavigationBar: _buildBottomMiniPlayer(),
    );
  }

  Widget _buildBottomMiniPlayer() {
    return Consumer(
      builder: (context, ref, child) {
        final audio = QuranAudioService();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return StreamBuilder<PlaybackStateInfo>(
          stream: audio.uiStateStream,
          builder: (context, snapshot) {
            final info = snapshot.data;
            final hasActive = (info?.currentUrl != null) &&
                ((info?.processingState ?? ProcessingState.idle) != ProcessingState.idle);
            if (!hasActive) {
              return const SizedBox.shrink();
            }

            final activeSurah = info!.currentSurahNumber ?? 1;
            final activeVerse = info.currentVerseNumber; // null -> surah mode
            final isPlaying = info.isPlaying;
            final position = info.position;
            final duration = info.duration ?? Duration.zero;
            final progress = duration.inMilliseconds > 0 
                ? position.inMilliseconds / duration.inMilliseconds 
                : 0.0;
            
            // Get edition from the active surah's controller, or use default
            final edition = ref.read(surahControllerProvider(activeSurah)).state.audioEdition;

            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    Container(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        minHeight: 3,
                      ),
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Surah/Verse info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                FutureBuilder<String>(
                                  future: _getSurahNameForPlayer(ref, activeSurah),
                                  builder: (context, snapshot) {
                                    final surahName = snapshot.data ?? 'Сураи $activeSurah';
                                    final title = activeVerse == null
                                        ? surahName
                                        : '$surahName - Ояти $activeVerse';
                                    return Text(
                                      title,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                                const SizedBox(height: 2),
                                // Time info
                                Row(
                                  children: [
                                    Text(
                                      _formatDurationForPlayer(position),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      ' / ${_formatDurationForPlayer(duration)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Previous button
                          IconButton(
                            onPressed: () async {
                              if (activeVerse != null) {
                                await audio.playPreviousVerse(edition: edition);
                              } else {
                                await audio.playPreviousSurah(edition: edition);
                              }
                            },
                            icon: Icon(
                              Icons.skip_previous,
                              color: colorScheme.onSurface,
                              size: 22,
                            ),
                            iconSize: 22,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: 'Гузашта',
                          ),
                          // Play/Pause button (between previous and next)
                          IconButton(
                            onPressed: () async {
                              await audio.togglePlayPause(
                                surahNumber: activeSurah,
                                verseNumber: activeVerse,
                                edition: edition,
                              );
                            },
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: colorScheme.onSurface,
                              size: 22,
                            ),
                            iconSize: 22,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: isPlaying ? 'Ист кардан' : 'Пахш кардан',
                          ),
                          // Next button
                          IconButton(
                            onPressed: () async {
                              if (activeVerse != null) {
                                await audio.playNextVerse(edition: edition);
                              } else {
                                await audio.playNextSurah(edition: edition);
                              }
                            },
                            icon: Icon(
                              Icons.skip_next,
                              color: colorScheme.onSurface,
                              size: 22,
                            ),
                            iconSize: 22,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: 'Оянда',
                          ),
                          const SizedBox(width: 4),
                          // Close button
                          IconButton(
                            onPressed: () async {
                              await audio.stop();
                            },
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              size: 20,
                            ),
                            iconSize: 20,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Пӯшидан',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getSurahNameForPlayer(WidgetRef ref, int surahNumber) async {
    try {
      final surahs = await ref.read(surahLocalDataSourceProvider).getAllSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      return surah.nameTajik;
    } catch (e) {
      return 'Сураи $surahNumber';
    }
  }

  String _formatDurationForPlayer(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAllVersesTab() {
    return ListView.builder(
      controller: _allTabScrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _surahNumbers.length,
      itemBuilder: (context, index) {
        final surahNumber = _surahNumbers[index];
        final verseNumbers = _surahVersesMap[surahNumber]!;
        final ref = _surahReferenceMap[surahNumber];
        
        return _SurahVersesSection(
          surahNumber: surahNumber,
          verseNumbers: verseNumbers,
          reference: ref,
          isNested: true, // This is inside a ListView, so use Column
          onVerseTap: (surahNum, verseNum) {
            context.push('/surah/$surahNum/verse/$verseNum');
          },
        );
      },
    );
  }

  Widget _buildSurahTab(int surahNumber, List<int> verseNumbers, ProphetReferenceModel? reference) {
    // Get or create scroll controller for this surah tab
    if (!_surahTabScrollControllers.containsKey(surahNumber)) {
      _surahTabScrollControllers[surahNumber] = ScrollController();
    }
    
    return _SurahVersesSection(
      surahNumber: surahNumber,
      verseNumbers: verseNumbers,
      reference: reference,
      isNested: false, // This is the main scrollable, so use ListView
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
  final ProphetReferenceModel? reference; // For pre-populated verse data
  final bool isNested; // If true, use Column; if false, use ListView
  final ScrollController? scrollController; // To preserve scroll position
  final void Function(int surahNum, int verseNum) onVerseTap;

  const _SurahVersesSection({
    required this.surahNumber,
    required this.verseNumbers,
    this.reference,
    this.isNested = false,
    this.scrollController,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahProvider(surahNumber));

    // Use only pre-populated data from Prophets.json
    if (reference?.verseData == null || reference!.verseData!.isEmpty) {
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
          // Simple verse widgets
          ...verseNumbers.map((verseNum) {
            final verseData = reference!.verseData![verseNum.toString()];
            if (verseData == null) {
              return const SizedBox.shrink();
            }
            
            return _SimpleVerseWidget(
              surahNumber: surahNumber,
              verseNumber: verseNum,
              arabic: verseData.arabic.trim(),
              tajik: verseData.tajik.isNotEmpty ? verseData.tajik : '',
              transliteration: verseData.transliteration,
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
