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
import 'package:flutter/services.dart';
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
  bool _showTransliteration = true;
  bool _showTafsir = false;
  bool _isWordByWordMode = false;
  bool _showAudioPlayer = false;
  String _translationLang = 'tajik';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future(() async {
      try {
        final s = SettingsService();
        await s.init();
        setState(() {
          _showTransliteration = s.getShowTransliteration();
          _showTafsir = s.getShowTafsir();
          _isWordByWordMode = s.getWordByWordMode();
          _translationLang = s.getTranslationLanguage();
        });
      } catch (_) {
        // Fallback to defaults if settings not ready
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
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Reciter',
            onSelected: (edition) {
              ref.read(surahControllerProvider(widget.surahNumber)).changeAudioEdition(
                surahNumber: widget.surahNumber,
                audioEdition: edition,
              );
              // Persist selection
              // ignore: unused_result
              Future(() async {
                // Lazy import to avoid blocking UI
                // ignore: unused_local_variable
                final settings = SettingsService();
                await settings.init();
                await settings.setAudioEdition(edition);
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'ar.alafasy', child: Text('Mishary Alafasy')),
              PopupMenuItem(value: 'ar.husary', child: Text('Mahmoud Khalil Al-Husary')),
              PopupMenuItem(value: 'ar.abdulbasit', child: Text('Abdul Basit')),
              PopupMenuItem(value: 'ar.minshawi', child: Text('Minshawi')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.audiotrack),
            onPressed: () {
              setState(() {
                _showAudioPlayer = !_showAudioPlayer;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showDisplaySettings(context);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate),
            tooltip: 'Translation',
            initialValue: _translationLang,
            onSelected: (lang) {
              setState(() {
                _translationLang = lang;
              });
              Future(() async {
                final s = SettingsService();
                await s.init();
                await s.setTranslationLanguage(lang);
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'tajik', child: Text('Tajik')),
              PopupMenuItem(value: 'farsi', child: Text('Farsi')),
              PopupMenuItem(value: 'russian', child: Text('Russian')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final s = surahAsync.asData?.value;
              if (s != null) {
                await Share.share('Reading ${s.nameEnglish} (${s.number})');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Jump navigator
          if (!controller.state.loading && controller.state.error == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _JumpChip(label: 'Ayah', onTap: () => _scrollToIndex(controller.state.currentAyahIndex)),
                  const SizedBox(width: 8),
                  _JumpChip(label: 'Juz', onTap: () => _scrollToMarker(controller.state.juzStarts)),
                  const SizedBox(width: 8),
                  _JumpChip(label: 'Hizb¼', onTap: () => _scrollToMarker(controller.state.hizbStarts)),
                  const SizedBox(width: 8),
                  _JumpChip(label: 'Ruku', onTap: () => _scrollToMarker(controller.state.rukuStarts)),
                  const SizedBox(width: 8),
                  _JumpChip(label: 'Manzil', onTap: () => _scrollToMarker(controller.state.manzilStarts)),
                  const SizedBox(width: 8),
                  _JumpChip(label: 'Page', onTap: () => _scrollToMarker(controller.state.pageStarts)),
                ],
              ),
            ),
          // Audio Player
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

          // Surah Info
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
                          label: Text('${surah.versesCount} verses'),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(surah.revelationType),
                          backgroundColor: surah.revelationType == 'Meccan' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                        ),
                      ],
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

          // Marker bar (basic)
          if (!controller.state.loading && controller.state.error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (controller.state.juzStarts.isNotEmpty) Chip(label: Text('Juz ${controller.state.juzStarts.length} markers')),
                  if (controller.state.hizbStarts.isNotEmpty) Chip(label: Text('Hizb¼ ${controller.state.hizbStarts.length}')),
                  if (controller.state.rukuStarts.isNotEmpty) Chip(label: Text('Ruku ${controller.state.rukuStarts.length}')),
                  if (controller.state.manzilStarts.isNotEmpty) Chip(label: Text('Manzil ${controller.state.manzilStarts.length}')),
                  if (controller.state.pageStarts.isNotEmpty) Chip(label: Text('Pages ${controller.state.pageStarts.length}')),
                ],
              ),
            ),

          // Verses List
          Expanded(
            child: versesAsync.when(
              data: (verses) {
                if (verses.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Оятҳо ёфт нашуд',
                    message: 'Дар ҳоли ҳозир ҳеҷ ояте дар ин сура нест.',
                    icon: Icons.menu_book,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    final arabicText = (index < controller.state.arabic.length)
                        ? controller.state.arabic[index].text
                        : verse.arabicText;
                    final audioUrl = (index < controller.state.audio.length)
                        ? controller.state.audio[index].audio
                        : null;
                    final wbw = controller.state.wordByWord[verse.uniqueKey]
                        ?.map((w) => {'arabic': w.arabic, 'meaning': w.farsi ?? ''})
                        .toList();
                    final widgets = <Widget>[];

                    void addDivider(String label) {
                      widgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(label, style: Theme.of(context).textTheme.labelMedium),
                              ),
                              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                            ],
                          ),
                        ),
                      );
                    }

                    final ayahIndex1Based = index + 1;
                    if (controller.state.juzStarts.contains(ayahIndex1Based)) {
                      addDivider('Juz');
                    }
                    if (controller.state.hizbStarts.contains(ayahIndex1Based)) {
                      addDivider('Hizb¼');
                    }
                    if (controller.state.rukuStarts.contains(ayahIndex1Based)) {
                      addDivider('Ruku');
                    }
                    if (controller.state.manzilStarts.contains(ayahIndex1Based)) {
                      addDivider('Manzil');
                    }
                    if (controller.state.pageStarts.contains(ayahIndex1Based)) {
                      addDivider('Page');
                    }

                    widgets.add(
                      VerseItem(
                        verse: verse.copyWith(arabicText: arabicText),
                        showTransliteration: _showTransliteration,
                        showTafsir: _showTafsir,
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
                        isHighlighted: controller.state.currentAyahIndex == index,
                        onPlayAudio: () {
                          // Use audio service which computes CDN URL safely
                          QuranAudioService().playVerse(widget.surahNumber, verse.verseNumber);
                          ref.read(surahControllerProvider(widget.surahNumber)).setCurrentAyahIndex(index);
                        },
                        onBookmark: () {
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
                          ref.read(bookmarkUseCaseProvider).addBookmark(bm);
                        },
                      ),
                    );

                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widgets);
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
        ],
      ),
    );
  }

  void _scrollToIndex(int index) {
    final offset = (index.clamp(0, 9999)) * 220.0; // rough item height; can refine
    _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _scrollToMarker(List<int> starts) {
    if (starts.isEmpty) return;
    _scrollToIndex((starts.first - 1).clamp(0, 9999));
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
                
                // Show Tafsir
                SwitchListTile(
                  title: const Text('Намоиши тафсир'),
                  subtitle: const Text('Тафсири оятҳо нишон дода шавад'),
                  value: _showTafsir,
                  onChanged: (value) {
                    setModalState(() {
                      _showTafsir = value;
                    });
                    setState(() {
                      _showTafsir = value;
                    });
                    Future(() async {
                      final s = SettingsService();
                      await s.init();
                      await s.setShowTafsir(value);
                    });
                  },
                ),
                
                // Word by Word Mode
                SwitchListTile(
                  title: const Text('Ҳолати калима ба калима'),
                  subtitle: const Text('Тафсири калима ба калима нишон дода шавад'),
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
}

class _JumpChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _JumpChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
      ),
    );
  }
}