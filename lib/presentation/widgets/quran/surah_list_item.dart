import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/surah_model.dart';

class SurahListItem extends ConsumerStatefulWidget {
  final SurahModel surah;
  final VoidCallback? onTap;

  const SurahListItem({
    super.key,
    required this.surah,
    this.onTap,
  });

  @override
  ConsumerState<SurahListItem> createState() => _SurahListItemState();
}

class _SurahListItemState extends ConsumerState<SurahListItem> {
  bool _showArabicName = true;

  void _toggleDisplay() {
    setState(() {
      _showArabicName = !_showArabicName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: widget.onTap ?? () => context.push('/surah/${widget.surah.number}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Surah number (outlined circle, no fill)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${widget.surah.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Surah details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tajik name (Сураи {nameTajik})
                    Text(
                      'Сураи ${widget.surah.nameTajik}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Revelation type (under Tajik name, always visible)
                    Text(
                      widget.surah.revelationType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Verses count (localized)
                    Text(
                      '${widget.surah.versesCount} оят',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arabic name or revelation type (toggleable - on right side)
              GestureDetector(
                onTap: _toggleDisplay,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    _showArabicName ? widget.surah.nameArabic : widget.surah.revelationType,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: _showArabicName ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
