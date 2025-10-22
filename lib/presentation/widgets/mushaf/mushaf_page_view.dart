import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mushaf_15_lines_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/uthmani_models.dart';
import '../../../core/theme/app_theme.dart';

class MushafPageView extends ConsumerWidget {
  final int pageNumber;

  const MushafPageView({
    super.key,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(mushaf15LinesPageProvider(pageNumber));

    return pageAsync.when(
      data: (page) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPageHeader(context, page),
            const SizedBox(height: 4),
            Expanded(
              child: _buildPageContent(context, page),
            ),
            const SizedBox(height: 4),
            _buildPageFooter(context, page),
          ],
        ),
      ),
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          message: 'Хато: $error',
          onRetry: () => ref.refresh(mushaf15LinesPageProvider(pageNumber)),
        ),
      ),
    );
  }

  // --------------------- HEADER ---------------------
  Widget _buildPageHeader(BuildContext context, MushafPage15Lines page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String surahName = page.surahNames.isNotEmpty ? page.surahNames.first : '';

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
  Widget _buildPageContent(BuildContext context, MushafPage15Lines page) {
    if (page.lines.isEmpty) return const SizedBox();

    // Each line gets Expanded for equal spacing (15 lines per page)
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: page.lines
          .map((line) => Expanded(child: _buildLine(context, line)))
          .toList(),
    );
  }

  // --------------------- LINE BUILDER ---------------------
  Widget _buildLine(BuildContext context, MushafLine line) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (line.isSurahName) {
      return _buildSurahHeader(context, line.text);
    } else if (line.isBismillah) {
      return _buildBismillah(context, line.text);
    } else {
      return _buildAyahLine(context, line, isDark);
    }
  }

  // --------------------- AYAH LINE ---------------------
  // --------------------- AYAH LINE ---------------------
  Widget _buildAyahLine(BuildContext context, MushafLine line, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          line.text,
          textAlign: line.isCentered ? TextAlign.center : TextAlign.justify,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 1.6,
            color: isDark
                ? AppTheme.arabicTextColorDark
                : AppTheme.arabicTextColor,
          ),
        ),
      ),
    );
  }

  // --------------------- SURAH HEADER ---------------------
  Widget _buildSurahHeader(BuildContext context, String surahName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '۞ $surahName ۞',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  // --------------------- BISMILLAH ---------------------
  Widget _buildBismillah(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  // --------------------- FOOTER ---------------------
  Widget _buildPageFooter(BuildContext context, MushafPage15Lines page) {
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
