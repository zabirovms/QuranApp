import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<String?> _payloadController = StreamController<String?>.broadcast();
  Stream<String?> get onPayload => _payloadController.stream;

  static const String _weeklyChannelId = 'weekly_kahf_channel';
  static const String _weeklyChannelName = 'Weekly Surah Al-Kahf';
  static const String _weeklyChannelDesc = 'Friday reminder to read Surah Al-Kahf';
  static const int _weeklyNotificationId = 1001;
  static const String _testOnceKey = 'notification_test_once';

  Future<void> initialize() async {
    // Timezone init
    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      // flutter_timezone >=5 returns TimezoneInfo; older may return String
      String localTzName;
      if (tzInfo is String) {
        localTzName = tzInfo;
      } else {
        localTzName = (tzInfo as dynamic).name as String;
      }
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (_) {
      // Fallback to device offset may remain UTC; scheduling uses tz.local regardless
    }

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _payloadController.add(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create channel on Android
    const AndroidNotificationChannel weeklyChannel = AndroidNotificationChannel(
      _weeklyChannelId,
      _weeklyChannelName,
      description: _weeklyChannelDesc,
      importance: Importance.defaultImportance,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(weeklyChannel);
      // Android 13+ permission
      await androidImpl.requestNotificationsPermission();
    }

    // Fallback permission request
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> scheduleWeeklyKahfReminder() async {
    // 7 AM device local time every Friday
    final tz.Location loc = tz.local;
    final tz.TZDateTime next = _nextInstanceOfFridayAt(loc, hour: 7, minute: 0);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _weeklyChannelId,
        _weeklyChannelName,
        channelDescription: _weeklyChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );

    try {
      await _plugin.zonedSchedule(
        _weeklyNotificationId,
        'Ҷумъа Муборак',
        'Хондани Сураи Ал-Каҳфро аз ёд набароред💚',
        next,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '/surah/18',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to schedule weekly reminder: $e');
      }
      // Do not rethrow; app should continue to run.
    }
  }

  Future<void> scheduleImmediateTestNotificationOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(_testOnceKey) ?? false;
    if (already) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _weeklyChannelId,
        _weeklyChannelName,
        channelDescription: _weeklyChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      _weeklyNotificationId + 1,
      'Ҷумъа Муборак',
      'Хондани Сураи Ал-Каҳфро аз ёд набароред💚',
      details,
      payload: '/surah/18',
    );

    await prefs.setBool(_testOnceKey, true);
  }

  tz.TZDateTime _nextInstanceOfFridayAt(tz.Location location, {required int hour, required int minute}) {
    tz.TZDateTime scheduled = tz.TZDateTime.now(location);
    scheduled = tz.TZDateTime(location, scheduled.year, scheduled.month, scheduled.day, hour, minute);
    // Friday = 5 (Mon=1 ... Sun=7)
    while (scheduled.weekday != DateTime.friday || scheduled.isBefore(tz.TZDateTime.now(location))) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(location, scheduled.year, scheduled.month, scheduled.day, hour, minute);
    }
    return scheduled;
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background isolate: forward payload via platform channel not needed here; app will handle on resume.
  if (kDebugMode) {
    debugPrint('Notification tapped in background: ${response.payload}');
  }
}


