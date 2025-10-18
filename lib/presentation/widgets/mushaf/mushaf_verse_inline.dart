import 'package:flutter/material.dart';
import '../../../data/models/mushaf_models.dart';

class MushafVerseInline extends StatelessWidget {
  final MushafVerse verse;

  const MushafVerseInline({
    super.key,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: RichText(
        textDirection: TextDirection.rtl,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24,
            color: Color(0xFF2C1810),
            height: 2.0,
            letterSpacing: 0.3,
          ),
          children: [
            if (verse.numberInSurah == 1 && verse.surahNumber != 9)
              const TextSpan(
                text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            TextSpan(
              text: verse.arabicText,
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildVerseNumber(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseNumber() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.5,
        ),
      ),
      child: Text(
        verse.arabicVerseNumber,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: Color(0xFFD4AF37),
          fontWeight: FontWeight.bold,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
