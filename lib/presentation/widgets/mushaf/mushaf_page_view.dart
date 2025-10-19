import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mushaf_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/mushaf_models.dart';
import '../../../core/theme/app_theme.dart';

class MushafPageView extends ConsumerWidget {
  final int pageNumber;

  const MushafPageView({
    super.key,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(mushafPageProvider(pageNumber));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth > 600 ? 80.0 : 48.0;

    return pageAsync.when(
      data: (page) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildPageHeader(context, page),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: _buildPageContent(context, page),
              ),
            ),
            const SizedBox(height: 16),
            _buildPageFooter(context, page),
          ],
        ),
      ),
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          message: 'Хато: $error',
          onRetry: () => ref.refresh(mushafPageProvider(pageNumber)),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, MushafPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'جُزۡءُ ${_toArabicNumerals(page.juz)}',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 12,
            color: isDark 
                ? Colors.grey[400]
                : AppTheme.textHintColor,
            fontWeight: FontWeight.normal,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildPageContent(BuildContext context, MushafPage page) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildContentWidgets(page, context),
    );
  }

  List<Widget> _buildContentWidgets(MushafPage page, BuildContext context) {
    final widgets = <Widget>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int currentSurahNumber = -1;
    final List<InlineSpan> currentParagraphSpans = [];
    bool isFirstVerseOfSurah = false;

    void flushParagraph() {
      if (currentParagraphSpans.isNotEmpty) {
        widgets.add(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(children: List.from(currentParagraphSpans)),
              textAlign: isFirstVerseOfSurah ? TextAlign.center : TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                color: isDark 
                    ? AppTheme.arabicTextColorDark 
                    : AppTheme.arabicTextColor,
                height: 2.2,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
        currentParagraphSpans.clear();
        isFirstVerseOfSurah = false;
      }
    }

    for (int i = 0; i < page.verses.length; i++) {
      final verse = page.verses[i];

      if (verse.numberInSurah == 1) {
        flushParagraph();

        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 12));
        }

        widgets.add(_buildSurahHeader(context, verse.surahName, verse.surahNumber));
        widgets.add(const SizedBox(height: 8));
        currentSurahNumber = verse.surahNumber;

        isFirstVerseOfSurah = true;
        currentParagraphSpans.add(
          TextSpan(
            text: '${verse.arabicText} ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
        
        currentParagraphSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildVerseNumber(context, verse.numberInSurah),
            ),
          ),
        );
        currentParagraphSpans.add(const TextSpan(text: ' '));
        
        flushParagraph();
      } else {
        currentParagraphSpans.add(
          TextSpan(text: '${verse.arabicText} '),
        );

        currentParagraphSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildVerseNumber(context, verse.numberInSurah),
            ),
          ),
        );

        currentParagraphSpans.add(const TextSpan(text: ' '));
      }
    }

    flushParagraph();

    return widgets;
  }

  Widget _buildSurahHeader(BuildContext context, String surahName, int surahNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          surahName,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildVerseNumber(BuildContext context, int number) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.primary.withOpacity(0.6);
    
    return Text(
      '﴿${_toArabicNumerals(number)}﴾',
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 20,
        color: color,
        fontWeight: FontWeight.normal,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildPageFooter(BuildContext context, page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Text(
        _toArabicNumerals(pageNumber),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: isDark 
              ? Colors.grey[400]
              : AppTheme.textHintColor,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join('');
  }
}
