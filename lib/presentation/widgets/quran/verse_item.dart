import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/verse_model.dart';

class VerseItem extends ConsumerStatefulWidget {
  final VerseModel verse;
  final bool showTransliteration;
  final bool showTafsir;
  final bool isWordByWordMode;
  final List<Map<String, String>>? wordByWordTokens; // [{arabic, meaning}]
  final String? translationTextOverride;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onPlayAudio;
  final bool isBookmarked;
  final bool isHighlighted;
  final bool? isTafsirOpen;
  final VoidCallback? onToggleTafsir;

  const VerseItem({
    super.key,
    required this.verse,
    this.showTransliteration = true,
    this.showTafsir = false,
    this.isWordByWordMode = false,
    this.wordByWordTokens,
    this.translationTextOverride,
    this.onTap,
    this.onBookmark,
    this.onPlayAudio,
    this.isBookmarked = false,
    this.isHighlighted = false,
    this.isTafsirOpen,
    this.onToggleTafsir,
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

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    if (widget.onBookmark != null) {
      widget.onBookmark!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? colorScheme.primaryContainer.withOpacity(0.2)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: widget.isHighlighted
            ? Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2)
            : Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Arabic Text
              Text(
                widget.verse.arabicText,
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 1.5, // reduced line height
                  fontSize: 22,
                  fontFamily: 'Amiri',
                  letterSpacing: 0.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
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

              // Translation
              Text(
                widget.translationTextOverride ?? widget.verse.tajikText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.justify,
              ),

              // Word by word tokens
              if (widget.isWordByWordMode && (widget.wordByWordTokens?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        for (final t in widget.wordByWordTokens!)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Chip(
                                label: Text(
                                  t['arabic'] ?? '',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              if ((t['meaning'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    t['meaning']!,
                                    textDirection: TextDirection.ltr,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],

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
                  // Verse number at bottom-left
                  Text(
                    '${widget.verse.surahId}:${widget.verse.verseNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Play audio
                  _buildActionButton(
                    icon: Icons.play_arrow,
                    tooltip: 'Play Audio',
                    onPressed: widget.onPlayAudio,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),

                  // Bookmark
                  _buildActionButton(
                    icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    tooltip: _isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                    onPressed: _toggleBookmark,
                    color: _isBookmarked ? colorScheme.primary : colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),

                  // Copy
                  _buildActionButton(
                    icon: Icons.copy,
                    tooltip: 'Нусхабардорӣ',
                    onPressed: () async {
                      final text =
                          '${widget.verse.arabicText}\n\n${widget.verse.tajikText}\n\n(${widget.verse.surahId}:${widget.verse.verseNumber})';
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

                  // Share
                  _buildActionButton(
                    icon: Icons.share,
                    tooltip: 'Мубодила',
                    onPressed: () async {
                      final text =
                          '${widget.verse.arabicText}\n\n${widget.verse.tajikText}\n\n(${widget.verse.surahId}:${widget.verse.verseNumber})';
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

                  const Spacer(),

                  // Tafsir toggle
                  if (widget.verse.tafsir != null)
                    _buildActionButton(
                      icon: (widget.isTafsirOpen ?? _isExpanded)
                          ? Icons.expand_less
                          : Icons.expand_more,
                      tooltip: 'Тафсир',
                      onPressed: () {
                        if (widget.onToggleTafsir != null) {
                          widget.onToggleTafsir!();
                        } else {
                          setState(() {
                            _isExpanded = !(widget.isTafsirOpen ?? _isExpanded);
                          });
                        }
                      },
                      color: colorScheme.onSurface,
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
        child: Container(
          padding: const EdgeInsets.all(6), // reduced padding
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
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
