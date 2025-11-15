import 'package:flutter/material.dart';
import '../learn_words_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/verse_model.dart';
import '../../../../data/models/word_by_word_model.dart';

class VerseCard extends StatelessWidget {
  final VerseModel verse;
  final List<WordByWordModel> words;
  final VoidCallback onQuizPressed;

  const VerseCard({
    super.key,
    required this.verse,
    required this.words,
    required this.onQuizPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  LearnWordsLocalizations.buildVerseNumber(verse.verseNumber),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                        fontSize: LearnWordsConstants.verseHeaderFontSize,
                      ),
                ),
                IconButton(
                  onPressed: onQuizPressed,
                  icon: const Icon(
                    LearnWordsConstants.quizIcon,
                    size: LearnWordsConstants.quizIconSize,
                  ),
                  tooltip: LearnWordsConstants.quizTooltip,
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
            // Word-by-word display
            Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.topRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 10,
                  children: words.map((word) => _WordWidget(word: word)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordWidget extends StatelessWidget {
  final WordByWordModel word;

  const _WordWidget({required this.word});

  @override
  Widget build(BuildContext context) {
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
              fontSize: LearnWordsConstants.largeArabicFontSize,
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
  }
}
