import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes the local notifications plugin and timezone databases.
  Future<void> init() async {
    // 1. Initialize Timezones
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("NotificationService: Timezone initialized to $timeZoneName");
    } catch (e) {
      debugPrint("NotificationService: Error initializing timezone: $e");
    }

    // 2. Configure initialization settings for Android and iOS
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 3. Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification clicked: ${response.payload}");
      },
    );
  }

  /// Requests notification permissions from the user.
  Future<void> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
        try {
          await androidImplementation?.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint("NotificationService: Error requesting exact alarm permission: $e");
        }
      } else if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      debugPrint("NotificationService: Error requesting permissions: $e");
    }
  }

  /// Dynamic 10:00 AM scheduling based on user task progress.
  /// Tracks indices 0 (Meditation), 1 (Word Memory Game), and 2 (Running Exercise).
  Future<void> scheduleDaily10AMCheck(List<bool> isDoneList) async {
    try {
      // Find names of incomplete tasks
      List<String> undoneTasks = [];
      if (isDoneList.isEmpty || !isDoneList[0]) undoneTasks.add("Meditation");
      if (isDoneList.length <= 1 || !isDoneList[1]) undoneTasks.add("Word Memory Game");
      if (isDoneList.length <= 2 || !isDoneList[2]) undoneTasks.add("Running Exercise");

      const int notificationId = 100;

      if (undoneTasks.isEmpty) {
        // All tasks done! Cancel notification for this checkpoint.
        await _notificationsPlugin.cancel(notificationId);
        debugPrint("NotificationService: All tasks complete. Cancelled 10 AM reminder.");
        
        // As a fallback, schedule tomorrow's fresh reminder since tomorrow they will start fresh
        await _scheduleForFuture(notificationId, ["Meditation", "Word Memory Game", "Running Exercise"], isTomorrowOnly: true);
      } else {
        // Tasks remain uncompleted. Schedule/reschedule notification for next 10 AM checkpoint.
        await _scheduleForFuture(notificationId, undoneTasks, isTomorrowOnly: false);
      }
    } catch (e) {
      debugPrint("NotificationService: Error scheduling check: $e");
    }
  }

  /// Schedules the notification helper method
  Future<void> _scheduleForFuture(int notificationId, List<String> undoneTasks, {required bool isTomorrowOnly}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10, 0);

    // If it's already past 10 AM today or we explicitly want tomorrow's schedule
    if (isTomorrowOnly || now.isAfter(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    String taskNames = undoneTasks.join(", ");
    String bodyMessage = "You haven't done tasks ($taskNames) yet.But don't worry,you have the energy.Let's get started.You have power to win";

    // Determine schedule mode based on Android 14+ permission status
    var androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final bool canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
        if (canScheduleExact) {
          androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        }
      }
    } catch (e) {
      debugPrint("NotificationService: Error checking exact alarm capability: $e");
    }

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      "Daily Task Reminder",
      bodyMessage,
      scheduledDate,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'daily_task_reminder_channel_v3', // Increment to v3 to force sound/vibration recreation
          'Daily Task Reminders',
          channelDescription: 'Reminds you of your uncompleted before 6 PM tasks daily at 10 AM.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint("NotificationService: Scheduled 10 AM reminder for $scheduledDate (mode: $androidScheduleMode) with message: $bodyMessage");
  }
}
