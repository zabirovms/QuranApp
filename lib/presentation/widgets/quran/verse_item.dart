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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: widget.isHighlighted ? colorScheme.primaryContainer.withOpacity(0.35) : null,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse number and Arabic text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verse number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.verse.verseNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Arabic text
                  Expanded(
                    child: Text(
                      widget.verse.arabicText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 2.0,
                        fontSize: 20,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Transliteration directly under Arabic (if enabled)
              if (widget.showTransliteration && widget.verse.transliteration != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.verse.transliteration!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Translation (override if provided)
              Text(
                widget.translationTextOverride ?? widget.verse.tajikText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
              
              // (moved transliteration above translation)

              // Word by word tokens (if enabled)
              if (widget.isWordByWordMode && (widget.wordByWordTokens?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
              
              // Tafsir (lazy expand or globally enabled)
              if (((widget.isTafsirOpen ?? _isExpanded)) && widget.verse.tafsir != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onToggleTafsir != null) {
                      widget.onToggleTafsir!();
                    } else {
                      setState(() {
                        _isExpanded = false;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  // Play audio button
                  IconButton(
                    onPressed: widget.onPlayAudio,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Play Audio',
                  ),
                  
                  // Bookmark button
                  IconButton(
                    onPressed: widget.onBookmark,
                    icon: Icon(
                      widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: widget.isBookmarked ? colorScheme.primary : null,
                    ),
                    tooltip: widget.isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                  ),
                  
                  // Copy button
                  IconButton(
                    onPressed: () async {
                      final text = '${widget.verse.arabicText}\n\n${widget.verse.tajikText}\n\n(${widget.verse.surahId}:${widget.verse.verseNumber})';
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
                    icon: const Icon(Icons.copy),
                    tooltip: 'Нусхабардорӣ',
                  ),

                  // Share button (uses share_plus)
                  IconButton(
                    onPressed: () async {
                      final text = '${widget.verse.arabicText}\n\n${widget.verse.tajikText}\n\n(${widget.verse.surahId}:${widget.verse.verseNumber})';
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
                    icon: const Icon(Icons.share),
                    tooltip: 'Мубодила',
                  ),
                  
                  // Duplicate copy removed
                  
                  
                  const Spacer(),
                  
                  // Expand/collapse button for tafsir
                  if (widget.verse.tafsir != null)
                    IconButton(
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
                        (widget.isTafsirOpen ?? _isExpanded) ? Icons.expand_less : Icons.expand_more,
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
}
