import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../providers/quran_provider.dart';
import '../../../domain/repositories/quran_repository.dart';

// Providers
final bookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  return await repository.getBookmarksByUser('default_user');
});

final bookmarkNotifierProvider = StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) => BookmarkNotifier(ref.watch(quranRepositoryProvider)));

// Bookmark state
class BookmarkState {
  final List<BookmarkModel> bookmarks;
  final bool isLoading;
  final String? error;

  BookmarkState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
  });

  BookmarkState copyWith({
    List<BookmarkModel>? bookmarks,
    bool? isLoading,
    String? error,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Bookmark notifier
class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final QuranRepository _repository;

  BookmarkNotifier(this._repository) : super(BookmarkState());

  Future<void> loadBookmarks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final bookmarks = await _repository.getBookmarksByUser('default_user');
      state = state.copyWith(
        bookmarks: bookmarks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Хатоги дар боргирии захираҳо: $e',
      );
    }
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    try {
      await _repository.addBookmark(bookmark);
      await loadBookmarks();
    } catch (e) {
      state = state.copyWith(error: 'Хатоги дар илова кардани захира: $e');
    }
  }

  Future<void> removeBookmark(int id) async {
    try {
      await _repository.removeBookmark(id);
      await loadBookmarks();
    } catch (e) {
      state = state.copyWith(error: 'Хатоги дар ҳазф кардани захира: $e');
    }
  }

  Future<void> clearAllBookmarks() async {
    try {
      // Get all bookmarks and remove them one by one
      final bookmarks = await _repository.getBookmarksByUser('default_user');
      for (final bookmark in bookmarks) {
        await _repository.removeBookmark(bookmark.id);
      }
      await loadBookmarks();
    } catch (e) {
      state = state.copyWith(error: 'Хатоги дар тоза кардани ҳамаи захираҳо: $e');
    }
  }
}

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkNotifierProvider.notifier).loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          if (bookmarkState.bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearAllDialog(context),
            ),
        ],
      ),
      body: bookmarkState.isLoading
          ? const Center(child: LoadingWidget())
          : bookmarkState.error != null
              ? Center(
                  child: CustomErrorWidget(
                    message: bookmarkState.error!,
                    onRetry: () => ref.read(bookmarkNotifierProvider.notifier).loadBookmarks(),
                  ),
                )
              : bookmarkState.bookmarks.isEmpty
                  ? _buildEmptyState()
                  : _buildBookmarksList(bookmarkState.bookmarks),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildBookmarksList(List<BookmarkModel> bookmarks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return BookmarkCard(
          bookmark: bookmark,
          onTap: () => _navigateToVerse(bookmark),
          onDelete: () => _deleteBookmark(bookmark),
        );
      },
    );
  }

  void _navigateToVerse(BookmarkModel bookmark) {
    context.go('/surah/${bookmark.surahNumber}/verse/${bookmark.verseNumber}');
  }

  void _deleteBookmark(BookmarkModel bookmark) {
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
            onPressed: () {
              ref.read(bookmarkNotifierProvider.notifier).removeBookmark(bookmark.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Захира ҳазф карда шуд')),
              );
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

  void _showClearAllDialog(BuildContext context) {
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
            onPressed: () {
              ref.read(bookmarkNotifierProvider.notifier).clearAllBookmarks();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ҳамаи захираҳо тоза карда шуданд')),
              );
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