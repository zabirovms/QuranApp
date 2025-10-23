import 'package:flutter/material.dart';
import '../../data/models/quiz_session_model.dart';

/// Widget for quiz mode selection - Action-focused design
class QuizModeSelectorWidget extends StatelessWidget {
  final QuizMode selectedMode;
  final Function(QuizMode) onModeChanged;
  final int? selectedSurahNumber;
  final Function(int?)? onSurahChanged;

  const QuizModeSelectorWidget({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.selectedSurahNumber,
    this.onSurahChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick mode selection buttons
            _buildModeButtons(context),
            
            // Surah selection (if applicable)
            if (selectedMode == QuizMode.surah && onSurahChanged != null) ...[
              const SizedBox(height: 12),
              _buildSurahSelector(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeButtons(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildModeButton(
                context,
                QuizMode.random,
                'Тасодуфӣ',
                Icons.shuffle,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeButton(
                context,
                QuizMode.daily,
                'Рӯзона',
                Icons.today,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildModeButton(
                context,
                QuizMode.surah,
                'Аз сура',
                Icons.book,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeButton(
                context,
                QuizMode.review,
                'Такрорӣ',
                Icons.refresh,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    QuizMode mode,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedMode == mode;
    
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.book,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedSurahNumber,
                isExpanded: true,
                hint: const Text('Сураро интихоб кунед'),
                items: List.generate(114, (index) {
                  final surahNumber = index + 1;
                  return DropdownMenuItem(
                    value: surahNumber,
                    child: Text('Сураи $surahNumber'),
                  );
                }),
                onChanged: onSurahChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for quiz settings and configuration - Action-focused design
class QuizSettingsWidget extends StatefulWidget {
  final int wordCount;
  final bool shuffleOptions;
  final bool showTransliteration;
  final Function(int) onWordCountChanged;
  final Function(bool) onShuffleOptionsChanged;
  final Function(bool) onShowTransliterationChanged;

  const QuizSettingsWidget({
    super.key,
    required this.wordCount,
    required this.shuffleOptions,
    required this.showTransliteration,
    required this.onWordCountChanged,
    required this.onShuffleOptionsChanged,
    required this.onShowTransliterationChanged,
  });

  @override
  State<QuizSettingsWidget> createState() => _QuizSettingsWidgetState();
}

class _QuizSettingsWidgetState extends State<QuizSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word count quick selector
            _buildWordCountSelector(context),
            const SizedBox(height: 12),
            
            // Quick toggle switches
            _buildQuickToggles(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCountSelector(BuildContext context) {
    return Column(
      children: [
        Text(
          'Миқдори калимаҳо',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.numbers,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: widget.wordCount.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  onChanged: (value) {
                    widget.onWordCountChanged(value.round());
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.wordCount}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickToggles(BuildContext context) {
    return Column(
      children: [
        _buildQuickToggle(
          context,
          title: 'Гузаронидани ҷавобҳо',
          value: widget.shuffleOptions,
          onChanged: widget.onShuffleOptionsChanged,
          icon: Icons.shuffle,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildQuickToggle(
          context,
          title: 'Транслитератсия',
          value: widget.showTransliteration,
          onChanged: widget.onShowTransliterationChanged,
          icon: Icons.text_fields,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildQuickToggle(
    BuildContext context, {
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? color : Colors.grey[300]!,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? color : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: value ? color : Colors.grey[700],
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
