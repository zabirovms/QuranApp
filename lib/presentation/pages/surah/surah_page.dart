import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quran_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../widgets/quran/verse_item.dart';
import '../../widgets/quran/audio_player_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
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
  bool _showAudioPlayer = false;
  String _translationLang = 'tajik';
  final ScrollController _scrollController = ScrollController();
  bool _isSurahDescriptionExpanded = false;
  int? _openTafsirIndex; // ensures only one tafsir is open
  int? _highlightedVerseIndex; // for highlighting specific verse

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

    // Handle initial verse navigation
    if (widget.initialVerseNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(widget.initialVerseNumber!);
      });
    }
  }

  void _scrollToVerse(int verseNumber) async {
    // Wait for verses to load
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    final versesAsync = ref.read(versesProvider(widget.surahNumber));
    versesAsync.whenData((verses) {
      if (verses.isNotEmpty) {
        // Find the verse index
        final verseIndex = verses.indexWhere((v) => v.verseNumber == verseNumber);
        if (verseIndex != -1) {
          setState(() {
            _highlightedVerseIndex = verseIndex;
          });

          // Calculate scroll position (approximate)
          final itemHeight = 200.0; // Approximate height per verse
          final targetOffset = (verseIndex * itemHeight) - 100; // Offset for better visibility
          
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahProvider(widget.surahNumber));
    final versesAsync = ref.watch(versesProvider(widget.surahNumber));
    final controller = ref.watch(surahControllerProvider(widget.surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (surah) => Text(surah?.nameTajik ?? 'Сураи ${widget.surahNumber}'),
          loading: () => Text('Сураи ${widget.surahNumber}'),
          error: (_, __) => Text('Сураи ${widget.surahNumber}'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            } catch (e) {
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
      body: CustomScrollView(
        controller: _scrollController,
         slivers: [
          if (_showAudioPlayer)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AudioPlayerWidget(
                  surahNumber: widget.surahNumber,
                  isCompact: true,
                  onClose: () {
                    setState(() {
                      _showAudioPlayer = false;
                    });
                  },
                ),
              ),
            ),

          // Surah Info
          surahAsync.when(
            data: (surah) {
              if (surah == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

               return SliverToBoxAdapter(
                 child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        surah.nameArabic,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        surah.nameTajik,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah.nameEnglish,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Chip(
                             label: Text('${surah.versesCount} оят'),
                             backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                           ),
                           const SizedBox(width: 8),
                           Chip(
                             label: Text(surah.revelationType == 'Meccan' ? 'Маккӣ' : 'Мадинӣ'),
                             backgroundColor: surah.revelationType == 'Meccan' 
                                 ? Colors.green.withOpacity(0.1)
                                 : Colors.blue.withOpacity(0.1),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       // Actions moved from AppBar to Surah header
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           PopupMenuButton<String>(
                             icon: const Icon(Icons.record_voice_over),
                             tooltip: 'Қорӣ',
                             onSelected: (edition) {
                               ref.read(surahControllerProvider(widget.surahNumber)).changeAudioEdition(
                                 surahNumber: widget.surahNumber,
                                 audioEdition: edition,
                               );
                               Future(() async {
                                 final settings = SettingsService();
                                 await settings.init();
                                 await settings.setAudioEdition(edition);
                               });
                             },
                             itemBuilder: (context) => const [
                               PopupMenuItem(value: 'ar.alafasy', child: Text('Мишарӣ Алъафасӣ')),
                               PopupMenuItem(value: 'ar.husary', child: Text('Маъмуди Халил Ҳусарӣ')),
                               PopupMenuItem(value: 'ar.abdulbasit', child: Text('Абдул Босит')),
                               PopupMenuItem(value: 'ar.minshawi', child: Text('Миншовӣ')),
                             ],
                           ),
                           const SizedBox(width: 8),
                           IconButton(
                             icon: const Icon(Icons.audiotrack),
                             tooltip: 'Плеери садо',
                             onPressed: () {
                               setState(() {
                                 _showAudioPlayer = !_showAudioPlayer;
                               });
                             },
                           ),
                           const SizedBox(width: 8),
                           IconButton(
                             icon: const Icon(Icons.share),
                             tooltip: 'Мубодила',
                             onPressed: () async {
                               await Share.share('Reading ${surah.nameEnglish} (${surah.number})');
                             },
                           ),
                         ],
                       ),
                      const SizedBox(height: 8),
                       if ((surah.description ?? '').trim().isNotEmpty)
                         Container(
                           margin: const EdgeInsets.only(top: 8),
                           decoration: BoxDecoration(
                             color: Colors.transparent,
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               InkWell(
                                 onTap: () {
                                   setState(() {
                                     _isSurahDescriptionExpanded = !_isSurahDescriptionExpanded;
                                   });
                                 },
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     const Icon(Icons.info_outline),
                                     const SizedBox(width: 8),
                                     Text(
                                       'Маълумот',
                                       style: Theme.of(context).textTheme.titleMedium,
                                     ),
                                     const SizedBox(width: 8),
                                     Icon(_isSurahDescriptionExpanded ? Icons.expand_less : Icons.expand_more),
                                   ],
                                 ),
                               ),
                               if (_isSurahDescriptionExpanded)
                                 GestureDetector(
                                   behavior: HitTestBehavior.opaque,
                                   onTap: () {
                                     setState(() {
                                       _isSurahDescriptionExpanded = false;
                                     });
                                   },
                                   child: Padding(
                                     padding: const EdgeInsets.only(top: 8),
                                     child: Align(
                                       alignment: Alignment.centerLeft,
                                       child: Text(
                                         surah.description!.trim(),
                                         textAlign: TextAlign.start,
                                         style: Theme.of(context).textTheme.bodyMedium,
                                       ),
                                     ),
                                   ),
                                 ),
                             ],
                           ),
                         ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: LoadingWidget(height: 120),
              ),
            ),
            error: (error, stackTrace) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

            // Marker chips removed as requested

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

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final verse = verses[index];
                      final arabicText = (index < controller.state.arabic.length)
                          ? controller.state.arabic[index].text
                          : verse.arabicText;
                       // audioUrl unused in this view; computation removed
                      final wbw = controller.state.wordByWord[verse.uniqueKey]
                          ?.map((w) => {'arabic': w.arabic, 'meaning': w.farsi ?? ''})
                          .toList();
                    return VerseItem(
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
                      isHighlighted: controller.state.currentAyahIndex == index || _highlightedVerseIndex == index,
                      isTafsirOpen: _openTafsirIndex == index,
                      onToggleTafsir: () {
                        setState(() {
                          _openTafsirIndex = _openTafsirIndex == index ? null : index;
                        });
                      },
                      onPlayAudio: () {
                        final currentEdition = controller.state.audioEdition;
                        QuranAudioService().playVerse(widget.surahNumber, verse.verseNumber, edition: currentEdition);
                        ref.read(surahControllerProvider(widget.surahNumber)).setCurrentAyahIndex(index);
                      },
                      onBookmark: () async {
                        final bm = BookmarkModel(
                          id: 0,
                          userId: 'default_user',
                          verseId: verse.id,
                          verseKey: '${widget.surahNumber}:${verse.verseNumber}',
                          surahNumber: widget.surahNumber,
                          verseNumber: verse.verseNumber,
                          arabicText: arabicText,
                          tajikText: verse.tajikText,
                          surahName: surahAsync.maybeWhen(data: (s) => s?.nameTajik ?? '', orElse: () => ''),
                          createdAt: DateTime.now(),
                        );
                        try {
                          await ref.read(bookmarkUseCaseProvider).addBookmark(bm);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Оят ба захираҳо илова карда шуд'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Хатоги дар захира кардан: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                    );
                    },
                    childCount: verses.length,
                  ),
                ),
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
    );
  }

  // Removed jump scrolling helper (no jump navigator)

  // Removed marker navigation (juz, hizb, ruku, manzil, page)

  void _showDisplaySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Танзимоти намоиш',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Translation Language
                ListTile(
                  title: const Text('Забони тарҷума'),
                  subtitle: Text(_getTranslationLanguageName(_translationLang)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showTranslationLanguageDialog(context, setModalState);
                  },
                ),
                
                // Show Transliteration
                SwitchListTile(
                  title: const Text('Намоиши транслитератсия'),
                  subtitle: const Text('Транслитератсияи арабӣ нишон дода шавад'),
                  value: _showTransliteration,
                  onChanged: (value) {
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
                
                // Tafsir toggle removed; handled per-verse only
                
                // Word by Word Mode
                SwitchListTile(
                  title: const Text('Ҳолати калима ба калима'),
                  subtitle: const Text('Тарҷума калима ба калима нишон дода шавад'),
                  value: _isWordByWordMode,
                  onChanged: (value) {
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
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Тайёр'),
                  ),
                ),
              ],
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
}

// JumpChip removed with marker navigation