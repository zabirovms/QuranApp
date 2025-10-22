import 'package:flutter/material.dart';
import '../../data/models/quiz_session_model.dart';

/// Widget for quiz mode selection
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 16),
            
            // Mode selection
            _buildModeSelection(context),
            const SizedBox(height: 16),
            
            // Surah selection (if applicable)
            if (selectedMode == QuizMode.surah && onSurahChanged != null)
              _buildSurahSelection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Танзимоти бозӣ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Намуди бозӣ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: QuizMode.values.map((mode) {
            final isSelected = selectedMode == mode;
            return _buildModeChip(context, mode, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModeChip(BuildContext context, QuizMode mode, bool isSelected) {
    return FilterChip(
      label: Text(_getModeLabel(mode)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onModeChanged(mode);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      avatar: Icon(
        _getModeIcon(mode),
        size: 18,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
    );
  }

  Widget _buildSurahSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сураи интихобшуда',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedSurahNumber,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Сураро интихоб кунед',
          ),
          items: List.generate(114, (index) {
            final surahNumber = index + 1;
            return DropdownMenuItem(
              value: surahNumber,
              child: Text('Сураи $surahNumber'),
            );
          }),
          onChanged: onSurahChanged,
        ),
      ],
    );
  }

  String _getModeLabel(QuizMode mode) {
    switch (mode) {
      case QuizMode.random:
        return 'Тасодуфӣ';
      case QuizMode.surah:
        return 'Аз сура';
      case QuizMode.daily:
        return 'Рӯзона';
      case QuizMode.review:
        return 'Такрорӣ';
    }
  }

  IconData _getModeIcon(QuizMode mode) {
    switch (mode) {
      case QuizMode.random:
        return Icons.shuffle;
      case QuizMode.surah:
        return Icons.book;
      case QuizMode.daily:
        return Icons.today;
      case QuizMode.review:
        return Icons.refresh;
    }
  }
}

/// Widget for quiz settings and configuration
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Танзимоти иловагӣ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Word count slider
            _buildWordCountSlider(context),
            const SizedBox(height: 16),
            
            // Toggle switches
            _buildToggleSwitches(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCountSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Миқдори калимаҳо: ${widget.wordCount}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: widget.wordCount.toDouble(),
          min: 5,
          max: 50,
          divisions: 9,
          label: '${widget.wordCount}',
          onChanged: (value) {
            widget.onWordCountChanged(value.round());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '5',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '50',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleSwitches(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Гузаронидани ҷавобҳо'),
          subtitle: const Text('Ҷавобҳоро ҳар як савол баъд аз ҷавобдиҳӣ тағйир диҳед'),
          value: widget.shuffleOptions,
          onChanged: widget.onShuffleOptionsChanged,
          secondary: const Icon(Icons.shuffle),
        ),
        SwitchListTile(
          title: const Text('Нишон додани транслитератсия'),
          subtitle: const Text('Транслитератсияи калимаҳоро нишон диҳед'),
          value: widget.showTransliteration,
          onChanged: widget.onShowTransliterationChanged,
          secondary: const Icon(Icons.text_fields),
        ),
      ],
    );
  }
}
