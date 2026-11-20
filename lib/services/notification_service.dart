import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';
import '../utils/reminder_time.dart';

/// Local daily reminders for habits. No network, no server.
///
/// Each habit with a reminder time gets one repeating daily notification,
/// scheduled with the device time zone. Reminders are cancelled when a
/// habit is archived, deleted, or its reminder is switched off.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialises the plugin and the time-zone database. Safe to call twice.
  ///
  /// Never throws: reminders are best-effort, and the app must keep
  /// working even when the notification stack is unavailable.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    try {
      tz_data.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Device time zone unknown: fall back to UTC. Reminders still
      // schedule; they may fire at the wrong wall-clock time.
      tz.setLocalLocation(tz.UTC);
    }
    try {
      const androidSettings = AndroidInitializationSettings('ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings);
    } catch (_) {
      // Plugin unavailable (e.g. in tests): reminders stay off.
    }
    _initialized = true;
  }

  /// Asks the user for the notification permission (Android 13+).
  ///
  /// Returns true when notifications are allowed afterwards.
  /// Returns false (never throws) when the permission flow is unavailable.
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Current notification permission status (false when unavailable).
  Future<bool> get isPermissionGranted async {
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Schedules (or re-schedules) the daily reminder for [habit].
  ///
  /// A habit without a reminder time, or an archived habit, has any
  /// existing reminder cancelled instead.
  Future<void> scheduleHabitReminder(Habit habit) async {
    final id = habit.id;
    if (id == null) {
      return;
    }
    if (habit.reminderMinutes == null || habit.archived) {
      await cancelHabitReminder(id);
      return;
    }
    await init();
    final next = nextReminderDateTime(
      DateTime.now(),
      habit.reminderMinutes!,
    );
    final scheduled = tz.TZDateTime.from(next, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        'Time for ${habit.name}',
        'Keep your streak going — tap to check in.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streakly_reminders',
            'Habit reminders',
            channelDescription: 'Daily reminders to check in on your habits',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Plugin unavailable: reminder silently stays off.
    }
  }

  /// Cancels the reminder for one habit.
  Future<void> cancelHabitReminder(int habitId) async {
    try {
      await _plugin.cancel(habitId);
    } catch (_) {
      // Plugin unavailable: nothing to cancel.
    }
  }

  /// Cancels every scheduled reminder.
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Plugin unavailable: nothing to cancel.
    }
  }
}
