import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import '../../providers/quran_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../widgets/quran/verse_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/models/verse_model.dart';
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
  String _translationLang = 'tajik';
  final ScrollController _scrollController = ScrollController();
  bool _isSurahDescriptionExpanded = false;
  int? _openTafsirIndex; // ensures only one tafsir is open
  int? _highlightedVerseIndex; // for highlighting specific verse
  
  // Scroll management
  final Map<int, GlobalKey> _verseKeys = {};
  bool _isScrollingToVerse = false;
  int? _pendingScrollVerse;

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
          _translationLang = s.getTranslationLanguage();
        });
      } catch (_) {
        // Fallback to defaults if settings not ready
      }
    });
    _handleInitialScroll();
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
    final audioService = QuranAudioService();
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
            
            // Standard audio controls using just_audio
            StreamBuilder<PlayerState>(
              stream: audioService.playerStateStream,
              builder: (context, playerStateSnapshot) {
                final isCurrentVersePlaying = audioService.isPlayingVerse(widget.surahNumber, verseNumber);
                
                return StreamBuilder<Duration>(
                  stream: audioService.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    
                    return StreamBuilder<Duration?>(
                      stream: audioService.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        
                        return Column(
                          children: [
                            // Progress bar using audio_video_progress_bar
                            ProgressBar(
                              progress: position,
                              total: duration,
                              onSeek: (duration) async {
                                await audioService.seekTo(duration);
                              },
                              progressBarColor: colorScheme.primary,
                              baseBarColor: colorScheme.outline.withOpacity(0.3),
                              thumbColor: colorScheme.primary,
                              barHeight: 4.0,
                              thumbRadius: 8.0,
                            ),
                            
                            // Time display
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Previous button
                                IconButton(
                                  onPressed: () async {
                                    await audioService.playPreviousVerse(edition: currentEdition);
                                  },
                                  icon: const Icon(Icons.skip_previous),
                                  iconSize: 32,
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Play/Pause button
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () async {
                                      if (isCurrentVersePlaying) {
                                        await audioService.pause();
                                      } else {
                                        await audioService.playVerse(widget.surahNumber, verseNumber, edition: currentEdition);
                                      }
                                    },
                                    icon: Icon(
                                      isCurrentVersePlaying ? Icons.pause : Icons.play_arrow,
                                      color: colorScheme.onPrimary,
                                      size: 32,
                                    ),
                                    iconSize: 32,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Next button
                                IconButton(
                                  onPressed: () async {
                                    await audioService.playNextVerse(edition: currentEdition);
                                  },
                                  icon: const Icon(Icons.skip_next),
                                  iconSize: 32,
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Handle initial verse navigation
  void _handleInitialScroll() {
    if (widget.initialVerseNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(widget.initialVerseNumber!);
      });
    }
  }

  void _scrollToVerse(int verseNumber) async {
    if (_isScrollingToVerse) return;
    
    _isScrollingToVerse = true;
    _pendingScrollVerse = verseNumber;
    
    try {
      // Wait for initial render and data loading
      await _waitForContentToLoad();
      
      if (!mounted) return;

      final versesAsync = ref.read(versesProvider(widget.surahNumber));
      versesAsync.whenData((verses) {
        if (verses.isNotEmpty) {
          // Find the verse index
          final verseIndex = verses.indexWhere((v) => v.verseNumber == verseNumber);
          if (verseIndex != -1) {
            _performPreciseScroll(verseIndex, verseNumber);
          }
        }
      });
    } finally {
      _isScrollingToVerse = false;
      _pendingScrollVerse = null;
    }
  }

  Future<void> _waitForContentToLoad() async {
    // Wait for initial data loading
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Wait for verses to be available
    int attempts = 0;
    while (attempts < 30) { // Max 3 seconds
      final versesAsync = ref.read(versesProvider(widget.surahNumber));
      if (versesAsync.hasValue && versesAsync.value!.isNotEmpty) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    // Wait for layout to be complete and widgets to be built
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Ensure scroll controller is ready
    int scrollAttempts = 0;
    while (!_scrollController.hasClients && scrollAttempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      scrollAttempts++;
    }
    
    // Additional wait for GlobalKeys to be ready
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void _performPreciseScroll(int verseIndex, int verseNumber) {
    if (!mounted || !_scrollController.hasClients) return;

    setState(() {
      _highlightedVerseIndex = verseIndex;
    });

    // Try precise scroll using GlobalKey first
    final verseKey = _verseKeys[verseIndex];
    if (verseKey?.currentContext != null) {
      _scrollToWidget(verseKey!.currentContext!);
      
      // Add a verification scroll after a short delay to ensure we reached the target
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _highlightedVerseIndex == verseIndex) {
          _verifyAndCorrectScroll(verseIndex);
        }
      });
    } else {
      // Fallback to calculated position
      _scrollToCalculatedPosition(verseIndex);
      
      // Add verification for calculated position too
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _highlightedVerseIndex == verseIndex) {
          _verifyAndCorrectScroll(verseIndex);
        }
      });
    }

    // Remove highlight after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _highlightedVerseIndex = null;
        });
      }
    });
  }

  void _verifyAndCorrectScroll(int verseIndex) {
    if (!mounted || !_scrollController.hasClients) return;
    
    final verseKey = _verseKeys[verseIndex];
    if (verseKey?.currentContext != null) {
      final RenderBox renderBox = verseKey!.currentContext!.findRenderObject() as RenderBox;
      final RenderBox scrollBox = _scrollController.position.context.storageContext as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero, ancestor: scrollBox);
      
      // If the verse is not visible or not in the right position, correct it
      if (position.dy < 50 || position.dy > 300) {
        Scrollable.ensureVisible(
          verseKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15, // Position 15% from top
        );
      }
    }
  }

  void _scrollToWidget(BuildContext context) {
    try {
      // Use Scrollable.ensureVisible for precise positioning
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.1, // Position the widget 10% from the top of the viewport
      );
    } catch (e) {
      // Fallback to manual calculation if ensureVisible fails
      _scrollToWidgetFallback(context);
    }
  }

  void _scrollToWidgetFallback(BuildContext context) {
    try {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final RenderBox scrollBox = _scrollController.position.context.storageContext as RenderBox;
      
      // Get the position of the verse relative to the scroll view
      final position = renderBox.localToGlobal(Offset.zero, ancestor: scrollBox);
      
      // Calculate the target scroll offset
      final targetOffset = _scrollController.offset + position.dy - 100;
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // If all else fails, use a simple calculated approach
      print('Scroll fallback failed: $e');
    }
  }

  void _scrollToCalculatedPosition(int verseIndex) {
    // Try to get more accurate measurements
    double estimatedHeight = 120.0; // Base height per verse
    
    // Adjust for different modes
    if (_showTransliteration) estimatedHeight += 40;
    if (_isWordByWordMode) estimatedHeight += 80;
    
    // Account for surah info section (more accurate measurement)
    double surahInfoHeight = _isSurahDescriptionExpanded ? 280.0 : 200.0;
    
    // Calculate target position
    final targetOffset = surahInfoHeight + (verseIndex * estimatedHeight) - 50;
    
    // Ensure we don't exceed scroll bounds
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _ensureVerseKeysExist(List<dynamic> verses) {
    for (int i = 0; i < verses.length; i++) {
      if (!_verseKeys.containsKey(i)) {
        _verseKeys[i] = GlobalKey();
      }
    }
  }

  void _handleContentChange() {
    // If we have a pending scroll, retry after content changes
    if (_pendingScrollVerse != null && !_isScrollingToVerse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(_pendingScrollVerse!);
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
        Scaffold(
          appBar: AppBar(
          title: surahAsync.when(
            data: (surah) => Row(
              children: [
                Expanded(
                  child: Text(surah?.nameTajik ?? 'Сураи ${widget.surahNumber}'),
                ),
                const SizedBox(width: 8),
                _buildSurahSelector(context, surah),
              ],
            ),
            loading: () => Row(
              children: [
                Expanded(
                  child: Text('Сураи ${widget.surahNumber}'),
                ),
                const SizedBox(width: 8),
                _buildSurahSelector(context, null),
              ],
            ),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: Text('Сураи ${widget.surahNumber}'),
                ),
                const SizedBox(width: 8),
                _buildSurahSelector(context, null),
              ],
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                context.go('/');
              }
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              context.push('/bookmarks');
            },
            tooltip: 'Захираҳо',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showDisplaySettings(context);
            },
          ),
        ],
      ),
      body: GestureDetector(
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
        child: CustomScrollView(
          controller: _scrollController,
           slivers: [

          // Modern Surah Header with Integrated Audio Controls
          surahAsync.when(
            data: (surah) {
              if (surah == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverToBoxAdapter(
                child: _buildModernSurahHeader(context, surah, versesAsync.value),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: LoadingWidget(height: 200),
              ),
            ),
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomErrorWidget(
                  message: 'Хатогӣ дар боргирӣ: $error',
                  onRetry: () {
                    ref.invalidate(surahProvider(widget.surahNumber));
                  },
                ),
              ),
            ),
          ),

          // Bismillah SVG for surahs except 1 and 9
          if (widget.surahNumber != 1 && widget.surahNumber != 9)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Center(
                  child: Container(
                    height: 80, // still smaller box
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
                          height: 140, // now this actually affects scaling
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Verses List
          versesAsync.when(
            data: (verses) {
              if (verses.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    title: 'Оятҳо ёфт нашуд',
                    message: 'Дар ҳоли ҳозир ҳеҷ ояте дар ин сура нест.',
                    icon: Icons.menu_book,
                  ),
                );
              }

              return Consumer(
                builder: (context, ref, child) {
                  final userId = ref.watch(currentUserIdProvider);
                  final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
                  
                  // Ensure verse keys exist for precise scrolling
                  _ensureVerseKeysExist(verses);
                  
                  // Handle delayed scroll after content changes
                  if (_pendingScrollVerse != null && !_isScrollingToVerse) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToVerse(_pendingScrollVerse!);
                    });
                  }
                  
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final verse = verses[index];
                          // Use only local Arabic text (Bismillah removed) instead of remote API text
                          final arabicText = verse.arabicText;
                          final wbw = controller.state.wordByWord[verse.uniqueKey]
                              ?.map((w) => {'arabic': w.arabic, 'meaning': w.farsi ?? ''})
                              .toList();
                          
                          // Check if verse is bookmarked
                          final isBookmarked = bookmarkState.bookmarkStatus[verse.uniqueKey] ?? false;
                          
                          return Container(
                            key: _verseKeys[index],
                            child: VerseItem(
                            verse: verse.copyWith(arabicText: arabicText),
                            showTransliteration: _showTransliteration,
                            showTafsir: false, // per-verse control
                            isWordByWordMode: _isWordByWordMode,
                            wordByWordTokens: wbw,
                            translationTextOverride: () {
                              switch (_translationLang) {
                                case 'farsi':
                                  return verse.farsi ?? verse.tajikText;
                                case 'russian':
                                  return verse.russian ?? verse.tajikText;
                                default:
                                  return verse.tajikText;
                              }
                            }(),
                            isHighlighted: _highlightedVerseIndex == index,
                            isTafsirOpen: _openTafsirIndex == index,
                            isBookmarked: isBookmarked,
                            isPlaying: QuranAudioService().isPlayingVerse(widget.surahNumber, verse.verseNumber),
                            onToggleTafsir: () {
                              setState(() {
                                _openTafsirIndex = _openTafsirIndex == index ? null : index;
                              });
                              _handleContentChange();
                            },
                            onPlayAudio: () {
                              _showVerseAudioController(verse.verseNumber);
                              ref.read(surahControllerProvider(widget.surahNumber)).setCurrentAyahIndex(index);
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
                                        ? (isBookmarked ? 'Хатбарак хориҷ карда шуд' : 'Оят ба захираҳо илова карда шуд')
                                        : 'Хатоги дар захира кардан'
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                          );
                        },
                        childCount: verses.length,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: LoadingListWidget(
                itemCount: 10,
                itemHeight: 200,
              ),
            ),
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: CustomErrorWidget(
                title: 'Хатоги дар боргирӣ',
                message: 'Оятҳоро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                onRetry: () {
                  ref.invalidate(versesProvider(widget.surahNumber));
                },
              ),
            ),
          ),
        ],
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
                padding: const EdgeInsets.all(24),
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
                  'Қориъ',
                  _getQariName(controller.state.audioEdition),
                  () => _showQariDialog(context, setModalState, controller),
                ),
                
                const SizedBox(height: 16),
                
                // Show Transliteration
                _buildModernSwitchTile(
                  context,
                  Icons.text_fields,
                  'Намоиши транслитератсия',
                  'Транслитератсияи арабӣ нишон дода шавад',
                  _showTransliteration,
                  (value) {
                    setModalState(() {
                      _showTransliteration = value;
                    });
                    setState(() {
                      _showTransliteration = value;
                    });
                    _handleContentChange();
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
                  'Тарҷума калима ба калима нишон дода шавад',
                  _isWordByWordMode,
                  (value) {
                    setModalState(() {
                      _isWordByWordMode = value;
                    });
                    setState(() {
                      _isWordByWordMode = value;
                    });
                    _handleContentChange();
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
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Тайёр'),
                  ),
                ),
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
    switch (lang) {
      case 'tajik':
        return 'Тоҷикӣ';
      case 'farsi':
        return 'Форсӣ';
      case 'russian':
        return 'Русӣ';
      default:
        return 'Тоҷикӣ';
    }
  }

  void _showTranslationLanguageDialog(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интихоби забони тарҷума'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Тоҷикӣ'),
              value: 'tajik',
              groupValue: _translationLang,
              onChanged: (value) {
                setModalState(() {
                  _translationLang = value!;
                });
                setState(() {
                  _translationLang = value!;
                });
                Future(() async {
                  final s = SettingsService();
                  await s.init();
                  await s.setTranslationLanguage(value!);
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Форсӣ'),
              value: 'farsi',
              groupValue: _translationLang,
              onChanged: (value) {
                setModalState(() {
                  _translationLang = value!;
                });
                setState(() {
                  _translationLang = value!;
                });
                Future(() async {
                  final s = SettingsService();
                  await s.init();
                  await s.setTranslationLanguage(value!);
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Русӣ'),
              value: 'russian',
              groupValue: _translationLang,
              onChanged: (value) {
                setModalState(() {
                  _translationLang = value!;
                });
                setState(() {
                  _translationLang = value!;
                });
                Future(() async {
                  final s = SettingsService();
                  await s.init();
                  await s.setTranslationLanguage(value!);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }



  void _navigateToSurah(int surahNumber) {
    if (surahNumber >= 1 && surahNumber <= 114) {
      context.go('/surah/$surahNumber');
    }
  }

  Widget _buildSurahSelector(BuildContext context, dynamic currentSurah) {
    return PopupMenuButton<int>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.surahNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
      tooltip: 'Интихоби сура',
      onSelected: (surahNumber) {
        _navigateToSurah(surahNumber);
      },
      itemBuilder: (context) {
        return List.generate(114, (index) {
          final surahNumber = index + 1;
          final isSelected = surahNumber == widget.surahNumber;
          
          return PopupMenuItem<int>(
            value: surahNumber,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$surahNumber',
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSurahName(surahNumber),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  String _getSurahName(int surahNumber) {
    // This is a simplified version - in a real app you'd want to load this from your data source
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

  Widget _buildModernSettingTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          padding: const EdgeInsets.all(8),
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
        subtitle: Text(
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
      margin: const EdgeInsets.only(bottom: 8),
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
          padding: const EdgeInsets.all(8),
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
        subtitle: Text(
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
        return 'Мишарӣ Алъафасӣ';
      case 'ar.husary':
        return 'Маъмуди Халил Ҳусарӣ';
      case 'ar.abdulbasit':
        return 'Абдул Босит';
      case 'ar.minshawi':
        return 'Миншовӣ';
      default:
        return 'Мишарӣ Алъафасӣ';
    }
  }

  void _showQariDialog(BuildContext context, StateSetter setModalState, dynamic controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интихоби қориъ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Мишарӣ Алъафасӣ'),
              value: 'ar.alafasy',
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
            RadioListTile<String>(
              title: const Text('Маъмуди Халил Ҳусарӣ'),
              value: 'ar.husary',
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
            RadioListTile<String>(
              title: const Text('Абдул Босит'),
              value: 'ar.abdulbasit',
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
            RadioListTile<String>(
              title: const Text('Миншовӣ'),
              value: 'ar.minshawi',
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
                        child: const Text('Тайёр'),
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
        children: [
          // Compact surah info and audio controls in one row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Surah info - compact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic name - smaller
                      Text(
                        surah.nameArabic,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // Tajik and English names - inline, smaller
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              surah.nameTajik,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 1,
                            height: 12,
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              surah.nameEnglish,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Compact info chips - horizontal
                      Row(
                        children: [
                          _buildCompactInfoChip(
                            context,
                            '${surah.versesCount}',
                            colorScheme.primary,
                            Icons.format_list_numbered,
                          ),
                          const SizedBox(width: 6),
                          _buildCompactInfoChip(
                            context,
                            surah.revelationType == 'Meccan' ? 'Маккӣ' : 'Мадинӣ',
                            surah.revelationType == 'Meccan' ? Colors.green : Colors.blue,
                            Icons.location_city,
                          ),
                          const SizedBox(width: 6),
                          _buildCompactInfoChip(
                            context,
                            '${verses?.isNotEmpty == true ? verses!.first.juz ?? 1 : 1}',
                            Colors.orange,
                            Icons.book,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Integrated audio controls - compact
                _buildCompactAudioControls(context, surah, verses),
              ],
            ),
          ),
          
          // Description toggle - only if exists
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
            
            // Expanded description - compact
            if (_isSurahDescriptionExpanded) ...[
              Container(
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

// JumpChip removed with marker navigation