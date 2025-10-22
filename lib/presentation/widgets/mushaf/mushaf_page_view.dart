import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/svg_mushaf_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/svg_mushaf_models.dart';
import '../../../core/theme/app_theme.dart';

class MushafPageView extends ConsumerWidget {
  final int pageNumber;

  const MushafPageView({
    super.key,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Building MushafPageView for page $pageNumber');
    final pageAsync = ref.watch(svgMushafPageProvider(pageNumber));
    
    print('Page async state: ${pageAsync.runtimeType}');
    if (pageAsync.hasValue) {
      print('Page has value: ${pageAsync.value?.pageNumber}');
    }
    if (pageAsync.hasError) {
      print('Page has error: ${pageAsync.error}');
    }

    return pageAsync.when(
      data: (page) {
        print('Rendering data for page ${page.pageNumber}');
        return Container(
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
        );
      },
      loading: () {
        print('Showing loading state');
        return const Center(child: LoadingWidget());
      },
      error: (error, stack) {
        print('Showing error state: $error');
        return Center(
          child: CustomErrorWidget(
            message: 'Хато: $error',
            onRetry: () => ref.refresh(svgMushafPageProvider(pageNumber)),
          ),
        );
      },
    );
  }

  // --------------------- HEADER ---------------------
  Widget _buildPageHeader(BuildContext context, SvgMushafPage page) {
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
  Widget _buildPageContent(BuildContext context, SvgMushafPage page) {
    print('Building page content for page ${page.pageNumber}');
    print('Page isLoaded: ${page.isLoaded}');
    print('SVG content length: ${page.svgContent.length}');
    print('Has valid SVG: ${page.hasValidSvgContent}');
    
    if (!page.isLoaded || !page.hasValidSvgContent) {
      print('Showing loading widget - isLoaded: ${page.isLoaded}, hasValidSvg: ${page.hasValidSvgContent}');
      return const Center(
        child: LoadingWidget(),
      );
    }

    print('Showing SVG content');
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: SvgPicture.string(
        page.svgContent,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Center(
          child: LoadingWidget(),
        ),
      ),
    );
  }

  // --------------------- FOOTER ---------------------
  Widget _buildPageFooter(BuildContext context, SvgMushafPage page) {
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
