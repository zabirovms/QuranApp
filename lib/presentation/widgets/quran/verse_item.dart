import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/verse_model.dart';
import '../../../data/services/settings_service.dart';
import '../translation_selection_dialog.dart';
import '../../providers/quran_provider.dart';

class VerseItem extends ConsumerStatefulWidget {
  final VerseModel verse;
  final bool showTransliteration;
  final bool showTafsir;
  final bool isWordByWordMode;
  final List<Map<String, String>>? wordByWordTokens; // [{arabic, meaning}]
  final String? translationTextOverride;
  final ValueChanged<String>? onTranslationChanged;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onToggleActions;
  final bool isBookmarked;
  final bool isHighlighted;
  final bool? isTafsirOpen;
  final VoidCallback? onToggleTafsir;
  final bool isPlaying;
  final bool showExtraActions;
  final bool showOnlyArabic;

  const VerseItem({
    super.key,
    required this.verse,
    this.showTransliteration = true,
    this.showTafsir = false,
    this.isWordByWordMode = false,
    this.wordByWordTokens,
    this.translationTextOverride,
    this.onTranslationChanged,
    this.onTap,
    this.onBookmark,
    this.onPlayAudio,
    this.onToggleActions,
    this.isBookmarked = false,
    this.isHighlighted = false,
    this.isTafsirOpen,
    this.onToggleTafsir,
    this.isPlaying = false,
    this.showExtraActions = false,
    this.showOnlyArabic = false,
  });

  @override
  ConsumerState<VerseItem> createState() => _VerseItemState();
}

class _VerseItemState extends ConsumerState<VerseItem> {
  bool _isExpanded = false;
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
  }

  @override
  void didUpdateWidget(VerseItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync bookmark state when widget prop changes
    if (oldWidget.isBookmarked != widget.isBookmarked) {
      _isBookmarked = widget.isBookmarked;
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    if (widget.onBookmark != null) {
      widget.onBookmark!();
    }
  }

  String _getArabicTextWithEndSymbol() {
    // Convert verse number to Arabic-Indic numerals
    final arabicVerseNumber = _convertToArabicNumerals(widget.verse.verseNumber);
    
    // Remove any trailing newlines and append the end-of-ayah symbol with verse number
    final cleanArabicText = widget.verse.arabicText.trim();
    return '$cleanArabicText\u06dd$arabicVerseNumber';
  }

  String _convertToArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    if (number == 0) return arabicNumerals[0];
    
    String result = '';
    while (number > 0) {
      result = arabicNumerals[number % 10] + result;
      number ~/= 10;
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (widget.isPlaying || widget.isHighlighted)
            ? colorScheme.primaryContainer.withOpacity(0.25)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: (widget.isPlaying || widget.isHighlighted)
            ? Border.all(color: colorScheme.primary.withOpacity(0.6), width: 2)
            : Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: (widget.isPlaying || widget.isHighlighted)
                ? colorScheme.primary.withOpacity(0.12)
                : colorScheme.shadow.withOpacity(0.05),
            blurRadius: (widget.isPlaying || widget.isHighlighted) ? 10 : 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () {
          if (widget.onToggleActions != null) {
            widget.onToggleActions!();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Arabic Text or Word-by-Word Tokens
              if (widget.isWordByWordMode && (widget.wordByWordTokens?.isNotEmpty ?? false))
                // Word-by-word display replacing Arabic text
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      alignment: WrapAlignment.end,
                      textDirection: TextDirection.rtl,
                      children: [
                        for (final t in widget.wordByWordTokens!)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  t['arabic'] ?? '',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontFamily: 'Amiri',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if ((t['meaning'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    t['meaning']!,
                                    textDirection: TextDirection.ltr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                // Regular Arabic text display
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _getArabicTextWithEndSymbol(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 1.4,
                        fontSize: 22,
                        fontFamily: 'Amiri',
                        letterSpacing: 0.0,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              // Transliteration
              if (widget.showTransliteration && widget.verse.transliteration != null)
                Text(
                  widget.verse.transliteration!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const SizedBox(height: 6),

              // Translation (hidden if showOnlyArabic is true)
              if (!widget.showOnlyArabic)
                Text(
                  widget.translationTextOverride ?? widget.verse.tajikText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.left,
                ),


              // Tafsir
              if (((widget.isTafsirOpen ?? _isExpanded)) && widget.verse.tafsir != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onToggleTafsir != null) {
                      widget.onToggleTafsir!();
                    } else {
                      setState(() {
                        _isExpanded = !(_isExpanded);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тафсир:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.verse.tafsir!,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Action Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Verse number at bottom-left with playing indicator
                  Row(
                    children: [
                      Text(
                        '${widget.verse.surahId}:${widget.verse.verseNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),

                  // Play/Pause audio (always visible)
                  _buildActionButton(
                    icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    tooltip: widget.isPlaying ? 'Пауза' : 'Play Audio',
                    onPressed: widget.onPlayAudio,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),

                  // Bookmark (always visible)
                  _buildActionButton(
                    icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    tooltip: _isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                    onPressed: _toggleBookmark,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),

                  // Copy (always visible)
                  _buildActionButton(
                    icon: Icons.copy,
                    tooltip: 'Нусхабардорӣ',
                    onPressed: () async {
                      final cleanArabicText = widget.verse.arabicText.trim();
                      final text =
                          '{$cleanArabicText}\n\n${widget.verse.tajikText}\n\n(Қуръон ${widget.verse.surahId}:${widget.verse.verseNumber})';
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Оят нусхабардорӣ карда шуд'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),

                  // Share (always visible)
                  _buildActionButton(
                    icon: Icons.share,
                    tooltip: 'Мубодила',
                    onPressed: () async {
                      final cleanArabicText = widget.verse.arabicText.trim();
                      final text =
                          '{$cleanArabicText}\n\n${widget.verse.tajikText}\n\n(Қуръон ${widget.verse.surahId}:${widget.verse.verseNumber})';
                      await Share.share(text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Оят мубодила карда шуд'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),

                  // Translation Switch (always visible)
                  _buildActionButton(
                    icon: Icons.translate,
                    tooltip: 'Интихоби тарҷума',
                    onPressed: () async {
                      final s = SettingsService();
                      await s.init();
                      final currentLang = s.getTranslationLanguage();

                      if (!context.mounted) return;
                      final selectedLang = await showDialog<String>(
                        context: context,
                        builder: (context) => TranslationSelectionDialog(
                          currentTranslation: currentLang,
                          surahNumber: widget.verse.surahId,
                        ),
                      );

                      if (!context.mounted) return;
                      if (selectedLang != null) {
                        if (widget.onTranslationChanged != null) {
                          widget.onTranslationChanged!(selectedLang);
                        } else {
                          // Fallback to ensure verses reload with new translation
                          ref.invalidate(versesProvider(widget.verse.surahId));
                        }
                      }
                    },
                    color: colorScheme.onSurface,
                  ),

                  const Spacer(),

                  // Tafsir toggle - replaced icon with text
                  if (widget.verse.tafsir != null)
                    InkWell(
                      onTap: () {
                        if (widget.onToggleTafsir != null) {
                          widget.onToggleTafsir!();
                        } else {
                          setState(() {
                            _isExpanded = !(widget.isTafsirOpen ?? _isExpanded);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'тафсир',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}
