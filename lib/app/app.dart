import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../presentation/pages/main_menu/main_menu_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/surah/surah_page.dart';
import '../presentation/pages/tasbeeh/tasbeeh_page.dart';
import '../presentation/pages/duas/duas_menu_page.dart';
import '../presentation/pages/duas/rabbano_duas_page.dart';
import '../presentation/pages/duas/prophets_duas_page.dart';
import '../presentation/pages/duas/prophet_dua_detail_page.dart';
import '../presentation/pages/duas/other_duas_page.dart';
import '../data/models/prophet_dua_model.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/bookmarks/bookmarks_page.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/learn_words/learn_words_page.dart';
import '../presentation/pages/prophets/prophets_page.dart';
import '../presentation/pages/prophets/prophet_detail_page.dart';
import '../presentation/pages/asmaul_husna/asmaul_husna_page.dart';
import '../presentation/pages/live_makkah/live_makkah_page.dart';
import '../presentation/providers/user_provider.dart';
import '../data/services/notification_service.dart';
import '../data/models/prophet_model.dart';

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
      
      // Main Menu Page (Home)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainMenuPage(),
      ),
      
      // Quran Page (Surahs List)
      GoRoute(
        path: '/quran',
        name: 'quran',
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
      
      
      // Duas Menu
      GoRoute(
        path: '/duas',
        name: 'duas',
        builder: (context, state) => const DuasMenuPage(),
      ),
      // Rabbano Duas
      GoRoute(
        path: '/duas/rabbano',
        name: 'rabbano-duas',
        builder: (context, state) => const RabbanoDuasPage(),
      ),
      // Prophets Duas
      GoRoute(
        path: '/duas/prophets',
        name: 'prophets-duas',
        builder: (context, state) => const ProphetsDuasPage(),
      ),
      // Prophet Dua Detail
      GoRoute(
        path: '/duas/prophets/detail',
        name: 'prophet-dua-detail',
        builder: (context, state) {
          final prophet = state.extra as ProphetDuaModel;
          return ProphetDuaDetailPage(prophet: prophet);
        },
      ),
      // Other Duas
      GoRoute(
        path: '/duas/other',
        name: 'other-duas',
        builder: (context, state) => const OtherDuasPage(),
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
        builder: (context, state) => Consumer(
          builder: (context, ref, child) {
            final userId = ref.watch(currentUserIdProvider);
            return BookmarksPage(userId: userId);
          },
        ),
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      
      // Learn Words
      GoRoute(
        path: '/learn-words',
        name: 'learn-words',
        builder: (context, state) => const LearnWordsPage(),
      ),
      
      // Prophets
      GoRoute(
        path: '/prophets',
        name: 'prophets',
        builder: (context, state) => const ProphetsPage(),
      ),
      
      // Prophet Detail
      GoRoute(
        path: '/prophets/detail',
        name: 'prophet-detail',
        builder: (context, state) {
          final prophet = state.extra as ProphetModel?;
          if (prophet == null) {
            return const ProphetsPage();
          }
          return ProphetDetailPage(prophet: prophet);
        },
      ),

      // Asmaul Husna
      GoRoute(
        path: '/asmaul-husna',
        name: 'asmaul-husna',
        builder: (context, state) => const AsmaulHusnaPage(),
      ),

      // Live Makkah
      GoRoute(
        path: '/live-makkah',
        name: 'live-makkah',
        builder: (context, state) => const LiveMakkahPage(),
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

class NotificationRouterBridge extends StatefulWidget {
  final Widget child;
  const NotificationRouterBridge({super.key, required this.child});

  @override
  State<NotificationRouterBridge> createState() => _NotificationRouterBridgeState();
}

class _NotificationRouterBridgeState extends State<NotificationRouterBridge> {
  StreamSubscription<String?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = NotificationService().onPayload.listen((payload) {
      if (payload != null && payload.isNotEmpty && mounted) {
        final router = GoRouter.of(context);
        router.go(payload);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
