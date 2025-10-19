import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/global_quran_page_provider.dart';
import '../../providers/mushaf_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../widgets/mushaf/mushaf_page_view.dart';
import '../../widgets/quran/global_quran_page_view.dart';
import '../../widgets/quran/audio_player_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

enum ReaderMode { mushaf, translation }

class UnifiedQuranReaderPage extends ConsumerStatefulWidget {
  final int? surahNumber;
  final int? initialPage;
  final int? initialVerseNumber;

  const UnifiedQuranReaderPage({
    super.key,
    this.surahNumber,
    this.initialPage,
    this.initialVerseNumber,
  });

  @override
  ConsumerState<UnifiedQuranReaderPage> createState() => _UnifiedQuranReaderPageState();
}

class _UnifiedQuranReaderPageState extends ConsumerState<UnifiedQuranReaderPage> {
  ReaderMode _currentMode = ReaderMode.mushaf;
  bool _showTransliteration = false;
  bool _isWordByWordMode = false;
  bool _showAudioPlayer = false;
  bool _showControls = true;
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

      int startPage = 1;
      
      if (widget.initialPage != null) {
        startPage = widget.initialPage!;
      } else if (widget.surahNumber != null) {
        final firstPage = await ref.read(surahFirstPageProvider(widget.surahNumber!).future);
        startPage = firstPage;
      }

      setState(() {
        _initialPageNumber = startPage;
        _currentPageNumber = startPage;
        _pageController = PageController(initialPage: startPage - 1);
        _isLoading = false;
      });

      if (widget.initialVerseNumber != null && widget.surahNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToVerse(widget.surahNumber!, widget.initialVerseNumber!);
        });
      }
    });
  }

  void _scrollToVerse(int surahNumber, int verseNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    try {
      final mushafJsonString = await rootBundle.loadString('assets/data/alquran_cloud_complete_quran.json');
      final mushafData = json.decode(mushafJsonString) as Map<String, dynamic>;
      final dataSection = mushafData['data'] as Map<String, dynamic>;
      final surahsList = dataSection['surahs'] as List<dynamic>;

      if (surahNumber < 1 || surahNumber > surahsList.length) {
        return;
      }

      final surahData = surahsList[surahNumber - 1] as Map<String, dynamic>;
      final ayahsList = surahData['ayahs'] as List<dynamic>;

      for (final ayahJson in ayahsList) {
        final ayahData = ayahJson as Map<String, dynamic>;
        final ayahVerseNumber = ayahData['numberInSurah'] as int;
        
        if (ayahVerseNumber == verseNumber) {
          final versePage = ayahData['page'] as int;
          
          if (_pageController.hasClients) {
            final pageIndex = versePage - 1;
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

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == ReaderMode.mushaf 
          ? ReaderMode.translation 
          : ReaderMode.mushaf;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= 604) {
      _pageController.jumpToPage(page - 1);
      setState(() {
        _currentPageNumber = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    if (_currentMode == ReaderMode.mushaf) {
      return _buildMushafMode();
    } else {
      return _buildTranslationMode();
    }
  }

  Widget _buildMushafMode() {
    final mushafDataAsync = ref.watch(mushafDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: mushafDataAsync.when(
        data: (data) => SafeArea(
          child: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: 604,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageNumber = index + 1;
                    });
                  },
                  itemBuilder: (context, index) {
                    final pageNumber = index + 1;
                    return MushafPageView(
                      pageNumber: pageNumber,
                    );
                  },
                ),
                if (_showControls) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildMushafTopBar(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildMushafBottomBar(),
                  ),
                ],
              ],
            ),
          ),
        ),
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(
          message: 'Хато ҳангоми боркунии Мусҳаф',
          onRetry: () => ref.refresh(mushafDataProvider),
        ),
      ),
    );
  }

  Widget _buildTranslationMode() {
    final surahInfoAsync = widget.surahNumber != null
        ? ref.watch(surahInfoProvider(widget.surahNumber!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: surahInfoAsync?.when(
          data: (surah) => Text(surah?.nameTajik ?? 'Қуръон'),
          loading: () => const Text('Қуръон'),
          error: (_, __) => const Text('Қуръон'),
        ) ?? const Text('Қуръон'),
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
            icon: Icon(
              _currentMode == ReaderMode.mushaf 
                  ? Icons.translate 
                  : Icons.auto_stories
            ),
            onPressed: _toggleMode,
            tooltip: _currentMode == ReaderMode.mushaf 
                ? 'Ҳолати тарҷума' 
                : 'Ҳолати Мусҳаф',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showDisplaySettings(context);
            },
          ),
          if (widget.surahNumber != null)
            surahInfoAsync?.maybeWhen(
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
            ) ?? const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          if (_showAudioPlayer && widget.surahNumber != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AudioPlayerWidget(
                surahNumber: widget.surahNumber!,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentMode == ReaderMode.mushaf 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _currentMode == ReaderMode.mushaf 
                              ? AppTheme.primaryColor 
                              : AppTheme.secondaryColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentMode == ReaderMode.mushaf 
                                ? Icons.auto_stories 
                                : Icons.translate,
                            size: 16,
                            color: _currentMode == ReaderMode.mushaf 
                                ? AppTheme.primaryColor 
                                : AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentMode == ReaderMode.mushaf ? 'Мусҳаф' : 'Тарҷума',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _currentMode == ReaderMode.mushaf 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.surahNumber != null)
                      IconButton(
                        icon: const Icon(Icons.audiotrack),
                        tooltip: 'Плеери садо',
                        onPressed: () {
                          setState(() {
                            _showAudioPlayer = !_showAudioPlayer;
                          });
                        },
                      ),
                    if (widget.surahNumber != null)
                      surahInfoAsync?.maybeWhen(
                        data: (surah) => IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Мубодила',
                          onPressed: () async {
                            await Share.share('Reading ${surah?.nameEnglish ?? ''} (${widget.surahNumber})');
                          },
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ) ?? const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 604,
              onPageChanged: (index) {
                setState(() {
                  _currentPageNumber = index + 1;
                });
              },
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
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

  Widget _buildMushafTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          Text(
            'Мусҳаф',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.translate, color: Colors.white),
            onPressed: _toggleMode,
            tooltip: 'Ҳолати тарҷума',
          ),
        ],
      ),
    );
  }

  Widget _buildMushafBottomBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Саҳифа $_currentPageNumber аз 604',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before, color: Colors.white),
                onPressed: _currentPageNumber < 604 ? () => _goToPage(_currentPageNumber + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next, color: Colors.white),
                onPressed: _currentPageNumber > 1 ? () => _goToPage(_currentPageNumber - 1) : null,
              ),
            ],
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
                  title: const Text('Ҳолати намоиш'),
                  subtitle: Text(_currentMode == ReaderMode.mushaf ? 'Мусҳаф' : 'Тарҷума'),
                  trailing: Switch(
                    value: _currentMode == ReaderMode.translation,
                    onChanged: (value) {
                      setModalState(() {
                        _currentMode = value ? ReaderMode.translation : ReaderMode.mushaf;
                      });
                      setState(() {
                        _currentMode = value ? ReaderMode.translation : ReaderMode.mushaf;
                      });
                    },
                  ),
                ),
                
                if (_currentMode == ReaderMode.translation) ...[
                  const Divider(),
                  
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
                ],
                
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
