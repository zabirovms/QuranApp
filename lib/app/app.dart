import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/surah/surah_page.dart';
// import '../presentation/pages/surah/verse_page.dart'; // Not needed
import '../presentation/pages/tasbeeh/tasbeeh_page.dart';
import '../presentation/pages/learn_words/learn_words_page.dart';
import '../presentation/pages/duas/duas_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/bookmarks/bookmarks_page.dart';
import '../presentation/pages/splash/splash_page.dart';

// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Home Page
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      
      // Surah Page
      GoRoute(
        path: '/surah/:surahNumber',
        name: 'surah',
        builder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          return SurahPage(surahNumber: surahNumber);
        },
      ),
      
      // Verse Page (with specific verse)
      GoRoute(
        path: '/surah/:surahNumber/verse/:verseNumber',
        name: 'verse',
        builder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          final verseNumber = int.parse(state.pathParameters['verseNumber']!);
          return SurahPage(
            surahNumber: surahNumber,
            initialVerseNumber: verseNumber,
          );
        },
      ),
      
      // Tasbeeh Counter
      GoRoute(
        path: '/tasbeeh',
        name: 'tasbeeh',
        builder: (context, state) => const TasbeehPage(),
      ),
      
      // Learn Words
      GoRoute(
        path: '/learn-words',
        name: 'learn-words',
        builder: (context, state) => const LearnWordsPage(),
      ),
      
      // Duas
      GoRoute(
        path: '/duas',
        name: 'duas',
        builder: (context, state) => const DuasPage(),
      ),
      
      // Search
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['query'];
          return SearchPage(initialQuery: query);
        },
      ),
      
      // Bookmarks
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksPage(),
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
