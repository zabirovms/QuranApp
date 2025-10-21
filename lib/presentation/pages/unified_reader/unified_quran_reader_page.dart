import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/global_quran_page_provider.dart';
import '../../providers/mushaf_provider.dart';
import '../../providers/quran_provider.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/audio_service.dart';
import '../../widgets/mushaf/mushaf_page_view.dart';
import '../../widgets/quran/global_quran_page_view.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

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
    with TickerProviderStateMixin {
  ReaderMode _currentMode = ReaderMode.mushaf;
  bool _showTransliteration = false;
  bool _isWordByWordMode = false;
  bool _showAudioPlayer = false;
  bool _showControls = false;
  bool _showSettingsPanel = false;
  String _selectedQari = 'Abdul Basit Murattal';
  late PageController _pageController;
  int _currentPageNumber = 1;
  bool _isLoading = true;
  late AnimationController _headerAnimationController;
  late AnimationController _footerAnimationController;
  late AnimationController _settingsAnimationController;
  late Animation<Offset> _headerAnimation;
  late Animation<Offset> _footerAnimation;
  late Animation<double> _settingsAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _footerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _settingsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    // Initialize animations
    _headerAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _footerAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _footerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _settingsAnimation = CurvedAnimation(
      parent: _settingsAnimationController,
      curve: Curves.easeInOut,
    );
    
    Future(() async {
      try {
        final s = SettingsService();
        await s.init();
        setState(() {
          _showTransliteration = s.getShowTransliteration();
          _isWordByWordMode = s.getWordByWordMode();
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
        _currentPageNumber = startPage;
        _pageController = PageController(initialPage: startPage - 1);
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _pageController.dispose();
    }
    _headerAnimationController.dispose();
    _footerAnimationController.dispose();
    _settingsAnimationController.dispose();
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
    
    if (_showControls) {
      _headerAnimationController.forward();
      _footerAnimationController.forward();
    } else {
      _headerAnimationController.reverse();
      _footerAnimationController.reverse();
      _hideSettingsPanel();
    }
  }

  void _hideSettingsPanel() {
    if (_showSettingsPanel) {
      setState(() {
        _showSettingsPanel = false;
      });
      _settingsAnimationController.reverse();
    }
  }

  void _toggleSettingsPanel() {
    setState(() {
      _showSettingsPanel = !_showSettingsPanel;
    });
    
    if (_showSettingsPanel) {
      _settingsAnimationController.forward();
    } else {
      _settingsAnimationController.reverse();
    }
  }

  void _toggleTransliteration() {
      setState(() {
      _showTransliteration = !_showTransliteration;
    });
    // Save to settings
    SettingsService().setShowTransliteration(_showTransliteration);
  }

  void _toggleWordByWordMode() {
    setState(() {
      _isWordByWordMode = !_isWordByWordMode;
    });
    // Save to settings
    SettingsService().setWordByWordMode(_isWordByWordMode);
  }

  void _toggleAudioPlayer() {
    setState(() {
      _showAudioPlayer = !_showAudioPlayer;
    });
    
    if (_showAudioPlayer) {
      // Start playing audio for current page
      _playCurrentPageAudio();
    } else {
      // Stop audio
      QuranAudioService().stop();
    }
  }

  void _playCurrentPageAudio() {
    try {
      final pageAsync = ref.read(globalQuranPageProvider(_currentPageNumber));
      pageAsync.maybeWhen(
        data: (page) {
          if (page.verses.isNotEmpty) {
            final firstVerse = page.verses.first;
            QuranAudioService().playVerse(
              firstVerse.surahId,
              firstVerse.verseNumber,
              edition: _selectedQari,
            );
          }
        },
        orElse: () {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Хатоги дар пахш кардани аудио: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _selectQari(String qari) {
    setState(() {
      _selectedQari = qari;
    });
    // Save to settings
    SettingsService().setAudioEdition(qari);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main content
            _buildMainContent(),
            
            // Header panel
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _headerAnimation,
                child: _buildHeaderPanel(),
              ),
            ),
            
            // Footer panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _footerAnimation,
                child: _buildFooterPanel(),
              ),
            ),
            
            // Settings panel (only in translation mode)
            if (_currentMode == ReaderMode.translation && _showSettingsPanel)
              _buildSettingsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (pageIndex) {
        setState(() {
          _currentPageNumber = pageIndex + 1;
        });
      },
      itemBuilder: (context, pageIndex) {
        final pageNumber = pageIndex + 1;
        
        if (_currentMode == ReaderMode.mushaf) {
          return _buildMushafContent(pageNumber);
        } else {
          return _buildTranslationContent(pageNumber);
        }
      },
    );
  }

  Widget _buildMushafContent(int pageNumber) {
    final mushafDataAsync = ref.watch(mushafDataProvider);

    return mushafDataAsync.when(
      data: (data) => SafeArea(
        child: MushafPageView(
          pageNumber: pageNumber,
        ),
      ),
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(mushafDataProvider);
          },
        ),
      ),
    );
  }

  Widget _buildTranslationContent(int pageNumber) {
    final surahDataAsync = ref.watch(globalQuranPageProvider(pageNumber));

    return surahDataAsync.when(
      data: (data) => SafeArea(
        child: GlobalQuranPageView(
          pageNumber: pageNumber,
          showTransliteration: _showTransliteration,
          isWordByWordMode: _isWordByWordMode,
          translationLang: 'tajik',
        ),
      ),
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(globalQuranPageProvider(pageNumber));
          },
        ),
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Back button, Surah name, Bookmark button
              Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  
                  // Surah name (centered)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _getCurrentSurahName(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Саҳифа $_currentPageNumber • Ҷузъ ${_getCurrentJuz()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Bookmark button
                  IconButton(
                    onPressed: _addBookmark,
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  // Bookmarks list button
                  IconButton(
                    onPressed: () => context.push('/bookmarks'),
                    icon: Icon(
                      Icons.bookmark_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Хатбаракҳо',
                  ),

                  // Single mode toggle button
                  IconButton(
                    tooltip: _currentMode == ReaderMode.mushaf ? 'Switch to Translation' : 'Switch to Mushaf',
                    icon: Icon(
                      _currentMode == ReaderMode.mushaf 
                          ? Icons.menu_book_rounded 
                          : Icons.translate_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22, // smaller for compact header
                    ),
                    onPressed: _toggleMode,
                  ),

                  // Settings icon (only for translation mode)
                  if (_currentMode == ReaderMode.translation)
                    IconButton(
                      onPressed: _toggleSettingsPanel,
                      icon: Icon(
                        _showSettingsPanel ? Icons.close_rounded : Icons.settings_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                ],
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildFooterPanel() {
    return Container(
          decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
              ),
            ],
          ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Play/Pause button
              IconButton(
                onPressed: _toggleAudioPlayer,
                icon: Icon(
                  _showAudioPlayer ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Qari name (centered)
              Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                    Text(
                      _selectedQari,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Қори',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Qari dropdown button
              PopupMenuButton<String>(
                onSelected: _selectQari,
                itemBuilder: (context) => _getQariList().map((qari) {
                  return PopupMenuItem<String>(
                    value: qari,
                    child: Row(
                      children: [
                        Icon(
                          _selectedQari == qari ? Icons.check_rounded : null,
                      color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            qari,
                            style: TextStyle(
                              color: _selectedQari == qari 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: _selectedQari == qari 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                ),
              ),
            ),
          ],
                    ),
                  );
                }).toList(),
            child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      top: 120, // Below header
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: _settingsAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Танзимот',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              
              // Transliteration toggle
              _buildSettingsToggle(
                'Транслитератсия',
                'Намоиши транслитератсия',
                _showTransliteration,
                Icons.font_download_rounded,
                _toggleTransliteration,
              ),
              
                const SizedBox(height: 16),
              
              // Word-by-word toggle
              _buildSettingsToggle(
                'Ҳарфи ба ҳарф',
                'Намоиши тарҷумаи ҳарфи ба ҳарф',
                _isWordByWordMode,
                Icons.text_fields_rounded,
                _toggleWordByWordMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsToggle(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    VoidCallback onToggle,
  ) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: value 
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: Colors.white,
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveThumbColor: Theme.of(context).colorScheme.outline,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentSurahName() {
    if (widget.surahNumber != null) {
      final surahInfoAsync = ref.read(surahInfoProvider(widget.surahNumber!));
      return surahInfoAsync.maybeWhen(
        data: (surah) => surah?.nameTajik ?? 'Сура',
        orElse: () => 'Сура',
      );
    }
    
    // For page-based navigation, get surah from current page
    final pageAsync = ref.read(globalQuranPageProvider(_currentPageNumber));
    return pageAsync.maybeWhen(
      data: (page) {
        if (page.surahsOnPage.isNotEmpty) {
          final firstSurahNumber = page.surahsOnPage.first;
          final surahInfoAsync = ref.read(surahInfoProvider(firstSurahNumber));
          return surahInfoAsync.maybeWhen(
            data: (surah) => surah?.nameTajik ?? 'Сура',
            orElse: () => 'Сура',
          );
        }
        return 'Сура';
      },
      orElse: () => 'Сура',
    );
  }

  int _getCurrentJuz() {
    final pageAsync = ref.read(globalQuranPageProvider(_currentPageNumber));
    return pageAsync.maybeWhen(
      data: (page) => page.juz,
      orElse: () => 1,
    );
  }

  void _addBookmark() async {
    try {
      // Get current verse information
      final pageAsync = ref.read(globalQuranPageProvider(_currentPageNumber));
      pageAsync.maybeWhen(
        data: (page) {
          if (page.verses.isNotEmpty) {
            // Add bookmark logic would go here
            // For now, just show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Оят ба захираҳо илова карда шуд'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        orElse: () {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Хатоги дар захира кардан: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  List<String> _getQariList() {
    return [
      'Abdul Basit Murattal',
      'Abdul Basit Mujawwad',
      'Abdurrahmaan As-Sudais',
      'Mishary Rashid Alafasy',
      'Saad Al-Ghamdi',
      'Muhammad Al-Minshawi',
      'Mahmoud Khalil Al-Husary',
      'Muhammad Siddiq Al-Minshawi',
    ];
  }
}
