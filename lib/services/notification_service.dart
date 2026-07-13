import 'dart:io';
import 'package:flutter/material.dart';
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
      List<String> undoneTasks = _getUndoneTasks(isDoneList);
      const int notificationId = 100;

      if (undoneTasks.isEmpty) {
        await _notificationsPlugin.cancel(notificationId);
        debugPrint("NotificationService: All tasks complete. Cancelled 10 AM reminder.");
        // Schedule tomorrow's fresh 10 AM reminder
        await _scheduleForFuture(
          notificationId: notificationId,
          undoneTasks: ["Meditation", "Word Memory Game", "Running Exercise"],
          hour: 10,
          title: "Daily Task Reminder",
          buildBody: (names) => "You haven't done tasks ($names) yet.But don't worry,you have the energy.Let's get started.You have power to win",
          isTomorrowOnly: true,
        );
      } else {
        await _scheduleForFuture(
          notificationId: notificationId,
          undoneTasks: undoneTasks,
          hour: 10,
          title: "Daily Task Reminder",
          buildBody: (names) => "You haven't done tasks ($names) yet.But don't worry,you have the energy.Let's get started.You have power to win",
          isTomorrowOnly: false,
        );
      }
    } catch (e) {
      debugPrint("NotificationService: Error scheduling 10 AM check: $e");
    }
  }

  /// Dynamic 4:00 PM scheduling based on user task progress.
  /// If any of the 3 morning tasks are still undone, sends an urgency reminder.
  Future<void> scheduleDaily4PMCheck(List<bool> isDoneList) async {
    try {
      List<String> undoneTasks = _getUndoneTasks(isDoneList);
      const int notificationId = 101;

      if (undoneTasks.isEmpty) {
        // All tasks done — no 4 PM reminder needed, cancel any existing one
        await _notificationsPlugin.cancel(notificationId);
        debugPrint("NotificationService: All tasks complete. Cancelled 4 PM reminder.");
      } else {
        await _scheduleForFuture(
          notificationId: notificationId,
          undoneTasks: undoneTasks,
          hour: 16,
          title: "⏰ 2 Hours More!",
          buildBody: (names) => "2 hours more. Complete $names and show your strength!",
          isTomorrowOnly: false,
        );
      }
    } catch (e) {
      debugPrint("NotificationService: Error scheduling 4 PM check: $e");
    }
  }

  /// Returns the list of uncompleted task names from the isDoneList.
  List<String> _getUndoneTasks(List<bool> isDoneList) {
    final List<String> undoneTasks = [];
    if (isDoneList.isEmpty || !isDoneList[0]) undoneTasks.add("Meditation");
    if (isDoneList.length <= 1 || !isDoneList[1]) undoneTasks.add("Word Memory Game");
    if (isDoneList.length <= 2 || !isDoneList[2]) undoneTasks.add("Running Exercise");
    return undoneTasks;
  }

  /// Schedules a notification at a given [hour] of the day.
  /// Accepts [buildBody] to generate the body string from task names.
  Future<void> _scheduleForFuture({
    required int notificationId,
    required List<String> undoneTasks,
    required int hour,
    required String title,
    required String Function(String taskNames) buildBody,
    required bool isTomorrowOnly,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

    // If it's already past the target hour today or we explicitly want tomorrow's schedule
    if (isTomorrowOnly || now.isAfter(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final String taskNames = undoneTasks.join(", ");
    final String bodyMessage = buildBody(taskNames);

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
      title,
      bodyMessage,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_task_reminder_channel_v3',
          'Daily Task Reminders',
          channelDescription: 'Reminds you of your uncompleted before 6 PM tasks.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: const Color(0xFF000000), // Black background for icon circle
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

    debugPrint("NotificationService: Scheduled ${hour}:00 reminder for $scheduledDate (mode: $androidScheduleMode) with message: $bodyMessage");
  }
}
