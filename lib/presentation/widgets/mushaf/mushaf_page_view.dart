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

    return pageAsync.when(
      data: (page) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildPageHeader(page),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildPageContent(context, page, constraints),
                ),
                const SizedBox(height: 8),
                _buildPageFooter(page),
              ],
            );
          },
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

  Widget _buildPageHeader(MushafPage page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'جُزۡءُ ${_toArabicNumerals(page.juz)}',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 12,
            color: AppTheme.textHintColor,
            fontWeight: FontWeight.normal,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildPageContent(BuildContext context, MushafPage page, BoxConstraints constraints) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: constraints.maxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildContentWidgets(page),
        ),
      ),
    );
  }

  List<Widget> _buildContentWidgets(MushafPage page) {
    final widgets = <Widget>[];
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
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: AppTheme.arabicTextColor,
                height: 1.8,
                letterSpacing: 0.2,
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

        widgets.add(_buildSurahHeader(verse.surahName, verse.surahNumber));
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
              child: _buildVerseNumber(verse.numberInSurah),
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
              child: _buildVerseNumber(verse.numberInSurah),
            ),
          ),
        );

        currentParagraphSpans.add(const TextSpan(text: ' '));
      }
    }

    flushParagraph();

    return widgets;
  }

  Widget _buildSurahHeader(String surahName, int surahNumber) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            AppTheme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOrnament(),
          const SizedBox(width: 12),
          Text(
            surahName,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 12),
          _buildOrnament(),
        ],
      ),
    );
  }

  Widget _buildOrnament() {
    return const Icon(
      Icons.auto_awesome,
      color: Colors.white,
      size: 14,
    );
  }

  Widget _buildVerseNumber(int number) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 1.2,
        ),
      ),
      child: Text(
        _toArabicNumerals(number),
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 12,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildPageFooter(page) {
    return Center(
      child: Text(
        _toArabicNumerals(pageNumber),
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: AppTheme.textHintColor,
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
