import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../providers/quran_provider.dart';


class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Захираҳо'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            } catch (e) {
              GoRouter.of(context).go('/');
            }
          },
        ),
        actions: [
          if (bookmarkState.hasValue && bookmarkState.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearAllDialog(context, ref),
            ),
        ],
      ),
      body: bookmarkState.when(
        data: (bookmarks) => bookmarks.isEmpty
            ? _buildEmptyState(context)
            : _buildBookmarksList(bookmarks, context, ref),
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stackTrace) => Center(
          child: CustomErrorWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(bookmarkNotifierProvider),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ захирае нест',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оятеро захира кунед то дар ин ҷо нишон дода шавад',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.menu_book),
            label: const Text('Қуръонро хонед'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(List<BookmarkModel> bookmarks, BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return BookmarkCard(
          bookmark: bookmark,
          onTap: () => _navigateToVerse(bookmark, context),
          onDelete: () => _deleteBookmark(bookmark, context, ref),
        );
      },
    );
  }

  void _navigateToVerse(BookmarkModel bookmark, BuildContext context) {
    context.go('/surah/${bookmark.surahNumber}/verse/${bookmark.verseNumber}');
  }

  void _deleteBookmark(BookmarkModel bookmark, BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ҳазф кардани захира'),
        content: const Text('Оё шумо мехоҳед ин захираро ҳазф кунед?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(bookmarkNotifierProvider.notifier).removeBookmark(bookmark.id);
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Захира ҳазф карда шуд')),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Хатоги дар ҳазф кардан: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Ҳазф кардан'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тоза кардани ҳамаи захираҳо'),
        content: const Text('Оё шумо мехоҳед ҳамаи захираҳоро тоза кунед? Ин амал баргаштан намешавад.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final bookmarks = ref.read(bookmarkNotifierProvider).value ?? [];
                for (final bookmark in bookmarks) {
                  await ref.read(bookmarkNotifierProvider.notifier).removeBookmark(bookmark.id);
                }
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ҳамаи захираҳо тоза карда шуданд')),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Хатоги дар тоза кардан: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Тоза кардан'),
          ),
        ],
      ),
    );
  }
}

class BookmarkCard extends StatelessWidget {
  final BookmarkModel bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with surah/verse info and delete button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Сураи ${bookmark.surahNumber}, Ояти ${bookmark.verseNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Arabic text
              if (bookmark.arabicText.isNotEmpty)
                Text(
                  bookmark.arabicText,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              
              if (bookmark.arabicText.isNotEmpty) const SizedBox(height: 8),
              
              // Translation
              if (bookmark.tajikText.isNotEmpty)
                Text(
                  bookmark.tajikText,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 8),
              
              // Date added
              Text(
                'Илова шуда: ${_formatDate(bookmark.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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
}