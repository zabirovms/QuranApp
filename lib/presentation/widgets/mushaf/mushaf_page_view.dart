import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mushaf_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import 'mushaf_verse_inline.dart';
import 'mushaf_surah_header.dart';

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
          color: const Color(0xFFF5F1E8),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPageHeader(page),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: _buildPageContent(context, page),
              ),
            ),
            const SizedBox(height: 8),
            _buildPageFooter(page),
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

  Widget _buildPageHeader(page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'جُزۡءُ ${_toArabicNumerals(page.juz)}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        if (page.surahsOnPage.isNotEmpty)
          Text(
            'سُورَةُ ${page.verses.first.surahName}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: Color(0xFF2C1810),
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
      ],
    );
  }

  Widget _buildPageContent(BuildContext context, page) {
    final verseWidgets = <Widget>[];
    
    for (int i = 0; i < page.verses.length; i++) {
      final verse = page.verses[i];
      
      if (verse.numberInSurah == 1) {
        verseWidgets.add(MushafVerseInline(verse: verse));
      } else {
        verseWidgets.add(MushafVerseInline(verse: verse));
      }
    }

    final contentWidgets = <Widget>[];
    int currentIndex = 0;
    
    for (int i = 0; i < page.verses.length; i++) {
      final verse = page.verses[i];
      
      if (verse.numberInSurah == 1) {
        if (contentWidgets.isNotEmpty) {
          contentWidgets.add(const SizedBox(height: 12));
        }
        
        contentWidgets.add(MushafSurahHeader(
          surahName: verse.surahName,
          surahNumber: verse.surahNumber,
        ));
        contentWidgets.add(const SizedBox(height: 8));
      }
      
      if (i == 0 || verse.numberInSurah == 1 || (i > 0 && page.verses[i - 1].surahNumber != verse.surahNumber)) {
        final surahVerses = <Widget>[];
        int j = i;
        while (j < page.verses.length && page.verses[j].surahNumber == verse.surahNumber) {
          surahVerses.add(MushafVerseInline(verse: page.verses[j]));
          j++;
        }
        
        contentWidgets.add(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: surahVerses,
            ),
          ),
        );
        
        i = j - 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: contentWidgets,
    );
  }

  Widget _buildPageFooter(page) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _toArabicNumerals(pageNumber),
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            color: Color(0xFF2C1810),
            fontWeight: FontWeight.bold,
          ),
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
