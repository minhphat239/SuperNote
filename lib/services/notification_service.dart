import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../models/task.dart';

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  final taskId = response.payload;
  if (taskId == null || taskId.isEmpty) return;
  developer.log('Background notification response: $taskId, action: ${response.actionId}',
      name: 'NotificationService');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool get isReady => _initialized;
  bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  bool _permissionsGranted = false;
  bool get permissionsGranted => _permissionsGranted;

  Function(String taskId)? onNotificationTapped;
  Function(String taskId, String action)? onNotificationAction;

  static const String _channelId = 'supernote_reminders';
  static const String _channelName = 'Task Reminders';
  static const String _channelDesc = 'Notifications for task deadlines and pre-reminders';
  static const String _prefsKeyQuietStart = 'notif_quiet_start';
  static const String _prefsKeyQuietEnd = 'notif_quiet_end';
  static const String _prefsKeyDefaultPreReminder = 'notif_default_pre_reminder';
  static const String _prefsKeyLastMissedTime = 'notif_last_missed_time';
  static const String _prefsKeyMissedCountToday = 'notif_missed_count_today';
  static const String _prefsKeyMissedDate = 'notif_missed_date';

  final Map<int, Timer> _timers = {};
  final Map<int, DateTime> _scheduledTimes = {};

  // ===== Smart Notification Constants =====
  static const int _missedIntervalHours = 3;
  static const int _missedMaxPerDay = 4;

  Future<void> init() async {
    if (_initialized) return;
    if (_isLinux) { _initialized = true; return; }

    developer.log('init() starting...', name: 'NotificationService');

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
        onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
      );

      await _createNotificationChannel();

      await _requestPermissions();

      _initialized = true;
      developer.log('init() completed successfully', name: 'NotificationService');
    } catch (e) {
      developer.log('init() FAILED: $e', name: 'NotificationService');
      _initialized = false;
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
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission() ?? false;
        _permissionsGranted = granted;
        if (!granted) {
          developer.log('Notification permission DENIED by user', name: 'NotificationService');
        }
      }

      final iosImpl = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
        _permissionsGranted = true;
      }
    } catch (e) {
      developer.log('Permission request failed: $e', name: 'NotificationService');
      _permissionsGranted = false;
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    if (_isLinux) return true;
    if (!_initialized) await init();

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final currentStatus = await androidImpl.areNotificationsEnabled() ?? false;
        if (currentStatus) {
          _permissionsGranted = true;
          return true;
        }
        final granted = await androidImpl.requestNotificationsPermission() ?? false;
        _permissionsGranted = granted;
        return granted;
      }
      _permissionsGranted = true;
      return true;
    } catch (e) {
      developer.log('Permission check failed: $e', name: 'NotificationService');
      _permissionsGranted = false;
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    final uri = Uri.parse('package:com.example.super_note');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final fallback = Uri.parse('package:com.example.super_note/app-settings');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (_isLinux) return true;
    if (!_initialized) await init();

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (e) {
      developer.log('Check notifications enabled failed: $e', name: 'NotificationService');
      return false;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId == null || taskId.isEmpty) return;

    final action = response.actionId ?? 'tap';
    if (action == 'tap') {
      onNotificationTapped?.call(taskId);
    } else {
      onNotificationAction?.call(taskId, action);
    }
  }

  // ===== Core: Post notification via show() (same as test notification) =====

  Future<void> _postNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool withActions = true,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      actions: withActions ? const [
        AndroidNotificationAction('done', '✅ Done', showsUserInterface: true),
        AndroidNotificationAction('snooze', '💤 Snooze', showsUserInterface: true),
      ] : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'task_reminder',
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(id, title, body, details, payload: payload);
      developer.log('_postNotification SUCCESS id=$id "$title"', name: 'NotificationService');
    } catch (e) {
      developer.log('_postNotification FAILED id=$id: $e', name: 'NotificationService');
    }
  }

  // ===== Timer-based scheduling for individual task notifications =====

  void _scheduleTimer({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String payload,
  }) {
    _cancelTimer(id);

    final now = DateTime.now();
    final delay = fireAt.difference(now);

    if (delay.isNegative) {
      developer.log('Timer already passed for id=$id, skipping', name: 'NotificationService');
      return;
    }

    developer.log('Setting timer id=$id to fire in ${delay.inSeconds}s at $fireAt', name: 'NotificationService');
    _scheduledTimes[id] = fireAt;

    _timers[id] = Timer(delay, () async {
      _timers.remove(id);
      _scheduledTimes.remove(id);
      await _postNotification(id: id, title: title, body: body, payload: payload);
    });
  }

  void _cancelTimer(int id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _scheduledTimes.remove(id);
  }

  // ===== Public API: Schedule task notifications =====

  Future<void> scheduleTaskNotification(Task task) async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    final deadline = task.deadline;
    if (deadline == null) return;

    final now = DateTime.now();
    if (deadline.isBefore(now) || deadline.isAtSameMomentAs(now)) {
      developer.log('Task "${task.title}" deadline in past, skipping', name: 'NotificationService');
      return;
    }

    final deltaT = deadline.difference(now).inMinutes;

    developer.log('scheduleTaskNotification: "${task.title}" deadline=$deadline', name: 'NotificationService');

    // Main notification at deadline
    _scheduleTimer(
      id: task.id.hashCode,
      title: '⏰ SuperNote',
      body: _getDeadlineBody(task),
      fireAt: deadline,
      payload: task.id,
    );

    // Pre-reminder
    if (deltaT > 30 && task.preReminderOffset != null && task.preReminderOffset! > 0) {
      final preTime = deadline.subtract(Duration(minutes: task.preReminderOffset!));
      if (preTime.isAfter(now)) {
        _scheduleTimer(
          id: task.id.hashCode + 10000,
          title: '📋 SuperNote',
          body: _getPreReminderBody(task),
          fireAt: preTime,
          payload: task.id,
        );
      }
    }
  }

  Future<void> cancelTaskNotifications(Task task) async {
    if (_isLinux) return;
    _cancelTimer(task.id.hashCode);
    _cancelTimer(task.id.hashCode + 10000);
  }

  Future<void> cancelAllNotifications() async {
    if (_isLinux) return;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _scheduledTimes.clear();
  }

  Future<void> rescheduleAllTasks(List<Task> tasks) async {
    developer.log('rescheduleAllTasks called with ${tasks.length} tasks', name: 'NotificationService');
    await cancelAllNotifications();
    int scheduled = 0;
    for (final task in tasks) {
      if (task.status == TaskStatus.pending || task.status == TaskStatus.snoozed) {
        await scheduleTaskNotification(task);
        scheduled++;
      }
    }
    developer.log('rescheduleAllTasks done, scheduled $scheduled notifications', name: 'NotificationService');
  }

  // ===== Smart Missed Tasks Notification (Grouped, Frequency-Limited) =====

  /// Check if we should fire a missed notification based on frequency rules:
  /// - Max 4 times per day
  /// - At least 3 hours between each
  Future<bool> _canFireMissedNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    // Check if it's a new day → reset counter
    final lastDate = prefs.getString(_prefsKeyMissedDate) ?? '';
    if (lastDate != today) {
      await prefs.setInt(_prefsKeyMissedCountToday, 0);
      await prefs.setString(_prefsKeyMissedDate, today);
    }

    // Check max per day
    final countToday = prefs.getInt(_prefsKeyMissedCountToday) ?? 0;
    if (countToday >= _missedMaxPerDay) {
      developer.log('Missed notification limit reached: $countToday/$_missedMaxPerDay today', name: 'NotificationService');
      return false;
    }

    // Check interval
    final lastTime = prefs.getInt(_prefsKeyLastMissedTime) ?? 0;
    final lastDateTime = DateTime.fromMillisecondsSinceEpoch(lastTime);
    final hoursSince = now.difference(lastDateTime).inHours;
    if (hoursSince < _missedIntervalHours) {
      developer.log('Missed notification interval not met: ${hoursSince}h < ${_missedIntervalHours}h', name: 'NotificationService');
      return false;
    }

    return true;
  }

  Future<void> _recordMissedNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_prefsKeyLastMissedTime, now.millisecondsSinceEpoch);
    final count = (prefs.getInt(_prefsKeyMissedCountToday) ?? 0) + 1;
    await prefs.setInt(_prefsKeyMissedCountToday, count);
    developer.log('Recorded missed notification #$count today', name: 'NotificationService');
  }

  /// Fire grouped missed notification — ONE notification for ALL overdue tasks
  Future<void> fireMissedNotifications(List<Task> tasks) async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    final now = DateTime.now();

    // Collect overdue tasks
    final overdue = <Task>[];
    for (final task in tasks) {
      if (task.status != TaskStatus.pending && task.status != TaskStatus.snoozed) continue;
      final deadline = task.deadline;
      if (deadline == null) continue;
      if (deadline.isBefore(now)) {
        overdue.add(task);
      }
    }

    if (overdue.isEmpty) return;

    // Check frequency rules
    if (!await _canFireMissedNotification()) return;

    // Build grouped notification
    final count = overdue.length;
    final body = _getMissedGroupBody(overdue);

    await _postNotification(
      id: 88888, // Fixed ID for grouped missed notification
      title: '📌 SuperNote',
      body: body,
      payload: 'missed_group',
      withActions: false,
    );

    await _recordMissedNotification();
    developer.log('Missed notification fired: $count tasks grouped', name: 'NotificationService');
  }

  // ===== Test =====

  Future<bool> sendTestNotification() async {
    if (_isLinux) return false;
    if (!_initialized) await init();
    if (!_initialized) return false;

    try {
      final granted = await checkAndRequestPermissions();
      if (!granted) return false;
    } catch (e) {
      return false;
    }

    await _postNotification(
      id: 99999,
      title: '🔔 SuperNote',
      body: 'Thông báo đã hoạt động! Bạn sẽ nhận được nhắc nhở đúng giờ.',
      payload: 'test',
    );

    // Also schedule a test 60s from now
    _scheduleTimer(
      id: 99998,
      title: '📋 SuperNote',
      body: 'Đây là thông báo tự động sau 60 giây!',
      fireAt: DateTime.now().add(const Duration(seconds: 60)),
      payload: 'test_scheduled',
    );

    return true;
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

  // ===== Default Pre-Reminder =====

  Future<void> setDefaultPreReminder(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyDefaultPreReminder, minutes);
  }

  Future<int> getDefaultPreReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyDefaultPreReminder) ?? 0;
  }

  // ===== Random Vietnamese Messages =====

  static final _random = Random();

  static final _deadlineMessages = [
    'Đến giờ rồi! {title} - làm ngay kẻo quên!',
    'Heey, {title} đến hạn rồi đó, nhanh tay lên!',
    '{title} hết giờ rồi, xử lý liền đi!',
    'Tin nhắn từ SuperNote: {title} cần bạn hoàn thành!',
    'Nhắc nhở: {title} - đừng để trễ nữa!',
    '{title} chờ đợi bạn, hoàn thành nó đi!',
    'Đã đến giờ ({title}), đừng chần chừ nữa!',
    'SuperNote nhắc: {title} - action time!',
  ];

  static final _preReminderMessages = [
    'Còn {duration} nữa là {title} đến hạn, chuẩn bị đi!',
    '{title} sắp hết giờ rồi ({duration} nữa), sẵn sàng chưa?',
    'Sắp tới hạn: {title} - còn {duration}, kick start đi!',
    'Nhắc nhở: {title} sẽ đến hạn trong {duration}, nào!',
    '{duration} nữa thôi, {title} cần bạn xử lý!',
    'SuperNote: Còn {duration} nữa đến {title}, chuẩn bị tinh thần!',
    'Alert: {title} sẽ đến hạn sau {duration}, đi nào!',
    '{title} - {duration} nữa là deadline, bạn ơi!',
  ];

  static final _missedMessages = [
    'Bạn có {count} việc chưa làm!',
    'Nè, còn {count} việc chờ bạn xử lý!',
    '{count} việc đang chờ, lẹ tay lên!',
    'SuperNote nhắc: còn {count} việc chưa xong!',
    'Bạn ơi, {count} việc bị bỏ lỡ nè!',
    '{count} việc chưa hoàn thành, cố gắng lên!',
    'Còn {count} việc đang chờ bạn, đừng quên!',
    'Nhắc nhẹ: {count} việc còn dang dở!',
  ];

  static final _missedDetails = [
    '• {title}',
    '→ {title}',
    '▸ {title}',
    '● {title}',
  ];

  String _getDeadlineBody(Task task) {
    final msg = _deadlineMessages[_random.nextInt(_deadlineMessages.length)];
    return msg.replaceAll('{title}', task.title);
  }

  String _getPreReminderBody(Task task) {
    final msg = _preReminderMessages[_random.nextInt(_preReminderMessages.length)];
    return msg
        .replaceAll('{title}', task.title)
        .replaceAll('{duration}', _formatDuration(task.preReminderOffset!));
  }

  /// Build grouped body for multiple overdue tasks
  /// Shows: "Bạn có 5 việc chưa làm!\n• Task 1\n• Task 2\n• Task 3\nvà 2 việc nữa..."
  String _getMissedGroupBody(List<Task> overdue) {
    final count = overdue.length;
    final msg = _missedMessages[_random.nextInt(_missedMessages.length)];
    final header = msg.replaceAll('{count}', '$count');

    if (count <= 3) {
      // Show all tasks
      final details = overdue.map((t) {
        final d = _missedDetails[_random.nextInt(_missedDetails.length)];
        return d.replaceAll('{title}', t.title);
      }).join('\n');
      return '$header\n$details';
    } else {
      // Show first 3 + "và N việc nữa..."
      final shown = overdue.take(3).map((t) {
        final d = _missedDetails[_random.nextInt(_missedDetails.length)];
        return d.replaceAll('{title}', t.title);
      }).join('\n');
      return '$header\n$shown\nvà ${count - 3} việc nữa...';
    }
  }

  String _formatDuration(int minutes) {
    if (minutes >= 1440) return '${minutes ~/ 1440} ngày';
    if (minutes >= 60) return '${minutes ~/ 60} tiếng';
    return '$minutes phút';
  }
}
