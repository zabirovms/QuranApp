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

    return pageAsync.when(
      data: (page) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(context, page),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildPageContent(context, page, constraints),
                ),
                const SizedBox(height: 12),
                _buildPageFooter(context, page),
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

  // --------------------- HEADER ---------------------
  Widget _buildPageHeader(BuildContext context, MushafPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String surahName = page.verses.isNotEmpty ? page.verses.first.surahName : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'جُزۡءُ ${_toArabicNumerals(page.juz)}',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 12,
            color: isDark ? Colors.grey[400] : AppTheme.textHintColor,
            fontWeight: FontWeight.normal,
          ),
          textDirection: TextDirection.rtl,
        ),
        Text(
          surahName,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 12,
            color: isDark ? Colors.grey[400] : AppTheme.textHintColor,
            fontWeight: FontWeight.normal,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  // --------------------- PAGE CONTENT ---------------------
  // --------------------- PAGE CONTENT ---------------------
  Widget _buildPageContent(BuildContext context, MushafPage page, BoxConstraints constraints) {
    final widgets = <Widget>[];

    if (page.verses.isEmpty) return const SizedBox();

    final firstVerse = page.verses.first;

    // Add Surah header only at the start of Surah
    if (firstVerse.numberInSurah == 1) {
      widgets.add(_buildSurahHeader(context, firstVerse.surahName));
    }

    // Extract Bismillah if not Surah 1
    const bismillahText = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ';
    String remainingText = '';
    if (firstVerse.arabicText.startsWith(bismillahText) && firstVerse.surahNumber != 1) {
      widgets.add(const SizedBox(height: 6));
      widgets.add(_buildBismillah(context, bismillahText));
      widgets.add(const SizedBox(height: 6));
      remainingText = firstVerse.arabicText.replaceFirst(bismillahText, '').trim();
    } else {
      remainingText = firstVerse.arabicText;
    }

    // Build continuous text for all verses
    final textSpans = <InlineSpan>[];
    if (remainingText.isNotEmpty) {
      textSpans.add(TextSpan(text: '$remainingText '));
      textSpans.add(_buildEndOfAyahSpan(firstVerse.numberInSurah));
    }

    for (int i = 1; i < page.verses.length; i++) {
      final verse = page.verses[i];
      textSpans.add(TextSpan(text: '${verse.arabicText} '));
      textSpans.add(_buildEndOfAyahSpan(verse.numberInSurah));
    }

    widgets.add(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: textSpans),
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            height: 1.8,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.arabicTextColorDark
                : AppTheme.arabicTextColor,
          ),
        ),
      ),
    );

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        child: SizedBox(width: constraints.maxWidth, child: Column(children: widgets)),
      ),
    );
  }


  // --------------------- SURAH HEADER ---------------------
  Widget _buildSurahHeader(BuildContext context, String surahName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        '۞ $surahName ۞',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // --------------------- BISMILLAH ---------------------
  Widget _buildBismillah(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // --------------------- END-OF-AYAH SPAN ---------------------
  InlineSpan _buildEndOfAyahSpan(int number) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Text(
        '۝${_toArabicNumerals(number)} ',
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --------------------- FOOTER ---------------------
  Widget _buildPageFooter(BuildContext context, MushafPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        _toArabicNumerals(pageNumber),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: isDark ? Colors.grey[400] : AppTheme.textHintColor,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // --------------------- ARABIC NUMERALS ---------------------
  String _toArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join('');
  }
}
