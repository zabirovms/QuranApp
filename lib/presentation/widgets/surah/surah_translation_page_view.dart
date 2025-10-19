import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/paginated_surah_provider.dart';
import '../../providers/quran_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/paginated_surah_models.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/services/audio_service.dart';
import '../quran/verse_item.dart';
import '../../pages/surah/surah_controller.dart';

class SurahTranslationPageView extends ConsumerStatefulWidget {
  final int surahNumber;
  final int pageNumber;
  final bool showTransliteration;
  final bool isWordByWordMode;
  final String translationLang;
  final String? surahName;

  const SurahTranslationPageView({
    super.key,
    required this.surahNumber,
    required this.pageNumber,
    required this.showTransliteration,
    required this.isWordByWordMode,
    required this.translationLang,
    this.surahName,
  });

  @override
  ConsumerState<SurahTranslationPageView> createState() => _SurahTranslationPageViewState();
}

class _SurahTranslationPageViewState extends ConsumerState<SurahTranslationPageView> {
  int? _openTafsirIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageParams = SurahPageParams(widget.surahNumber, widget.pageNumber);
    final pageAsync = ref.watch(surahPageProvider(pageParams));
    final controller = ref.watch(surahControllerProvider(widget.surahNumber));

    return pageAsync.when(
      data: (surahPage) {
        if (!surahPage.hasVerses) {
          return const Center(
            child: Text('Ҳеҷ ояте ёфт нашуд'),
          );
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Саҳифаи ${surahPage.pageNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ҷузъи ${surahPage.juz}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final paginatedVerse = surahPage.verses[index];
                      final verse = paginatedVerse.verse;
                      
                      final surahWideIndex = verse.verseNumber - 1;
                      
                      final arabicText = (surahWideIndex >= 0 && surahWideIndex < controller.state.arabic.length)
                          ? controller.state.arabic[surahWideIndex].text
                          : verse.arabicText;

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
                        isHighlighted: controller.state.currentAyahIndex == surahWideIndex,
                        isTafsirOpen: _openTafsirIndex == surahWideIndex,
                        onToggleTafsir: () {
                          setState(() {
                            _openTafsirIndex = _openTafsirIndex == surahWideIndex ? null : surahWideIndex;
                          });
                        },
                        onPlayAudio: () {
                          final currentEdition = controller.state.audioEdition;
                          QuranAudioService().playVerse(
                            widget.surahNumber,
                            verse.verseNumber,
                            edition: currentEdition,
                          );
                          ref.read(surahControllerProvider(widget.surahNumber))
                              .setCurrentAyahIndex(surahWideIndex);
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
                            surahName: widget.surahName ?? '',
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
                    childCount: surahPage.verses.length,
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
          onRetry: () => ref.refresh(surahPageProvider(pageParams)),
        ),
      ),
    );
  }
}
