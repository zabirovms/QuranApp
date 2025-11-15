import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../providers/quran_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../widgets/audio_player_controls.dart';
import '../../widgets/translation_selection_dialog.dart';
import '../../widgets/quran/verse_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../core/constants/app_constants.dart';
import 'package:share_plus/share_plus.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? initialVerseNumber;

  const SurahPage({
    super.key,
    required this.surahNumber,
    this.initialVerseNumber,
  });

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  bool _showTransliteration = false;
  bool _isWordByWordMode = false;
  bool _showOnlyArabic = false;
  String _translationLang = AppConstants.defaultLanguage;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isSurahDescriptionExpanded = false;
  int? _openTafsirIndex; // ensures only one tafsir is open
  int? _highlightedVerseIndex; // for highlighting specific verse
  StreamSubscription<PlaybackStateInfo>? _audioSub; // listen for verse changes
  int? _lastAutoScrolledVerse;
  int? _lastNavigatedSurah; // prevent duplicate navigations
  int? _activeActionsIndex; // controls verse action row visibility
  bool _hasHighlightedInitialVerse = false; // track if initial verse has been highlighted

  @override
  void initState() {
    super.initState();
    Future(() async {
      try {
        final s = SettingsService();
        await s.init();
        setState(() {
          _showTransliteration = s.getShowTransliteration();
          _isWordByWordMode = s.getWordByWordMode();
          _showOnlyArabic = s.getShowOnlyArabic();
          _translationLang = s.getTranslationLanguage();
        });
        // Sync audio edition from global settings into the surah controller
        final edition = s.getAudioEdition();
        if (mounted) {
          ref.read(surahControllerProvider(widget.surahNumber)).changeAudioEdition(
                surahNumber: widget.surahNumber,
                audioEdition: edition,
              );
        }
      } catch (_) {
        // Fallback to defaults if settings not ready
      }
    });
    // Note: initialScrollIndex handles initial scrolling, so _handleInitialScroll is not needed
    // But we'll keep it as a fallback for highlighting
    if (widget.initialVerseNumber != null) {
      _hasHighlightedInitialVerse = false; // Will be set to true after first highlight
    }

    // Auto-scroll to the currently playing verse when playback changes
    final audio = QuranAudioService();
    _audioSub = audio.uiStateStream.listen((info) {
      if (!mounted) return;
      final isThisSurah = info.currentSurahNumber == widget.surahNumber;
      final verse = info.currentVerseNumber;
      // Auto-scroll to currently playing verse within this surah
      if (isThisSurah && verse != null) {
        if (_lastAutoScrolledVerse == verse) return;
        _lastAutoScrolledVerse = verse;
        // Use a small delay to ensure data is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToVerse(verse);
          }
        });
      }

      // If playback context switched to a different surah, navigate there
      final targetSurah = info.currentSurahNumber;
      if (targetSurah != null && targetSurah != widget.surahNumber && _lastNavigatedSurah != targetSurah) {
        _lastNavigatedSurah = targetSurah;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToSurah(targetSurah);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    super.dispose();
  }

  void _showVerseAudioController(int verseNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVerseAudioController(verseNumber),
    );
  }

  Widget _buildVerseAudioController(int verseNumber) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use shared audio service via controls; no local usage needed here
    final currentEdition = ref.read(surahControllerProvider(widget.surahNumber)).state.audioEdition;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Verse info - minimal
            Row(
              children: [
                Text(
                  'Ояти ${verseNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Minimal reusable audio controls
            AudioPlayerControls(
              surahNumber: widget.surahNumber,
              verseNumber: verseNumber,
              edition: currentEdition,
              compact: false,
              showPrevNext: true,
            ),
          ],
        ),
      ),
    );
  }

  // Calculate initial scroll index for ScrollablePositionedList
  int? _calculateInitialScrollIndex(List<VerseModel> verses) {
    if (widget.initialVerseNumber == null || verses.isEmpty) {
      return null;
    }
    
    // Find the verse index in the verses list
    final verseIndex = verses.indexWhere((v) => v.verseNumber == widget.initialVerseNumber);
    if (verseIndex == -1) {
      return null;
    }
    
    // Header is at index 0, Bismillah is at index 1 (if exists)
    final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
    final scrollIndex = hasBismillah ? verseIndex + 2 : verseIndex + 1;
    
    return scrollIndex;
  }

  // Note: _handleInitialScroll removed - using initialScrollIndex instead

  void _scrollToVerse(int verseNumber) {
    // Wait for verses to be available, then scroll
    final versesAsync = ref.read(versesProvider(widget.surahNumber));
    
    if (versesAsync.hasValue && versesAsync.value!.isNotEmpty) {
      _performScrollToVerse(versesAsync.value!, verseNumber);
    } else {
      // Wait for data to load
      versesAsync.whenData((verses) {
        if (verses.isNotEmpty && mounted) {
          _performScrollToVerse(verses, verseNumber);
        }
      });
    }
  }
  
  void _performScrollToVerse(List<dynamic> verses, int verseNumber) {
    // Find the verse index
    final verseIndex = verses.indexWhere((v) => v.verseNumber == verseNumber);
    if (verseIndex != -1) {
      // Header and Bismillah are at indices 0 and 1 (if bismillah exists)
      // So verse index needs to be offset by 2 (header + bismillah) or 1 (just header)
      final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
      final scrollIndex = hasBismillah ? verseIndex + 2 : verseIndex + 1;
      
      // Use ItemScrollController to scroll to the verse index, positioned slightly above center
      // alignment: 0.0 = top, 0.5 = center, 1.0 = bottom
      // Using 0.4 to position verse slightly above center, showing part of previous verse
      _itemScrollController.scrollTo(
        index: scrollIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position verse slightly above center, showing part of previous verse
      );
      
      // Highlight the verse (use original verse index for highlighting)
      setState(() {
        _highlightedVerseIndex = verseIndex;
      });
      
      // Remove highlight after 1.5 seconds (shorter duration)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _highlightedVerseIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahProvider(widget.surahNumber));
    final versesAsync = ref.watch(versesProvider(widget.surahNumber));
    final controller = ref.watch(surahControllerProvider(widget.surahNumber));

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            setState(() {
              if (_isSurahDescriptionExpanded) {
                _isSurahDescriptionExpanded = false;
              }
              _activeActionsIndex = null; // hide any open verse actions when tapping anywhere
            });
          },
          child: PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (!didPop) {
                // Handle device back button
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  // If no history, go to quran page (surahs list) instead of main menu
                  context.go('/quran');
                }
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: surahAsync.when(
                  data: (surah) => Text(
                    surah != null ? 'Сураи ${surah.nameTajik}' : 'Сураи ${widget.surahNumber}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  loading: () => Text('Сураи ${widget.surahNumber}'),
                  error: (_, __) => Text('Сураи ${widget.surahNumber}'),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // Check if we can pop (normal back navigation)
                    if (GoRouter.of(context).canPop()) {
                      GoRouter.of(context).pop();
                    } else {
                      // If no history, go to quran page (surahs list) instead of main menu
                      context.go('/quran');
                    }
                  },
                ),
                actions: [
                  // Navigation button - opens dialog
                  IconButton(
                    icon: const Icon(Icons.navigation),
                    onPressed: () => _showNavigationDialog(context),
                    tooltip: 'Навигатсия',
                  ),
                  // Bookmark icon
                  Consumer(
                    builder: (context, ref, child) {
                      final userId = ref.watch(currentUserIdProvider);
                      final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
                      final hasBookmarks = bookmarkState.bookmarks.isNotEmpty;
                      
                      return IconButton(
                        icon: Icon(hasBookmarks ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: () {
                          context.push('/bookmarks');
                        },
                        tooltip: 'Захираҳо',
                      );
                    },
                  ),
                ],
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _activeActionsIndex = null;
                });
              },
              onHorizontalDragEnd: (details) {
                // Swipe left to go to next surah
                if (details.primaryVelocity! > 0 && widget.surahNumber > 1) {
                  _navigateToSurah(widget.surahNumber - 1);
                }
                // Swipe right to go to previous surah
                else if (details.primaryVelocity! < 0 && widget.surahNumber < 114) {
                  _navigateToSurah(widget.surahNumber + 1);
                }
              },
              child: versesAsync.when(
                data: (verses) {
                  if (verses.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'Оятҳо ёфт нашуд',
                      message: 'Дар ҳоли ҳозир ҳеҷ ояте дар ин сура нест.',
                      icon: Icons.menu_book,
                    );
                  }

                  final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
                  // Total items: 1 (header) + 1 (bismillah if exists) + verses.length
                  final totalItems = hasBismillah ? verses.length + 2 : verses.length + 1;

                  return Consumer(
                    builder: (context, ref, child) {
                      final userId = ref.watch(currentUserIdProvider);
                      final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
                      
                      return surahAsync.when(
                        data: (surah) {
                          // Calculate initial scroll index if initialVerseNumber is provided
                          final initialScrollIndex = _calculateInitialScrollIndex(verses);
                          
                          // Highlight the verse if initialVerseNumber is provided (only once)
                          if (initialScrollIndex != null && !_hasHighlightedInitialVerse) {
                            final verseIndex = verses.indexWhere((v) => v.verseNumber == widget.initialVerseNumber);
                            if (verseIndex != -1) {
                              _hasHighlightedInitialVerse = true; // Mark as highlighted immediately to prevent re-triggering
                              // Use a small delay to ensure the list is rendered
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  setState(() {
                                    _highlightedVerseIndex = verseIndex;
                                  });
                                  // Remove highlight after 1.5 seconds
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    if (mounted) {
                                      setState(() {
                                        _highlightedVerseIndex = null;
                                      });
                                    }
                                  });
                                }
                              });
                            }
                          }
                          
                          return ScrollablePositionedList.builder(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            initialScrollIndex: initialScrollIndex ?? 0,
                            itemCount: totalItems,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemBuilder: (context, index) {
                              // Index 0: Header
                              if (index == 0) {
                                if (surah == null) return const SizedBox.shrink();
                                return _buildModernSurahHeader(context, surah, verses);
                              }
                              
                              // Index 1: Bismillah (if exists)
                              if (index == 1 && hasBismillah) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Center(
                                    child: Container(
                                      height: 80,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: SvgPicture.asset(
                                            'assets/images/bismillah.svg',
                                            height: 140,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              // Index 2+ (or 1+ if no bismillah): Verses
                              final verseIndex = hasBismillah ? index - 2 : index - 1;
                              if (verseIndex < 0 || verseIndex >= verses.length) {
                                return const SizedBox.shrink();
                              }
                              
                              final verse = verses[verseIndex];
                                // Use only local Arabic text (Bismillah removed) instead of remote API text
                                final arabicText = verse.arabicText;
                                final wbw = controller.state.wordByWord[verse.uniqueKey]
                                    ?.map((w) => {'arabic': w.arabic, 'meaning': w.farsi ?? ''})
                                    .toList();
                                
                                // Check if verse is bookmarked
                                final isBookmarked = bookmarkState.bookmarkStatus[verse.uniqueKey] ?? false;
                                
                                final audio = QuranAudioService();
                                final edition = ref.read(surahControllerProvider(widget.surahNumber)).state.audioEdition;
                                return StreamBuilder<PlaybackStateInfo>(
                                  stream: audio.uiStateStream,
                                  builder: (context, snap) {
                                    final info = snap.data;
                                    final isPlayingThis = (info?.currentSurahNumber == widget.surahNumber &&
                                        info?.currentVerseNumber == verse.verseNumber);
                                    return VerseItem(
                                      verse: verse.copyWith(arabicText: arabicText),
                                      showTransliteration: _showTransliteration && !_showOnlyArabic,
                                      showTafsir: false, // per-verse control
                                      isWordByWordMode: _isWordByWordMode,
                                      wordByWordTokens: wbw,
                                      showOnlyArabic: _showOnlyArabic,
                                      translationTextOverride: () {
                                        switch (_translationLang) {
                                          case 'tajik':
                                            return verse.tajikText;
                                          case 'tj_2':
                                            if (verse.tj2 == null || verse.tj2!.isEmpty) {
                                              return 'Тарҷумаи "Абуаломуддин (бо тафсир)" барои ин оят мавҷуд нест.';
                                            }
                                            return verse.tj2!;
                                          case 'tj_3':
                                            if (verse.tj3 == null || verse.tj3!.isEmpty) {
                                              return 'Тарҷумаи "Pioneers of Translation Center" барои ин оят мавҷуд нест.';
                                            }
                                            return verse.tj3!;
                                          case 'farsi':
                                            if (verse.farsi == null || verse.farsi!.isEmpty) {
                                              return 'Тарҷумаи "Форсӣ" барои ин оят мавҷуд нест.';
                                            }
                                            return verse.farsi!;
                                          case 'russian':
                                            if (verse.russian == null || verse.russian!.isEmpty) {
                                              return 'Тарҷумаи "Эльмир Кулиев" барои ин оят мавҷуд нест.';
                                            }
                                            return verse.russian!;
                                          default:
                                            return verse.tajikText;
                                        }
                                      }(),
                                      isHighlighted: _highlightedVerseIndex == verseIndex,
                                      isTafsirOpen: _openTafsirIndex == verseIndex,
                                      isBookmarked: isBookmarked,
                                      isPlaying: isPlayingThis,
                                      showExtraActions: true,
                                      onTranslationChanged: (newLang) {
                                        setState(() {
                                          _translationLang = newLang;
                                        });
                                        ref.invalidate(versesProvider(widget.surahNumber));
                                      },
                                      onTap: () {
                                        if (_activeActionsIndex == verseIndex) {
                                          setState(() {
                                            _activeActionsIndex = null;
                                          });
                                        }
                                      },
                                      onToggleActions: () {
                                        setState(() {
                                          _activeActionsIndex = _activeActionsIndex == verseIndex ? null : verseIndex;
                                        });
                                      },
                                      onToggleTafsir: () {
                                        setState(() {
                                          _openTafsirIndex = _openTafsirIndex == verseIndex ? null : verseIndex;
                                        });
                                      },
                                      onPlayAudio: () async {
                                        await audio.togglePlayPause(
                                          surahNumber: widget.surahNumber,
                                          verseNumber: verse.verseNumber,
                                          edition: edition,
                                        );
                                        ref.read(surahControllerProvider(widget.surahNumber)).setCurrentAyahIndex(verseIndex);
                                      },
                                      onBookmark: () async {
                                        final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
                                        final surahName = surahAsync.maybeWhen(
                                          data: (s) => s?.nameTajik ?? '', 
                                          orElse: () => ''
                                        );
                                        
                                        final success = await notifier.toggleBookmark(verse, surahName);
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success 
                                                  ? (isBookmarked ? 'Захира пок карда шуд' : 'Оят ба захирагоҳ илова карда шуд')
                                                  : 'Хатоги дар захира кардан'
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            );
                        },
                        loading: () => const LoadingListWidget(
                          itemCount: 10,
                          itemHeight: 200,
                        ),
                        error: (error, stackTrace) => CustomErrorWidget(
                          title: 'Хатоги дар боргирӣ',
                          message: 'Сураро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                          onRetry: () {
                            ref.invalidate(surahProvider(widget.surahNumber));
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingListWidget(
                  itemCount: 10,
                  itemHeight: 200,
                ),
                error: (error, stackTrace) => CustomErrorWidget(
                  title: 'Хатоги дар боргирӣ',
                  message: 'Оятҳоро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                  onRetry: () {
                    ref.invalidate(versesProvider(widget.surahNumber));
                  },
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomMiniPlayer(),
          ),
        ),
        ),
        // Word-by-word error popup
        if (controller.state.showWordByWordError)
          _buildWordByWordErrorPopup(context, controller),
      ],
    );
  }

  // Removed jump scrolling helper (no jump navigator)

  // Removed marker navigation (juz, hizb, ruku, manzil, page)

  Widget _buildBottomMiniPlayer() {
    final audio = QuranAudioService();
    final edition = ref.read(surahControllerProvider(widget.surahNumber)).state.audioEdition;
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

        final activeSurah = info!.currentSurahNumber ?? widget.surahNumber;
        final activeVerse = info.currentVerseNumber; // null -> surah mode
        final isPlaying = info.isPlaying;
        final position = info.position;
        final duration = info.duration ?? Duration.zero;
        final progress = duration.inMilliseconds > 0 
            ? position.inMilliseconds / duration.inMilliseconds 
            : 0.0;

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
                              future: _getSurahNameForPlayer(activeSurah),
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
  }
  
  Future<String> _getSurahNameForPlayer(int surahNumber) async {
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

  void _showDisplaySettings(BuildContext context) {
    final controller = ref.read(surahControllerProvider(widget.surahNumber));
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Танзимоти намоиш',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Translation Language
                _buildModernSettingTile(
                  context,
                  Icons.translate,
                  'Забони тарҷума',
                  _getTranslationLanguageName(_translationLang),
                  () => _showTranslationLanguageDialog(context, setModalState),
                ),
                
                const SizedBox(height: 16),
                
                // Qari Selection
                _buildModernSettingTile(
                  context,
                  Icons.record_voice_over,
                  'Қори',
                  _getQariName(controller.state.audioEdition),
                  () => _showQariDialog(context, setModalState, controller),
                ),
                
                const SizedBox(height: 16),
                
                // Show Transliteration
                _buildModernSwitchTile(
                  context,
                  Icons.text_fields,
                  'Намоиши транслитератсия',
                  '',
                  _showTransliteration,
                  (value) {
                    setModalState(() {
                      _showTransliteration = value;
                    });
                    setState(() {
                      _showTransliteration = value;
                    });
                    Future(() async {
                      final s = SettingsService();
                      await s.init();
                      await s.setShowTransliteration(value);
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Word by Word Mode
                _buildModernSwitchTile(
                  context,
                  Icons.format_list_bulleted,
                  'Ҳолати калима ба калима',
                  '',
                  _isWordByWordMode,
                  (value) {
                    setModalState(() {
                      _isWordByWordMode = value;
                    });
                    setState(() {
                      _isWordByWordMode = value;
                    });
                    Future(() async {
                      final s = SettingsService();
                      await s.init();
                      await s.setWordByWordMode(value);
                    });
                    
                    // Check if word-by-word is enabled but data is not available
                    if (value && !controller.state.wordByWordAvailable) {
                      controller.showWordByWordError();
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Removed explicit confirm button for a minimal, instant-apply UX
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTranslationLanguageName(String lang) {
    return AppConstants.getTranslationName(lang);
  }


  void _showTranslationLanguageDialog(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => TranslationSelectionDialog(
        currentTranslation: _translationLang,
        surahNumber: widget.surahNumber,
        onTranslationSelected: (newLang) {
          setState(() {
            _translationLang = newLang;
          });
          // Update settings
          Future(() async {
            final s = SettingsService();
            await s.init();
            await s.setTranslationLanguage(newLang);
          });
          // Reload verses to show new translation
          ref.invalidate(versesProvider(widget.surahNumber));
        },
      ),
    );
  }



  void _navigateToSurah(int surahNumber) {
    if (surahNumber >= 1 && surahNumber <= 114) {
      context.go('/surah/$surahNumber');
    }
  }

  void _navigateToVerse(int surahNumber, int verseNumber) {
    if (surahNumber >= 1 && surahNumber <= 114 && verseNumber >= 1) {
      context.go('/surah/$surahNumber/verse/$verseNumber');
    }
  }

  void _showNavigationDialog(BuildContext context) {
    final verseController = TextEditingController();
    final surahsAsync = ref.read(surahsProvider);

    showDialog(
      context: context,
      builder: (context) {
        return surahsAsync.when(
          data: (surahs) {
            return _NavigationDialog(
              currentSurah: widget.surahNumber,
              surahs: surahs,
              verseController: verseController,
              onNavigate: (surahNumber, verseNumber) {
                if (verseNumber != null) {
                  _navigateToVerse(surahNumber, verseNumber);
                } else {
                  _navigateToSurah(surahNumber);
                }
              },
            );
          },
          loading: () => AlertDialog(
            title: const Text('Навигатсия'),
            content: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => AlertDialog(
            title: const Text('Навигатсия'),
            content: const Text('Хатоги дар боргирӣ'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Бекор кардан'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernSettingTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: (subtitle.trim().isEmpty)
            ? null
            : Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildModernSwitchTile(BuildContext context, IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: (subtitle.trim().isEmpty)
            ? null
            : Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getQariName(String qari) {
    switch (qari) {
      case 'ar.alafasy':
        return 'Mishary Alafasy';
      case 'ar.husary':
        return 'Mahmoud Khalil Al-Husary';
      case 'ar.minshawi':
        return 'Muhammad Siddiq Al-Minshawi';
      case 'ar.sudais':
        return 'Abdur-Rahman As-Sudais';
      case 'ar.shuraim':
        return 'Saud Al-Shuraim';
      case 'ar.maher':
        return 'Maher Al-Muaiqly';
      case 'ar.ayyoub':
        return 'Yasser Al-Ayyoub';
      case 'ar.jibreel':
        return 'Ibrahim Al-Jibrin';
      case 'ar.budair':
        return 'Abdullah Al-Budair';
      case 'ar.ghamdi':
        return 'Saad Al-Ghamdi';
      case 'ar.ajamy':
        return 'Ahmad Al-Ajmi';
      case 'ar.matroud':
        return 'Fares Abbad/Matroud';
      case 'ar.rifai':
        return 'Hani Rifai';
      case 'ar.akhdar':
        return 'Ali Al-Hudhaify (Akhdar)';
      case 'ar.hajjaj':
        return 'Hani Al-Refai (Hajjaj)';
      case 'ar.abbad':
        return 'Fares Abbad';
      case 'ar.abdulkareem':
        return 'Abdul Kareem';
      case 'ar.abdulwahed':
        return 'Abdul Wahed';
      case 'ar.dussary':
        return 'Yasser Al-Dossari';
      default:
        return qari;
    }
  }

  void _showQariDialog(BuildContext context, StateSetter setModalState, dynamic controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интихоби қориъ'),
        content: Builder(
          builder: (context) {
            final reciters = QuranAudioService().getAvailableReciters();
            return SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final code in reciters)
                      RadioListTile<String>(
                        title: Text(_getQariName(code)),
                        value: code,
                        groupValue: controller.state.audioEdition,
                        onChanged: (value) {
                          controller.changeAudioEdition(
                            surahNumber: widget.surahNumber,
                            audioEdition: value!,
                          );
                          Future(() async {
                            final settings = SettingsService();
                            await settings.init();
                            await settings.setAudioEdition(value);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWordByWordErrorPopup(BuildContext context, dynamic controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ҳолати калима ба калима дастрас нест',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Интернет пайваст нест. Лутфан интернетро тафтиш кунед ва дубора кӯшиш кунед.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.hideWordByWordError();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Тасдиқ кардан'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.hideWordByWordError();
                          // Reload the surah to try fetching word-by-word data again
                          controller.load(
                            surahNumber: widget.surahNumber,
                            audioEdition: controller.state.audioEdition,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Такрор кӯшиш'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSurahHeader(BuildContext context, SurahModel surah, List<VerseModel>? verses) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimal header: Arabic name, Tajik name, compact player
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surah.nameArabic,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.0,
                    height: 1.1,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Сураи ${surah.nameTajik}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Small play button between surah name and Маълумот
          SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Smallest play button
                StreamBuilder<PlaybackStateInfo>(
                  stream: QuranAudioService().uiStateStream,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isPlayingSurah = info?.currentSurahNumber == surah.number && 
                                         info?.currentVerseNumber == null && 
                                         (info?.isPlaying ?? false);
                    
                    return IconButton(
                      onPressed: () async {
                        final audioService = QuranAudioService();
                        await audioService.togglePlayPause(
                          surahNumber: surah.number,
                          verseNumber: null, // Full surah mode
                          edition: ref.read(surahControllerProvider(widget.surahNumber)).state.audioEdition,
                        );
                      },
                      icon: Icon(
                        isPlayingSurah ? Icons.pause : Icons.play_arrow,
                        color: isPlayingSurah 
                            ? colorScheme.primary 
                            : colorScheme.onSurface,
                        size: 20,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                        maxWidth: 28,
                        maxHeight: 28,
                      ),
                      tooltip: isPlayingSurah ? 'Ист кардан' : 'Пахш кардани сура',
                    );
                  },
                ),
              ],
            ),
          ),

          // 'Маълумот' dropdown toggle (only if exists)
          if ((surah.description ?? '').trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSurahDescriptionExpanded = !_isSurahDescriptionExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Маълумот',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isSurahDescriptionExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colorScheme.primary,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Expanded description - compact (tappable to close)
            if (_isSurahDescriptionExpanded) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSurahDescriptionExpanded = false;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    surah.description!.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactAudioControls(BuildContext context, SurahModel surah, List<VerseModel>? verses) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final audioService = QuranAudioService();
    final currentEdition = ref.read(surahControllerProvider(widget.surahNumber)).state.audioEdition;
    
    return Consumer(
      builder: (context, ref, child) {
        return StreamBuilder<PlayerState>(
          stream: audioService.playerStateStream,
          builder: (context, playerStateSnapshot) {
            final isPlaying = playerStateSnapshot.data?.playing ?? false;
            final isCurrentSurahPlaying = audioService.currentSurahNumber == widget.surahNumber && isPlaying;
            
            return StreamBuilder<Duration>(
              stream: audioService.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                
                return StreamBuilder<Duration?>(
                  stream: audioService.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact controls row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Play/Pause button - smaller
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  if (isCurrentSurahPlaying) {
                                    await audioService.pause();
                                  } else {
                                    await audioService.playSurah(widget.surahNumber, edition: currentEdition);
                                  }
                                },
                                icon: Icon(
                                  isCurrentSurahPlaying ? Icons.pause : Icons.play_arrow,
                                  color: colorScheme.onPrimary,
                                  size: 18,
                                ),
                                iconSize: 18,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Share button - smaller
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  final juzNumber = verses?.isNotEmpty == true 
                                      ? verses!.first.juz ?? 1 
                                      : 1;
                                  
                                  final shareText = 'Сураи ${surah.nameTajik} (Ҷузъи $juzNumber) – ${surah.versesCount} оят\n'
                                      'Тарҷума ва тафсири онро дар барномаи Quran.tj ё вебсайти https://www.quran.tj бихонед.';
                                  
                                  await Share.share(shareText);
                                },
                                icon: Icon(
                                  Icons.share,
                                  color: colorScheme.onSurface,
                                  size: 14,
                                ),
                                tooltip: 'Мубодила',
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Compact progress bar
                        SizedBox(
                          width: 120,
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                ),
                                child: Slider(
                                  value: duration.inMilliseconds > 0
                                      ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
                                      : 0.0,
                                  max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                  onChanged: duration.inMilliseconds > 0
                                      ? (value) async {
                                          await audioService.seekTo(Duration(milliseconds: value.toInt()));
                                        }
                                      : null,
                                  activeColor: colorScheme.primary,
                                  inactiveColor: colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              
                              // Time display - compact
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 9,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompactInfoChip(BuildContext context, String text, Color color, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Navigation dialog widget
class _NavigationDialog extends StatefulWidget {
  final int currentSurah;
  final List<SurahModel> surahs;
  final TextEditingController verseController;
  final void Function(int surahNumber, int? verseNumber) onNavigate;

  const _NavigationDialog({
    required this.currentSurah,
    required this.surahs,
    required this.verseController,
    required this.onNavigate,
  });

  @override
  State<_NavigationDialog> createState() => _NavigationDialogState();
}

class _NavigationDialogState extends State<_NavigationDialog> {
  late int _selectedSurah;
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.currentSurah;
  }

  @override
  void dispose() {
    widget.verseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Навигатсия'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surah selector
            Text(
              'Сура',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (builderContext) {
                return Container(
                  key: _dropdownKey,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Show menu below the button
                      final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
                      final Offset? offset = renderBox?.localToGlobal(Offset.zero);
                      final Size? size = renderBox?.size;
                      
                      if (offset != null && size != null) {
                        showMenu<int>(
                          context: builderContext,
                          position: RelativeRect.fromLTRB(
                            offset.dx,
                            offset.dy + size.height + 4,
                            offset.dx + size.width,
                            offset.dy + size.height + 304,
                          ),
                          items: widget.surahs.map((surah) {
                            return PopupMenuItem<int>(
                              value: surah.number,
                              child: Text('${surah.number}. Сураи ${surah.nameTajik}'),
                            );
                          }).toList(),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              _selectedSurah = value;
                            });
                          }
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedSurah}. Сураи ${widget.surahs.firstWhere((s) => s.number == _selectedSurah).nameTajik}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // Verse input
          Text(
            'Оят (ихтиёрӣ)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.verseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Рақами оят',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Бекор кардан'),
        ),
        FilledButton(
          onPressed: () {
            final verseText = widget.verseController.text.trim();
            if (verseText.isNotEmpty) {
              final verseNumber = int.tryParse(verseText);
              if (verseNumber != null && verseNumber >= 1) {
                Navigator.of(context).pop();
                widget.onNavigate(_selectedSurah, verseNumber);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Рақами оят нодуруст аст')),
                );
              }
            } else {
              Navigator.of(context).pop();
              widget.onNavigate(_selectedSurah, null);
            }
          },
          child: const Text('Рафтан'),
        ),
      ],
    );
  }
}

// JumpChip removed with marker navigation