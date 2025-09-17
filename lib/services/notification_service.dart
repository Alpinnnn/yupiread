import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import 'data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _streakReminderId = 1;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    // Request notification permission for Android 13+
    final permission = await Permission.notification.request();
    
    if (permission.isGranted) {
      return true;
    } else if (permission.isDenied) {
      // Show permission dialog
      return false;
    } else if (permission.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    if (response.id == _streakReminderId) {
      // Navigate to reading screen or show streak info
      // This would be handled by the main app
    }
  }

  Future<void> scheduleStreakReminder({
    required String time,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    // Cancel existing reminder
    await cancelStreakReminder();

    // Parse time (format: "HH:MM")
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Schedule daily notification
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'streak_reminder',
      'Reading Streak Reminder',
      channelDescription: 'Daily reminder to maintain your reading streak',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2563EB),
      enableLights: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      _streakReminderId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  Future<void> cancelStreakReminder() async {
    await _notifications.cancel(_streakReminderId);
  }

  Future<void> updateStreakReminder() async {
    final dataService = DataService.instance;
    
    if (dataService.streakReminderEnabled) {
      await scheduleStreakReminder(
        time: dataService.streakReminderTime,
        title: 'Reading Streak Reminder', // This should be localized
        body: 'Don\'t forget to read today to maintain your streak!', // This should be localized
      );
    } else {
      await cancelStreakReminder();
    }
  }

  Future<void> showStreakEndedNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_ended',
      'Streak Ended',
      channelDescription: 'Notification when reading streak ends',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFEF4444),
      enableLights: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2, // Different ID for streak ended notifications
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> showStreakMilestoneNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_milestone',
      'Streak Milestone',
      channelDescription: 'Notification for streak milestones',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF10B981),
      enableLights: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      3, // Different ID for milestone notifications
      title,
      body,
      notificationDetails,
    );
  }

  Future<bool> areNotificationsEnabled() async {
    final permission = await Permission.notification.status;
    return permission.isGranted;
  }
}
