import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quran_provider.dart';
import '../../providers/paginated_surah_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/models/bookmark_model.dart';
import '../../widgets/surah/surah_translation_page_view.dart';
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
  bool _isSurahDescriptionExpanded = false;
  late PageController _pageController;
  int _currentPageIndex = 0;
  int _currentMushafPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
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
      }
    });

    if (widget.initialVerseNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(widget.initialVerseNumber!);
      });
    }
  }

  void _scrollToVerse(int verseNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    final verseParams = VerseParams(widget.surahNumber, verseNumber);
    final pageNumberAsync = ref.read(pageNumberForVerseProvider(verseParams));
    
    pageNumberAsync.whenData((mushafPageNumber) async {
      final paginatedData = await ref.read(paginatedSurahDataProvider(widget.surahNumber).future);
      final pageIndex = paginatedData.pages.indexWhere((p) => p.pageNumber == mushafPageNumber);
      
      if (pageIndex != -1 && _pageController.hasClients) {
        _pageController.jumpToPage(pageIndex);
        setState(() {
          _currentPageIndex = pageIndex;
          _currentMushafPage = mushafPageNumber;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahProvider(widget.surahNumber));
    final paginatedDataAsync = ref.watch(paginatedSurahDataProvider(widget.surahNumber));
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
      body: Column(
        children: [
          if (_showAudioPlayer)
            Padding(
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

          surahAsync.when(
            data: (surah) {
              if (surah == null) return const SizedBox.shrink();

              return Container(
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
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingWidget(height: 120),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),

          Expanded(
            child: paginatedDataAsync.when(
              data: (paginatedData) {
                if (paginatedData.pages.isEmpty) {
                  return const Center(
                    child: Text('Ҳеҷ оятҳое ёфт нашуд'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Саҳифаи $_currentMushafPage аз 604',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'Саҳифаи ${_currentPageIndex + 1} аз ${paginatedData.totalPages} дар сура',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        reverse: true,
                        itemCount: paginatedData.pages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPageIndex = index;
                            _currentMushafPage = paginatedData.pages[index].pageNumber;
                          });
                        },
                        itemBuilder: (context, index) {
                          final page = paginatedData.pages[index];
                          return SurahTranslationPageView(
                            surahNumber: widget.surahNumber,
                            pageNumber: page.pageNumber,
                            showTransliteration: _showTransliteration,
                            isWordByWordMode: _isWordByWordMode,
                            translationLang: _translationLang,
                            surahName: surahAsync.maybeWhen(
                              data: (s) => s?.nameTajik ?? '',
                              orElse: () => '',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: LoadingListWidget(
                  itemCount: 10,
                  itemHeight: 200,
                ),
              ),
              error: (error, stackTrace) => Center(
                child: CustomErrorWidget(
                  title: 'Хатоги дар боргирӣ',
                  message: 'Саҳифаҳоро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                  onRetry: () {
                    ref.invalidate(paginatedSurahDataProvider(widget.surahNumber));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                
                ListTile(
                  title: const Text('Забони тарҷума'),
                  subtitle: Text(_getTranslationLanguageName(_translationLang)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showTranslationLanguageDialog(context, setModalState);
                  },
                ),
                
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
                if (value != null) {
                  setModalState(() {
                    _translationLang = value;
                  });
                  setState(() {
                    _translationLang = value;
                  });
                  Future(() async {
                    final s = SettingsService();
                    await s.init();
                    await s.setTranslationLanguage(value);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Форсӣ'),
              value: 'farsi',
              groupValue: _translationLang,
              onChanged: (value) {
                if (value != null) {
                  setModalState(() {
                    _translationLang = value;
                  });
                  setState(() {
                    _translationLang = value;
                  });
                  Future(() async {
                    final s = SettingsService();
                    await s.init();
                    await s.setTranslationLanguage(value);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Русӣ'),
              value: 'russian',
              groupValue: _translationLang,
              onChanged: (value) {
                if (value != null) {
                  setModalState(() {
                    _translationLang = value;
                  });
                  setState(() {
                    _translationLang = value;
                  });
                  Future(() async {
                    final s = SettingsService();
                    await s.init();
                    await s.setTranslationLanguage(value);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
