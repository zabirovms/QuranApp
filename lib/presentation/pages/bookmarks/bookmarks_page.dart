import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/bookmark_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/quran_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class BookmarksPage extends ConsumerWidget {
  final String userId;
  
  const BookmarksPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Хатбаракҳо'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (bookmarkState.bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => _showClearAllDialog(context, ref),
              tooltip: 'Clear all bookmarks',
            ),
        ],
      ),
      body: _buildBody(context, ref, bookmarkState, surahsAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BookmarkState bookmarkState,
    AsyncValue<List<dynamic>> surahsAsync,
  ) {
    if (bookmarkState.isLoading) {
      return const Center(
        child: LoadingWidget(height: 100),
      );
    }

    if (bookmarkState.error != null) {
      return Center(
        child: CustomErrorWidget(
          title: 'Хатоги дар хатбаракҳо',
          message: bookmarkState.error!,
          onRetry: () {
            ref.read(bookmarkNotifierProvider(userId).notifier).refreshBookmarks();
          },
        ),
      );
    }

    if (bookmarkState.bookmarks.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Bookmark count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${bookmarkState.bookmarks.length} хатбарак',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Bookmarks list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: bookmarkState.bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarkState.bookmarks[index];
              return _buildBookmarkItem(context, ref, bookmark, surahsAsync);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkItem(
    BuildContext context,
    WidgetRef ref,
    BookmarkModel bookmark,
    AsyncValue<List<dynamic>> surahsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () {
            context.go('/surah/${bookmark.surahNumber}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Surah and verse info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bookmark.surahNumber}:${bookmark.verseNumber}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookmark.surahName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeBookmark(context, ref, bookmark),
                      icon: const Icon(Icons.bookmark, color: Colors.red),
                      tooltip: 'Remove bookmark',
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Arabic text
                Text(
                  bookmark.arabicText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Amiri',
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                
                const SizedBox(height: 8),
                
                // Tajik translation
                Text(
                  bookmark.tajikText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Created date
                Text(
                  'Сохта шуд: ${_formatDate(bookmark.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ хатбараке нест',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оёти дӯстдоштаро хатбарак кунед',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Имрӯз';
    } else if (difference.inDays == 1) {
      return 'Дирӯз';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} рӯз пеш';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _removeBookmark(
    BuildContext context,
    WidgetRef ref,
    BookmarkModel bookmark,
  ) async {
    print('Bookmark to remove: ID=${bookmark.id}, verseKey=${bookmark.verseKey}, surah=${bookmark.surahNumber}:${bookmark.verseNumber}');
    
    final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
    
    // Try verse key-based removal first
    bool success = await notifier.removeBookmarkByVerseKey(bookmark.verseKey);
    
    // If that fails, try ID-based removal as fallback
    if (!success && bookmark.id > 0) {
      print('Verse key removal failed, trying ID-based removal');
      success = await notifier.removeBookmark(bookmark.id);
    }
    
    print('Remove bookmark success: $success');
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хатбарак хориҷ карда шуд'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хатоги дар хориҷ кардани хатбарак'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Хориҷ кардани ҳамаи хатбаракҳо'),
        content: const Text('Оё шумо мехоҳед ҳамаи хатбаракҳоро хориҷ кунед?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Бекор кардан'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Хориҷ кардан'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
      final success = await notifier.clearAllBookmarks();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ҳамаи хатбаракҳо хориҷ карда шуданд'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}