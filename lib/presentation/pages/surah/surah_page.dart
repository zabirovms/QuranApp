import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/global_quran_page_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../widgets/quran/global_quran_page_view.dart';
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
  late PageController _pageController;
  int _currentPageNumber = 1;
  int _initialPageNumber = 1;
  bool _isLoading = true;

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
      }

      final firstPage = await ref.read(surahFirstPageProvider(widget.surahNumber).future);
      setState(() {
        _initialPageNumber = firstPage;
        _currentPageNumber = firstPage;
        _pageController = PageController(initialPage: 604 - firstPage);
        _isLoading = false;
      });

      if (widget.initialVerseNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToVerse(widget.initialVerseNumber!);
        });
      }
    });
  }

  void _scrollToVerse(int verseNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    try {
      final mushafJsonString = await rootBundle.loadString('assets/data/alquran_cloud_complete_quran.json');
      final mushafData = json.decode(mushafJsonString) as Map<String, dynamic>;
      final dataSection = mushafData['data'] as Map<String, dynamic>;
      final surahsList = dataSection['surahs'] as List<dynamic>;

      if (widget.surahNumber < 1 || widget.surahNumber > surahsList.length) {
        return;
      }

      final surahData = surahsList[widget.surahNumber - 1] as Map<String, dynamic>;
      final ayahsList = surahData['ayahs'] as List<dynamic>;

      for (final ayahJson in ayahsList) {
        final ayahData = ayahJson as Map<String, dynamic>;
        final ayahVerseNumber = ayahData['numberInSurah'] as int;
        
        if (ayahVerseNumber == verseNumber) {
          final versePage = ayahData['page'] as int;
          
          if (_pageController.hasClients) {
            final pageIndex = 604 - versePage;
            _pageController.jumpToPage(pageIndex);
            setState(() {
              _currentPageNumber = versePage;
            });
          }
          break;
        }
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahInfoAsync = ref.watch(surahInfoProvider(widget.surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: surahInfoAsync.when(
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
          surahInfoAsync.maybeWhen(
            data: (surah) => PopupMenuButton<String>(
              icon: const Icon(Icons.record_voice_over),
              tooltip: 'Қорӣ',
              onSelected: (edition) {
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
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : Column(
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
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Саҳифаи $_currentPageNumber аз 604',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.audiotrack),
                            tooltip: 'Плеери садо',
                            onPressed: () {
                              setState(() {
                                _showAudioPlayer = !_showAudioPlayer;
                              });
                            },
                          ),
                          surahInfoAsync.maybeWhen(
                            data: (surah) => IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'Мубодила',
                              onPressed: () async {
                                await Share.share('Reading ${surah?.nameEnglish ?? ''} (${widget.surahNumber})');
                              },
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: true,
                    itemCount: 604,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageNumber = 604 - index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final pageNumber = 604 - index;
                      return GlobalQuranPageView(
                        pageNumber: pageNumber,
                        focusedSurahNumber: widget.surahNumber,
                        showTransliteration: _showTransliteration,
                        isWordByWordMode: _isWordByWordMode,
                        translationLang: _translationLang,
                      );
                    },
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
