import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  // Callback when notification tapped — receives taskId
  Function(String taskId)? onNotificationTapped;
  // Callback when action button tapped — receives (taskId, action)
  Function(String taskId, String action)? onNotificationAction;

  static const String _channelId = 'supernote_reminders';
  static const String _channelName = 'Task Reminders';
  static const String _channelDesc = 'Notifications for task deadlines and pre-reminders';
  static const String _prefsKeyQuietStart = 'notif_quiet_start';
  static const String _prefsKeyQuietEnd = 'notif_quiet_end';
  static const String _prefsKeyDefaultPreReminder = 'notif_default_pre_reminder';

  Future<void> init() async {
    if (_initialized) return;
    if (_isLinux) { _initialized = true; return; }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      await _createNotificationChannel();
      await _requestPermissions();
      _initialized = true;
    } catch (e) {
      // Notifications must not prevent the task screen from opening.
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF2979FF),
    );

    await androidImpl.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Parse payload: "taskId:action" or just "taskId"
    final parts = payload.split(':');
    final taskId = parts[0];
    final action = parts.length > 1 ? parts[1] : 'tap';

    if (action == 'tap') {
      onNotificationTapped?.call(taskId);
    } else {
      onNotificationAction?.call(taskId, action);
    }
  }

  // ===== Schedule =====

  Future<void> scheduleTaskNotification(Task task) async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;
    final deadline = task.deadline;
    if (deadline == null) return;

    final now = DateTime.now();
    if (deadline.isBefore(now)) return;

    // Main notification at deadline
    await _scheduleNotification(
      id: task.id.hashCode,
      title: task.title,
      body: _getNotificationBody(task),
      scheduledDate: tz.TZDateTime.from(deadline, tz.local),
      payload: '${task.id}:tap',
    );

    // Pre-reminder notification
    if (task.preReminderOffset != null && task.preReminderOffset! > 0) {
      final preTime = deadline.subtract(Duration(minutes: task.preReminderOffset!));
      if (preTime.isAfter(now)) {
        await _scheduleNotification(
          id: task.id.hashCode + 10000,
          title: '⏰ Reminder: ${task.title}',
          body: 'Due in ${_formatDuration(task.preReminderOffset!)}',
          scheduledDate: tz.TZDateTime.from(preTime, tz.local),
          payload: '${task.id}:tap',
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    // Check quiet hours
    if (await _isQuietHour(scheduledDate)) {
      // Shift to end of quiet hours
      final shifted = await _shiftFromQuietHours(scheduledDate);
      if (shifted != null) {
        await _doSchedule(id: id, title: title, body: body, scheduledDate: shifted, payload: payload);
      }
      return;
    }

    await _doSchedule(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload);
  }

  Future<void> _doSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction('done', '✅ Done', showsUserInterface: false),
        AndroidNotificationAction('snooze', '💤 Snooze', showsUserInterface: false),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'task_reminder',
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // Exact alarms may be denied on Android. Fall back to an inexact alarm.
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (fallbackError) {
        debugPrint('Notification scheduling failed: $fallbackError');
      }
    }
  }

  // ===== Cancel =====

  Future<void> cancelTaskNotifications(Task task) async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;
    await _notifications.cancel(task.id.hashCode);
    await _notifications.cancel(task.id.hashCode + 10000);
  }

  Future<void> cancelAllNotifications() async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;
    await _notifications.cancelAll();
  }

  Future<void> rescheduleAllTasks(List<Task> tasks) async {
    await cancelAllNotifications();
    for (final task in tasks) {
      if (task.status == TaskStatus.pending) {
        await scheduleTaskNotification(task);
      }
    }
  }

  // ===== Test =====

  Future<void> sendTestNotification() async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      99999,
      '🔔 Test Notification',
      'If you see this, notifications are working!',
      details,
    );
  }

  // ===== Quiet Hours =====

  Future<void> setQuietHours(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyQuietStart, startHour);
    await prefs.setInt(_prefsKeyQuietEnd, endHour);
  }

  Future<(int, int)> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getInt(_prefsKeyQuietStart) ?? 22;
    final end = prefs.getInt(_prefsKeyQuietEnd) ?? 7;
    return (start, end);
  }

  Future<bool> _isQuietHour(DateTime dt) async {
    final (start, end) = await getQuietHours();
    final hour = dt.hour;
    if (start < end) {
      return hour >= start && hour < end;
    } else {
      return hour >= start || hour < end;
    }
  }

  Future<tz.TZDateTime?> _shiftFromQuietHours(tz.TZDateTime dt) async {
    final (start, end) = await getQuietHours();
    final shifted = dt.add(const Duration(hours: 1));
    return shifted;
  }

  // ===== Default Pre-Reminder =====

  Future<void> setDefaultPreReminder(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyDefaultPreReminder, minutes);
  }

  Future<int> getDefaultPreReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyDefaultPreReminder) ?? 0;
  }

  // ===== Helpers =====

  String _getNotificationBody(Task task) {
    final parts = <String>[];
    if (task.dueDate != null) {
      parts.add('📅 ${task.dueDate!.day}/${task.dueDate!.month}');
    }
    if (task.dueTime != null) {
      parts.add('🕐 ${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}');
    }
    if (task.repeatRule != null) {
      parts.add('🔁 ${task.repeatRule}');
    }
    if (parts.isEmpty) return 'Tap to view';
    return parts.join('  ·  ');
  }

  String _formatDuration(int minutes) {
    if (minutes >= 1440) return '${minutes ~/ 1440} day${minutes ~/ 1440 > 1 ? 's' : ''}';
    if (minutes >= 60) return '${minutes ~/ 60} hour${minutes ~/ 60 > 1 ? 's' : ''}';
    return '$minutes min';
  }
}
