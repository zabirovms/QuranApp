import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/surah_model.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../providers/quran_provider.dart';
import 'learn_words_controller.dart';
import 'learn_words_constants.dart';

// Provider for LearnWordsController
final learnWordsControllerProvider =
    ChangeNotifierProvider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final aqcApi = ref.watch(alquranCloudApiProvider);
  return LearnWordsController(apiService: apiService, aqcApi: aqcApi);
});

class LearnWordsPage extends ConsumerStatefulWidget {
  const LearnWordsPage({super.key});

  @override
  ConsumerState<LearnWordsPage> createState() => _LearnWordsPageState();
}

class _LearnWordsPageState extends ConsumerState<LearnWordsPage> {
  final TextEditingController _wordCountController = TextEditingController(text: '');
  final TextEditingController _verseStartController = TextEditingController(text: '');
  final TextEditingController _verseEndController = TextEditingController(text: '');
  late final ScrollController _scrollController;
  bool _wordCountAdjusted = false;
  Timer? _wordCountHintTimer;
  bool _verseStartAdjusted = false;
  bool _verseEndAdjusted = false;
  Timer? _verseStartHintTimer;
  Timer? _verseEndHintTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _wordCountHintTimer?.cancel();
    _verseStartHintTimer?.cancel();
    _verseEndHintTimer?.cancel();
    _wordCountController.dispose();
    _verseStartController.dispose();
    _verseEndController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only proceed if scroll position is valid
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    
    // Load more when user scrolls near the bottom (within 200 pixels)
    if (position.pixels >= position.maxScrollExtent - 200) {
      final controller = ref.read(learnWordsControllerProvider);
      final state = controller.state;
      
      // Only load more if there are more verses to load and not already loading
      if (state.versesLoaded < state.verses.length && !state.loading) {
        controller.loadMoreVerses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(learnWordsControllerProvider);
    final state = controller.state;

    return PopScope(
      canPop: false, // Always intercept to handle navigation properly
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle device back button - respect navigation history
          if (state.currentScreen == LearnWordsScreen.quiz) {
            // From quiz screen, go back to learning screen
            controller.endQuiz();
          } else if (state.currentScreen == LearnWordsScreen.learning) {
            // From learning screen, go back to surahs list
            controller.goBackToSurahs();
          } else {
            // From surahs screen, pop normally (goes to main menu or previous page)
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              // If no history, go to main menu
              context.go('/');
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle(state.currentScreen, state.selectedSurah)),
          leading: state.currentScreen != LearnWordsScreen.surahs
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (state.currentScreen == LearnWordsScreen.quiz) {
                      controller.endQuiz();
                    } else {
                      controller.goBackToSurahs();
                    }
                  },
                )
              : null,
        ),
        body: _buildBody(state, controller),
      ),
    );
  }

  String _getAppBarTitle(LearnWordsScreen screen, SurahModel? surah) {
    if ((screen == LearnWordsScreen.learning || screen == LearnWordsScreen.quiz) && surah != null) {
      return "Сураи ${surah.nameTajik}";
    }
    return 'Омӯхтани калимаҳо';
  }

  Widget _buildBody(LearnWordsState state, LearnWordsController controller) {
    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          color: Colors.green,
        ),
      );
    }

    if (state.error != null) {
      // Check if it's an offline error
      final isOfflineError = state.error!.contains(LearnWordsConstants.offlineTitle) ||
          state.error!.contains('Интернет пайваст нест') ||
          state.error!.contains('калима ба калима') ||
          state.error!.contains('дастрас нест');
      
      return Center(
        child: CustomErrorWidget(
          title: isOfflineError ? LearnWordsConstants.offlineTitle : 'Хатогӣ',
          message: state.error!,
          onRetry: () {
            if (state.selectedSurah != null) {
              controller.selectSurah(state.selectedSurah!);
            } else {
              controller.loadSurahs();
            }
          },
        ),
      );
    }

    switch (state.currentScreen) {
      case LearnWordsScreen.surahs:
        return _buildSurahsScreen(state, controller);
      case LearnWordsScreen.learning:
        return _buildLearningScreen(state, controller);
      case LearnWordsScreen.quiz:
        return _buildQuizScreen(state, controller);
    }
  }

  Widget _buildSurahsScreen(LearnWordsState state, LearnWordsController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Рӯйхати сураҳо',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: state.surahs.length,
            itemBuilder: (context, index) {
              final surah = state.surahs[index];
              final wordCount = controller.getWordCountForSurah(surah.number);
              final wordCountText = wordCount != null 
                  ? '$wordCount калима'
                  : '';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text('${surah.number}. Сураи ${surah.nameTajik}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${surah.versesCount} оят',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (wordCountText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            wordCountText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () => controller.selectSurah(surah),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLearningScreen(LearnWordsState state, LearnWordsController controller) {
    // Check if there's an offline error for word-by-word data
    final isOfflineWordByWordError = state.error != null && 
        (state.error!.contains(LearnWordsConstants.offlineWordByWordMessage) ||
         state.error!.contains('калима ба калима'));

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        // Page title within learning screen
        Text(
          'Санҷиш',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Show offline warning banner for word-by-word data
        if (isOfflineWordByWordError)
          _buildOfflineWarningBanner(state, controller),

        // Quiz options
        _buildQuizOptions(state, controller),

        const SizedBox(height: 16),

        // Verses display
        ..._buildVerses(state, controller),
      ],
    );
  }

  Widget _buildQuizOptions(LearnWordsState state, LearnWordsController controller) {
    final isWordsMode = state.selectedQuizMode == QuizMode.words;
    final int maxVerses = state.selectedSurah?.versesCount ?? LearnWordsConstants.defaultVerseEnd;
    final String startText = _verseStartController.text.trim();
    final String endText = _verseEndController.text.trim();
    final int? startNum = startText.isEmpty ? null : int.tryParse(startText);
    final int? endNum = endText.isEmpty ? null : int.tryParse(endText);
    final bool wordsFilled = _wordCountController.text.trim().isNotEmpty;
    final bool versesFilled = startNum != null && endNum != null;
    final bool versesInRange = versesFilled && startNum >= 1 && endNum >= 1 && startNum <= maxVerses && endNum <= maxVerses && startNum <= endNum;
    final bool canStart = isWordsMode ? wordsFilled : versesInRange;
    return Column(
      children: [
        // Toggle between modes
        Align(
          alignment: Alignment.center,
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            isSelected: [isWordsMode, !isWordsMode],
            onPressed: (index) {
              controller.setQuizMode(index == 0 ? QuizMode.words : QuizMode.verses);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Аз калима'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Аз оят'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isWordsMode) ...[
          // Word count input
          TextField(
            controller: _wordCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: '${LearnWordsConstants.wordCountLabel} (${LearnWordsConstants.minWordCount}–${state.wordByWord.values.fold<int>(0, (s, l) => s + l.where((w) => w.farsi != null && w.farsi!.isNotEmpty).length)})',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _wordCountAdjusted
                      ? Colors.redAccent.withOpacity(0.7)
                      : Theme.of(context).dividerColor,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _wordCountAdjusted
                      ? Colors.redAccent
                      : AppTheme.primaryColor,
                  width: 1.5,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              suffixIcon: _wordCountAdjusted
                  ? const Icon(Icons.error_outline, size: 16, color: Colors.redAccent)
                  : null,
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                return;
              }
              // Clamp to allowed range and reflect in UI immediately
              int parsed = int.tryParse(value) ?? LearnWordsConstants.defaultWordCount;
              if (parsed < LearnWordsConstants.minWordCount) parsed = LearnWordsConstants.minWordCount;
              final int _availableWords = state.wordByWord.values.fold<int>(0, (s, l) => s + l.where((w) => w.farsi != null && w.farsi!.isNotEmpty).length);
              if (_availableWords > 0 && parsed > _availableWords) parsed = _availableWords;
              final needsAdjust = _wordCountController.text != parsed.toString();
              if (needsAdjust) {
                _wordCountController.text = parsed.toString();
                _wordCountController.selection = TextSelection.collapsed(offset: _wordCountController.text.length);
                // Show subtle invalid indicator briefly
                setState(() {
                  _wordCountAdjusted = true;
                });
                _wordCountHintTimer?.cancel();
                _wordCountHintTimer = Timer(const Duration(milliseconds: 1200), () {
                  if (mounted) {
                    setState(() {
                      _wordCountAdjusted = false;
                    });
                  }
                });
              }
              controller.setCustomWordCount(parsed);
            },
          ),
        ] else ...[
          // Verse range inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verseStartController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '${LearnWordsConstants.verseFromLabel} (1–$maxVerses)',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _verseStartAdjusted
                            ? Colors.redAccent.withOpacity(0.7)
                            : Theme.of(context).dividerColor,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _verseStartAdjusted
                            ? Colors.redAccent
                            : AppTheme.primaryColor,
                        width: 1.5,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    suffixIcon: _verseStartAdjusted
                        ? const Icon(Icons.error_outline, size: 16, color: Colors.redAccent)
                        : null,
                  ),
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      return;
                    }
                    int start = int.tryParse(value) ?? LearnWordsConstants.defaultVerseStart;
                    int end = int.tryParse(_verseEndController.text) ?? LearnWordsConstants.defaultVerseEnd;
                    // Clamp
                    if (start < 1) start = 1;
                    if (start > maxVerses) start = maxVerses;
                    // Ensure start <= end
                    if (start > end) {
                      end = start;
                      _verseEndController.text = end.toString();
                      _verseEndController.selection = TextSelection.collapsed(offset: _verseEndController.text.length);
                    }
                    final needsAdjust = _verseStartController.text != start.toString();
                    if (needsAdjust) {
                      _verseStartController.text = start.toString();
                      _verseStartController.selection = TextSelection.collapsed(offset: _verseStartController.text.length);
                      setState(() { _verseStartAdjusted = true; });
                      _verseStartHintTimer?.cancel();
                      _verseStartHintTimer = Timer(const Duration(milliseconds: 1200), () {
                        if (mounted) setState(() { _verseStartAdjusted = false; });
                      });
                    }
                    controller.setVerseRange(start, end);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('–', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: TextField(
                  controller: _verseEndController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '${LearnWordsConstants.verseToLabel} (1–$maxVerses)',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _verseEndAdjusted
                            ? Colors.redAccent.withOpacity(0.7)
                            : Theme.of(context).dividerColor,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _verseEndAdjusted
                            ? Colors.redAccent
                            : AppTheme.primaryColor,
                        width: 1.5,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    suffixIcon: _verseEndAdjusted
                        ? const Icon(Icons.error_outline, size: 16, color: Colors.redAccent)
                        : null,
                  ),
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      return;
                    }
                    int end = int.tryParse(value) ?? LearnWordsConstants.defaultVerseEnd;
                    int start = int.tryParse(_verseStartController.text) ?? LearnWordsConstants.defaultVerseStart;
                    // Clamp
                    if (end < 1) end = 1;
                    if (end > maxVerses) end = maxVerses;
                    // Ensure end >= start
                    if (end < start) {
                      start = end;
                      _verseStartController.text = start.toString();
                      _verseStartController.selection = TextSelection.collapsed(offset: _verseStartController.text.length);
                    }
                    final needsAdjust = _verseEndController.text != end.toString();
                    if (needsAdjust) {
                      _verseEndController.text = end.toString();
                      _verseEndController.selection = TextSelection.collapsed(offset: _verseEndController.text.length);
                      setState(() { _verseEndAdjusted = true; });
                      _verseEndHintTimer?.cancel();
                      _verseEndHintTimer = Timer(const Duration(milliseconds: 1200), () {
                        if (mounted) setState(() { _verseEndAdjusted = false; });
                      });
                    }
                    controller.setVerseRange(start, end);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Single Start button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: canStart
                ? () {
                    if (isWordsMode) {
                      controller.startCustomWordQuiz();
                    } else {
                      controller.startVerseRangeQuiz();
                    }
                  }
                : null,
            icon: Icon(isWordsMode ? Icons.quiz : Icons.list_alt, size: 18),
            label: const Text('Оғоз кардан'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVerses(LearnWordsState state, LearnWordsController controller) {
    final widgets = <Widget>[];

    for (int i = 0; i < state.versesLoaded && i < state.verses.length; i++) {
      final verse = state.verses[i];
      final words = state.wordByWord[verse.uniqueKey] ?? [];

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse header with quiz button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ояти ${verse.verseNumber}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                          ),
                    ),
                    // Minimalistic quiz button
                    IconButton(
                      onPressed: () => controller.startSingleVerseQuiz(verse),
                      icon: const Icon(Icons.quiz, size: 20),
                      tooltip: 'Санҷиди ин оят',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.all(6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Word-by-word display with stacked Arabic and Tajik
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 10,
                      children: words.map((word) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Arabic word
                              Text(
                                word.arabic,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontFamily: 'Noto_Naskh_Arabic',
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                              // Tajik translation
                              if (word.farsi != null && word.farsi!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    word.farsi!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          height: 1.1,
                                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildQuizScreen(LearnWordsState state, LearnWordsController controller) {
    if (state.quizWords.isEmpty) {
      return const Center(child: Text('Ҳеҷ калимае нест'));
    }

    // Show results if requested
    if (state.showQuizResults) {
      return _buildQuizResults(state, controller);
    }

    final currentWord = state.quizWords[state.currentQuizIndex];
    final options = controller.generateQuizOptions();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Quiz progress with indicator
          Column(
            children: [
              Text(
                'Калима ${state.currentQuizIndex + 1} аз ${state.quizWords.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              CircularProgressIndicator(
                value: (state.currentQuizIndex + 1) / state.quizWords.length,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 4,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Arabic word (large, centered, RTL)
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  currentWord.arabic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto_Naskh_Arabic',
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isCorrect = option == currentWord.translation;
                final isSelected = state.lastCorrectAnswer == index;
                final alreadyAnswered = state.quizAnswers.containsKey(state.currentQuizIndex);

                Color? textColor;
                Widget? trailingIcon;

                if (alreadyAnswered && state.lastCorrectAnswer != null) {
                  if (isCorrect) {
                    textColor = Colors.green.shade900;
                    trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
                  } else if (isSelected) {
                    textColor = Colors.red.shade900;
                    trailingIcon = const Icon(Icons.cancel, color: Colors.red);
                  } else {
                    textColor = Colors.grey.shade600;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton(
                    onPressed: alreadyAnswered
                        ? null
                        : () {
                            controller.setLastCorrectAnswer(index);
                            if (isCorrect) {
                              if (state.currentQuizIndex < state.quizWords.length - 1) {
                                // Not the last question - auto-advance
                                Future.delayed(const Duration(milliseconds: 1200), () {
                                  if (mounted && state.currentQuizIndex < state.quizWords.length - 1) {
                                    controller.nextQuiz();
                                  }
                                });
                              } else {
                                // Last question - show results after delay
                                Future.delayed(const Duration(milliseconds: 1500), () {
                                  if (mounted) {
                                    controller.showQuizResults();
                                  }
                                });
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          option,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          trailingIcon,
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.currentQuizIndex > 0 ? () => controller.previousQuiz() : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Ақиб'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.allQuestionsAnswered()
                      ? () {
                          controller.showQuizResults();
                        }
                      : (state.currentQuizIndex < state.quizWords.length - 1) && 
                          state.quizAnswers.containsKey(state.currentQuizIndex)
                      ? () {
                          controller.nextQuiz();
                        }
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(controller.allQuestionsAnswered() 
                          ? 'Натиҷа' 
                          : 'Баъдӣ'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Back button
          OutlinedButton(
            onPressed: () => controller.endQuiz(),
            child: const Text('Бозгашт ба сура'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResults(LearnWordsState state, LearnWordsController controller) {
    final score = controller.getQuizScore();
    final total = state.quizAnswers.length;
    final percentage = controller.getQuizPercentage();

    Color resultColor;
    String resultEmoji;
    String resultMessage;
    
    if (percentage >= 80) {
      resultColor = Colors.green;
      resultEmoji = '🎉';
      resultMessage = 'Офарин! Пешравиҳо муборак!';
    } else if (percentage >= 60) {
      resultColor = Colors.blue;
      resultEmoji = '👍';
      resultMessage = 'Бад не. Кӯшиш мекунем аз ин беҳтар шавад!';
    } else {
      resultColor = Colors.red;
      resultEmoji = '💪';
      resultMessage = 'Ноумед намешавем! Боз дубора кӯшиш мекунем!';
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Results Card
        Card(
          elevation: 6,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  resultEmoji,
                  style: const TextStyle(fontSize: 72),
                ),
                const SizedBox(height: 16),
                Text(
                  'Натиҷаҳои санҷиш',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[800]
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                  strokeWidth: 12,
                ),
                const SizedBox(height: 24),
                Text(
                  '${score.toString()} аз ${total.toString()}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: resultColor,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  resultMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Review answers section
        Text(
          'Баррасии ҷавобҳо',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // List of all answers
        ...List.generate(state.quizWords.length, (index) {
          final word = state.quizWords[index];
          final isCorrect = state.quizAnswers[index] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            word.arabic,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Noto_Naskh_Arabic',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.translation,
                          style: TextStyle(
                            color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Action buttons
        OutlinedButton.icon(
          onPressed: () {
            controller.hideQuizResults();
          },
          icon: const Icon(Icons.replay),
          label: const Text('Бозгашт ба санҷиш'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => controller.endQuiz(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Бозгашт ба сура'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineWarningBanner(LearnWordsState state, LearnWordsController controller) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.orange.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LearnWordsConstants.offlineTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LearnWordsConstants.offlineWordByWordMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.orange.shade700,
              onPressed: () {
                if (state.selectedSurah != null) {
                  controller.selectSurah(state.selectedSurah!);
                }
              },
              tooltip: 'Дубора кӯшиш',
            ),
          ],
        ),
      ),
    );
  }
}

