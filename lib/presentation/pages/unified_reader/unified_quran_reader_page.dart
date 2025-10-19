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

class _UnifiedQuranReaderPageState extends ConsumerState<UnifiedQuranReaderPage> 
    with SingleTickerProviderStateMixin {
  ReaderMode _currentMode = ReaderMode.mushaf;
  bool _showTransliteration = false;
  bool _isWordByWordMode = false;
  bool _showAudioPlayer = false;
  bool _showControls = true;
  bool _showQuickActions = false;
  String _translationLang = 'tajik';
  String _audioEdition = 'ar.alafasy';
  late PageController _pageController;
  int _currentPageNumber = 1;
  int _initialPageNumber = 1;
  bool _isLoading = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    Future(() async {
      try {
        final s = SettingsService();
        await s.init();
        setState(() {
          _showTransliteration = s.getShowTransliteration();
          _isWordByWordMode = s.getWordByWordMode();
          _translationLang = s.getTranslationLanguage();
          _audioEdition = s.getAudioEdition();
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
    _fabAnimationController.dispose();
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

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
    });
    if (_showQuickActions) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: LoadingWidget()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF5F5F5),
      extendBodyBehindAppBar: true,
      body: mushafDataAsync.when(
        data: (data) => SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _toggleControls,
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
                    return MushafPageView(pageNumber: pageNumber);
                  },
                ),
              ),
              
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildMushafHeader(),
                ),
              
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildMushafFooter(),
                ),
            ],
          ),
        ),
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(
          message: 'Хато ҳангоми боркунии Мусҳаф',
          onRetry: () => ref.refresh(mushafDataProvider),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTranslationMode() {
    final surahInfoAsync = widget.surahNumber != null
        ? ref.watch(surahInfoProvider(widget.surahNumber!))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTranslationHeader(surahInfoAsync),
            
            if (_showAudioPlayer && widget.surahNumber != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildMushafHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? Colors.black : Colors.white).withOpacity(0.95),
            (isDark ? Colors.black : Colors.white).withOpacity(0.7),
            (isDark ? Colors.black : Colors.white).withOpacity(0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
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
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Мусҳаф',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            icon: Icon(
              Icons.translate,
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
            onPressed: _toggleMode,
            tooltip: 'Ҳолати тарҷума',
          ),
        ],
      ),
    );
  }

  Widget _buildMushafFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            (isDark ? Colors.black : Colors.white).withOpacity(0.95),
            (isDark ? Colors.black : Colors.white).withOpacity(0.7),
            (isDark ? Colors.black : Colors.white).withOpacity(0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Саҳифа $_currentPageNumber аз 604',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.navigate_before,
                  color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                ),
                onPressed: _currentPageNumber < 604 ? () => _goToPage(_currentPageNumber + 1) : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.navigate_next,
                  color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                ),
                onPressed: _currentPageNumber > 1 ? () => _goToPage(_currentPageNumber - 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationHeader(AsyncValue<dynamic>? surahInfoAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
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
                
                Expanded(
                  child: Column(
                    children: [
                      if (surahInfoAsync != null)
                        surahInfoAsync.when(
                          data: (surah) => Text(
                            surah?.nameTajik ?? 'Қуръон',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const Text('Қуръон'),
                          error: (_, __) => const Text('Қуръон'),
                        )
                      else
                        Text(
                          'Қуръон',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.translate,
                                  size: 14,
                                  color: AppTheme.secondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Саҳифаи $_currentPageNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {
                    context.push('/bookmarks');
                  },
                  tooltip: 'Захираҳо',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showQuickActions) ...[
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.small(
              heroTag: 'mode_toggle',
              onPressed: _toggleMode,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                _currentMode == ReaderMode.mushaf 
                    ? Icons.translate 
                    : Icons.auto_stories,
                color: Colors.white,
              ),
              tooltip: _currentMode == ReaderMode.mushaf 
                  ? 'Ҳолати тарҷума' 
                  : 'Ҳолати Мусҳаф',
            ),
          ),
          const SizedBox(height: 12),
          
          if (_currentMode == ReaderMode.translation) ...[
            ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.small(
                heroTag: 'audio',
                onPressed: () {
                  setState(() {
                    _showAudioPlayer = !_showAudioPlayer;
                  });
                },
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(
                  _showAudioPlayer ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                tooltip: 'Садо',
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.small(
              heroTag: 'settings',
              onPressed: () => _showSettingsBottomSheet(context),
              backgroundColor: AppTheme.accentColor,
              child: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
              tooltip: 'Танзимот',
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggleQuickActions,
          backgroundColor: AppTheme.primaryColor,
          child: AnimatedRotation(
            turns: _showQuickActions ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Танзимоти намоиш',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    _currentMode == ReaderMode.mushaf 
                        ? Icons.auto_stories 
                        : Icons.translate,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Ҳолати намоиш'),
                  subtitle: Text(_currentMode == ReaderMode.mushaf ? 'Мусҳаф' : 'Тарҷума'),
                  trailing: Switch(
                    value: _currentMode == ReaderMode.translation,
                    activeColor: AppTheme.primaryColor,
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
              ),
              
              if (_currentMode == ReaderMode.translation) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                ListTile(
                  leading: Icon(Icons.language, color: AppTheme.secondaryColor),
                  title: const Text('Забони тарҷума'),
                  subtitle: Text(_getTranslationLanguageName(_translationLang)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showTranslationLanguageDialog(context, setModalState);
                  },
                ),
                
                SwitchListTile(
                  secondary: Icon(Icons.text_fields, color: AppTheme.accentColor),
                  title: const Text('Транслитератсия'),
                  subtitle: const Text('Нусхаи лотинӣ нишон дода шавад'),
                  value: _showTransliteration,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setModalState(() => _showTransliteration = value);
                    setState(() => _showTransliteration = value);
                    Future(() async {
                      final s = SettingsService();
                      await s.init();
                      await s.setShowTransliteration(value);
                    });
                  },
                ),
                
                SwitchListTile(
                  secondary: Icon(Icons.compare_arrows, color: AppTheme.accentColor),
                  title: const Text('Калима ба калима'),
                  subtitle: const Text('Тарҷумаи ҳар калима'),
                  value: _isWordByWordMode,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setModalState(() => _isWordByWordMode = value);
                    setState(() => _isWordByWordMode = value);
                    Future(() async {
                      final s = SettingsService();
                      await s.init();
                      await s.setWordByWordMode(value);
                    });
                  },
                ),
                
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                
                ListTile(
                  leading: Icon(Icons.record_voice_over, color: AppTheme.primaryColor),
                  title: const Text('Қорӣ'),
                  subtitle: Text(_getQariName(_audioEdition)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showQariSelectionDialog(context, setModalState);
                  },
                ),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

  String _getQariName(String edition) {
    switch (edition) {
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

  void _showTranslationLanguageDialog(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.language, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Интихоби забон'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, 'Тоҷикӣ', 'tajik', setModalState),
            _buildLanguageOption(context, 'Форсӣ', 'farsi', setModalState),
            _buildLanguageOption(context, 'Русӣ', 'russian', setModalState),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String name,
    String value,
    StateSetter setModalState,
  ) {
    final isSelected = _translationLang == value;
    
    return InkWell(
      onTap: () {
        setModalState(() => _translationLang = value);
        setState(() => _translationLang = value);
        Future(() async {
          final s = SettingsService();
          await s.init();
          await s.setTranslationLanguage(value);
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQariSelectionDialog(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.record_voice_over, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Интихоби қорӣ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQariOption(context, 'Мишарӣ Алъафасӣ', 'ar.alafasy', setModalState),
            _buildQariOption(context, 'Маъмуди Халил Ҳусарӣ', 'ar.husary', setModalState),
            _buildQariOption(context, 'Абдул Босит', 'ar.abdulbasit', setModalState),
            _buildQariOption(context, 'Миншовӣ', 'ar.minshawi', setModalState),
          ],
        ),
      ),
    );
  }

  Widget _buildQariOption(
    BuildContext context,
    String name,
    String edition,
    StateSetter setModalState,
  ) {
    final isSelected = _audioEdition == edition;
    
    return InkWell(
      onTap: () {
        setModalState(() => _audioEdition = edition);
        setState(() => _audioEdition = edition);
        Future(() async {
          final s = SettingsService();
          await s.init();
          await s.setAudioEdition(edition);
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
