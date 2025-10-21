import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/global_quran_page_provider.dart';
import '../../providers/quran_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/services/audio_service.dart';
import '../quran/verse_item.dart';

class GlobalQuranPageView extends ConsumerStatefulWidget {
  final int pageNumber;
  final int? focusedSurahNumber;
  final bool showTransliteration;
  final bool isWordByWordMode;
  final String translationLang;

  const GlobalQuranPageView({
    super.key,
    required this.pageNumber,
    this.focusedSurahNumber,
    required this.showTransliteration,
    required this.isWordByWordMode,
    required this.translationLang,
  });

  @override
  ConsumerState<GlobalQuranPageView> createState() => _GlobalQuranPageViewState();
}

class _GlobalQuranPageViewState extends ConsumerState<GlobalQuranPageView> {
  final Map<String, bool> _openTafsirMap = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(globalQuranPageProvider(widget.pageNumber));

    return pageAsync.when(
      data: (quranPage) {
        if (!quranPage.hasVerses) {
          return const Center(
            child: Text('Ҳеҷ ояте ёфт нашуд'),
          );
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final verse = quranPage.verses[index];
                      final isFirstVerseOfSurah = verse.verseNumber == 1;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isFirstVerseOfSurah) ...[
                            if (index > 0) const SizedBox(height: 16),
                            _buildSurahHeader(verse.surahId),
                            const SizedBox(height: 12),
                          ],
                          _buildVerseItem(verse),
                        ],
                      );
                    },
                    childCount: quranPage.verses.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          message: 'Хатоги дар боргирии саҳифа: $error',
          onRetry: () => ref.refresh(globalQuranPageProvider(widget.pageNumber)),
        ),
      ),
    );
  }

  Widget _buildSurahHeader(int surahNumber) {
    final surahInfoAsync = ref.watch(surahInfoProvider(surahNumber));

    return surahInfoAsync.when(
      data: (surah) {
        if (surah == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                surah.nameArabic,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),
              Text(
                surah.nameTajik,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text('${surah.versesCount} оят'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(surah.revelationType == 'Meccan' ? 'Маккӣ' : 'Мадинӣ'),
                    backgroundColor: surah.revelationType == 'Meccan' 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                  ),
                ],
              ),
              if (surah.description != null && surah.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ExpansionTile(
                  title: Text(
                    'Тавсифи Сура',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        surah.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildVerseItem(VerseModel verse) {
    final surahNumber = verse.surahId;
    final controller = ref.watch(surahControllerProvider(surahNumber));
    final surahInfoAsync = ref.watch(surahInfoProvider(surahNumber));
    
    final surahWideIndex = verse.verseNumber - 1;
    final tafsirKey = '${verse.surahId}:${verse.verseNumber}';
    
    // Always use the Arabic text from the verse model (from mushaf data) 
    // to ensure proper RTL formatting and alignment
    final arabicText = verse.arabicText;

    final wbw = controller.state.wordByWord[verse.uniqueKey]
        ?.map((w) => {'arabic': w.arabic, 'meaning': w.farsi ?? ''})
        .toList();

    return VerseItem(
      verse: verse.copyWith(arabicText: arabicText),
      showTransliteration: widget.showTransliteration,
      showTafsir: false,
      isWordByWordMode: widget.isWordByWordMode,
      wordByWordTokens: wbw,
      translationTextOverride: () {
        switch (widget.translationLang) {
          case 'farsi':
            return verse.farsi ?? verse.tajikText;
          case 'russian':
            return verse.russian ?? verse.tajikText;
          default:
            return verse.tajikText;
        }
      }(),
      isHighlighted: verse.verseNumber != 1 && controller.state.currentAyahIndex == surahWideIndex,
      isTafsirOpen: _openTafsirMap[tafsirKey] ?? false,
      onToggleTafsir: () {
        setState(() {
          _openTafsirMap[tafsirKey] = !(_openTafsirMap[tafsirKey] ?? false);
        });
      },
      onPlayAudio: () {
        final currentEdition = controller.state.audioEdition;
        QuranAudioService().playVerse(
          surahNumber,
          verse.verseNumber,
          edition: currentEdition,
        );
        ref.read(surahControllerProvider(surahNumber))
            .setCurrentAyahIndex(surahWideIndex);
      },
      onBookmark: () async {
        final bm = BookmarkModel(
          id: 0,
          userId: 'default_user',
          verseId: verse.id,
          verseKey: '$surahNumber:${verse.verseNumber}',
          surahNumber: surahNumber,
          verseNumber: verse.verseNumber,
          arabicText: arabicText,
          tajikText: verse.tajikText,
          surahName: surahInfoAsync.maybeWhen(
            data: (s) => s?.nameTajik ?? '',
            orElse: () => '',
          ),
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
  }
}
