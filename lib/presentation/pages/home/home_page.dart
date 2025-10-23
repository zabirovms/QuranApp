import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quran_provider.dart';
import '../../widgets/quran/surah_list_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _SurahsTab(),
    const _TasbeehTab(),
    const _LearnWordsTab(),
    const _DuasTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Қуръон'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              context.push('/bookmarks');
            },
            tooltip: 'Захираҳо',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Сураҳо',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Тасбеҳ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Омӯзиш',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Дуоҳо',
          ),
        ],
      ),
    );
  }
}

class _SurahsTab extends ConsumerWidget {
  const _SurahsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surahs List
          Expanded(
            child: surahsAsync.when(
              data: (surahs) {
                if (surahs.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Қуръон ёфт нашуд',
                    message: 'Дар ҳоли ҳозир ҳеҷ сурае дар барнома нест. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                    icon: Icons.menu_book,
                  );
                }

                return ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return SurahListItem(
                      surah: surah,
                      onTap: () => context.go('/surah/${surah.number}'),
                    );
                  },
                );
              },
              loading: () => const LoadingListWidget(
                itemCount: 10,
                itemHeight: 100,
              ),
              error: (error, stackTrace) => CustomErrorWidget(
                title: 'Хатоги дар боргирӣ',
                message: 'Қуръонро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                onRetry: () {
                  ref.invalidate(surahsProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasbeehTab extends StatelessWidget {
  const _TasbeehTab();

  @override
  Widget build(BuildContext context) {
    // Start immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
      if (loc != '/tasbeeh') {
        context.go('/tasbeeh');
      }
    });
    return const SizedBox.shrink();
  }
}

class _LearnWordsTab extends StatelessWidget {
  const _LearnWordsTab();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
      if (loc != '/learn-words') {
        context.go('/learn-words');
      }
    });
    return const SizedBox.shrink();
  }
}

class _DuasTab extends StatelessWidget {
  const _DuasTab();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
      if (loc != '/duas') {
        context.go('/duas');
      }
    });
    return const SizedBox.shrink();
  }
}
