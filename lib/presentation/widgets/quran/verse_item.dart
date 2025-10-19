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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 32.0 : 20.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? colorScheme.primaryContainer.withOpacity(0.1)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Arabic Text
              Text(
                widget.verse.arabicText,
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 2.0,
                  fontSize: 26,
                  fontFamily: 'Amiri',
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),

              const SizedBox(height: 16),

              // Transliteration
              if (widget.showTransliteration && widget.verse.transliteration != null) ...[
                Text(
                  widget.verse.transliteration!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Translation
              Text(
                widget.translationTextOverride ?? widget.verse.tajikText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  fontSize: 18,
                  letterSpacing: 0.2,
                  color: colorScheme.onSurface.withOpacity(0.9),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тафсир',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.verse.tafsir!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Verse number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.verse.surahId}:${widget.verse.verseNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bookmark
                  _buildActionButton(
                    icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
                    tooltip: _isBookmarked ? 'Нест кардан' : 'Захира кардан',
                    onPressed: _toggleBookmark,
                    color: _isBookmarked ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),

                  // Play audio
                  _buildActionButton(
                    icon: Icons.play_circle_outline,
                    tooltip: 'Пахш кардан',
                    onPressed: widget.onPlayAudio,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),

                  const Spacer(),

                  // Tafsir toggle
                  if (widget.verse.tafsir != null)
                    TextButton.icon(
                      onPressed: () {
                        if (widget.onToggleTafsir != null) {
                          widget.onToggleTafsir!();
                        } else {
                          setState(() {
                            _isExpanded = !(widget.isTafsirOpen ?? _isExpanded);
                          });
                        }
                      },
                      icon: Icon(
                        (widget.isTafsirOpen ?? _isExpanded)
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                      label: Text(
                        'Тафсир',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      child: IconButton(
        icon: Icon(icon),
        iconSize: 22,
        color: color,
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
