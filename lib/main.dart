import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'data/services/audio_service.dart';
import 'data/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

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
  
  // Initialize audio handler for media notifications
  // This MUST be called before any playback starts
  // The builder creates the handler instance, which is stored in QuranAudioHandler._instance
  // This is the SAME instance that Android will use for notification controls
  await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quran.tj.audio',
      androidNotificationChannelName: 'Quran Playback',
      androidNotificationOngoing: true,
    ),
  );
  
  // Verify the handler instance was created
  final handler = QuranAudioHandler.instance;
  if (handler != null) {
    debugPrint('[Main] AudioService handler instance verified: ${handler.runtimeType}');
    debugPrint('[Main] Handler instance hash: ${identityHashCode(handler)}');
    debugPrint('[Main] This is the instance Android will use for notification controls');
  } else {
    debugPrint('[Main] Warning: Handler instance not available after AudioService.init()');
  }

  // Initialize local notifications and schedule reminders
  await NotificationService().initialize();
  await NotificationService().scheduleWeeklyKahfReminder();
  // Note: Test notification removed - Juma Mubarak notification only shows on Fridays

  // Android 13+ notification permission (one-time)
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  }

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

    // Map settings.theme to ThemeData and ThemeMode
    final selectedTheme = settings.theme;
    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;
    ThemeMode themeMode = ThemeMode.system;

    switch (selectedTheme) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'softBeige':
        lightTheme = AppTheme.softBeigeTheme;
        themeMode = ThemeMode.light;
        break;
      case 'elegantMarble':
        lightTheme = AppTheme.elegantMarbleTheme;
        themeMode = ThemeMode.light;
        break;
      case 'nightSky':
        darkTheme = AppTheme.nightSkyTheme;
        themeMode = ThemeMode.dark;
        break;
      case 'silverLight':
        lightTheme = AppTheme.silverLightTheme;
        themeMode = ThemeMode.light;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: NotificationRouterBridge(child: child!),
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
