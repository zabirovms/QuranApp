import 'package:flutter/material.dart';

class MushafSurahHeader extends StatelessWidget {
  final String surahName;
  final int surahNumber;

  const MushafSurahHeader({
    super.key,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD4AF37),
            Color(0xFFE8C547),
            Color(0xFFD4AF37),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
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
              fontSize: 20,
              color: Color(0xFF2C1810),
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
      color: Color(0xFF2C1810),
      size: 16,
    );
  }
}
