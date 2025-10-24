import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/performance_optimizer.dart';
import 'core/utils/hive_utils.dart';
import 'presentation/pages/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await HiveUtils.init();
  
  // Initialize performance optimizations
  await PerformanceOptimizer().initialize();
  
  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: _BackHandler(child: TajikQuranApp()),
    ),
  );
}

class TajikQuranApp extends ConsumerWidget {
  const TajikQuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final mode = () {
      switch (settings.theme) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    }();
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

class _BackHandler extends StatelessWidget {
final Widget child;
  const _BackHandler({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        
        // Get current location
        final currentLocation = GoRouterState.of(context).uri.path;
        
        // Debug logging
        print('Back button pressed. Current location: $currentLocation');
        print('Can pop: ${router.canPop()}');
        
        // Define tab routes that should always go to home first
        final tabRoutes = ['/tasbeeh', '/duas', '/search', '/bookmarks', '/settings'];
        
        if (tabRoutes.contains(currentLocation)) {
          // User is on a tab route - always navigate to home first
          print('On tab route - navigating to home (default tab)...');
          router.go('/');
        } else if (router.canPop()) {
          // Check if we can pop (go back in navigation history)
          print('Popping route...');
          router.pop();
        } else if (currentLocation == '/') {
          // User is on home page (default tab) with no navigation history
          // Allow app exit
          print('Allowing app exit...');
          // Let the system handle app exit
        } else {
          // If we can't pop and we're not on a recognized route, go to home
          print('Navigating to home...');
          router.go('/');
        }
      },
      child: child,
    );
  }
}
