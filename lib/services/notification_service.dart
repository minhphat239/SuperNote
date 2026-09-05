import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
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

  static const int _overdueNotificationId = 888888;
  static const int _morningSummaryId = 777777;
  static const int _eveningSummaryId = 666666;

  List<Task> Function()? _getAllTasksCallback;

  // ===== INIT =====

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
      await _scheduleDailySummaries();

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
      developer.log('Permission request failed', error: e, name: 'NotificationService');
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
      developer.log('Permission check failed', error: e, name: 'NotificationService');
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
      developer.log('Check notifications enabled failed', error: e, name: 'NotificationService');
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

  // ===== CORE: Notification Details =====

  NotificationDetails _taskNotificationDetails({bool withActions = true}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
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
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'task_reminder',
      ),
    );
  }

  // ===== NOTIFICATION ID CONVENTION =====
  //
  // Main (deadline):     task.id.hashCode
  // Pre-reminder:        task.id.hashCode + 1
  // Overdue summary:     888888 (fixed)
  // Morning summary:     777777 (fixed)
  // Evening summary:     666666 (fixed)

  // ===== TASK NOTIFICATION SCHEDULING =====

  /// Schedule both pre-reminder and main notification for a task.
  /// - Main: always at deadline (if in future)
  /// - Pre: only if preTime > now + 1 minute AND preTime < deadline
  /// - Quiet hours: shift both, but drop pre if too close to main (<15 min gap)
  Future<void> scheduleTaskNotification(Task task) async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    final deadline = task.deadline;
    if (deadline == null) return;

    final now = DateTime.now();
    final mainId = task.id.hashCode;
    final preId = task.id.hashCode + 1;

    // 1. Cancel old notifications for this task first
    await cancelTaskReminder(task.id);

    // 2. Skip if deadline already passed → Overdue Summary handles it
    if (deadline.isBefore(now)) {
      developer.log('Deadline passed for "${task.title}", skipping main/pre', name: 'NotificationService');
      return;
    }

    // 3. Schedule MAIN notification at deadline
    final tzMain = tz.TZDateTime.from(deadline, tz.local);
    await _doSchedule(
      id: mainId,
      title: '⏰ SuperNote',
      body: _getDeadlineBody(task),
      scheduledDate: tzMain,
      payload: task.id,
    );

    // 4. Schedule PRE-reminder (smart logic)
    final preOffset = task.preReminderOffset;
    if (preOffset != null && preOffset > 0) {
      final preTime = deadline.subtract(Duration(minutes: preOffset));

      // Only schedule if preTime is in the future (at least 1 minute from now)
      if (preTime.isAfter(now.add(const Duration(minutes: 1))) && preTime.isBefore(deadline)) {
        final tzPre = tz.TZDateTime.from(preTime, tz.local);

        // Quiet hours: shift if needed
        var adjustedPre = await _adjustForQuietHours(tzPre);
        final adjustedMain = await _adjustForQuietHours(tzMain);

        // Quiet Hours Adjustment: if adjusted time > deadline, cancel notification
        if (adjustedPre != null && adjustedPre.isAfter(tz.TZDateTime.from(deadline, tz.local))) {
          developer.log('Pre adjusted time $adjustedPre exceeds deadline, cancelling pre for "${task.title}"', name: 'NotificationService');
          adjustedPre = null;
        }
        if (adjustedMain != null && adjustedMain.isAfter(tz.TZDateTime.from(deadline, tz.local))) {
          developer.log('Main adjusted time $adjustedMain exceeds deadline, cancelling main for "${task.title}"', name: 'NotificationService');
          await _notifications.cancel(mainId);
          return;
        }

        // Dedup: if pre and main are too close (< 15 min gap), drop pre
        if (adjustedPre != null && adjustedMain != null) {
          final gap = adjustedMain.difference(adjustedPre).inMinutes;
          if (gap < 15) {
            developer.log('Pre too close to main (${gap}m), dropping pre for "${task.title}"', name: 'NotificationService');
          } else {
            await _doSchedule(
              id: preId,
              title: '📋 SuperNote',
              body: _getPreReminderBody(task),
              scheduledDate: adjustedPre,
              payload: task.id,
            );
          }
        } else if (adjustedPre != null) {
          await _doSchedule(
            id: preId,
            title: '📋 SuperNote',
            body: _getPreReminderBody(task),
            scheduledDate: adjustedPre,
            payload: task.id,
          );
        }
      } else {
        developer.log('Pre-time $preTime is in past or too close, skipping pre for "${task.title}"', name: 'NotificationService');
      }
    }
  }

  /// Cancel BOTH main and pre-reminder for a task
  Future<void> cancelTaskReminder(String taskId) async {
    if (_isLinux) return;
    final mainId = taskId.hashCode;
    final preId = taskId.hashCode + 1;
    try {
      await _notifications.cancel(mainId);
      await _notifications.cancel(preId);
      developer.log('cancelTaskReminder: cancelled main=$mainId pre=$preId', name: 'NotificationService');
    } catch (e) {
      developer.log('cancelTaskReminder FAILED: $e', name: 'NotificationService');
    }
  }

  Future<void> cancelAllReminders() async {
    if (_isLinux) return;
    try {
      await _notifications.cancelAll();
      developer.log('cancelAllReminders done', name: 'NotificationService');
    } catch (e) {
      developer.log('cancelAllReminders FAILED: $e', name: 'NotificationService');
    }
  }

  // ===== RESCHEDULE (app restart / resume) =====

  /// Reschedule only tasks with deadline > now
  Future<void> rescheduleAllTasks(List<Task> tasks) async {
    developer.log('rescheduleAllTasks called with ${tasks.length} tasks', name: 'NotificationService');
    await cancelAllReminders();
    await _scheduleDailySummaries();

    int scheduled = 0;
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.status != TaskStatus.pending && task.status != TaskStatus.snoozed) continue;
      final deadline = task.deadline;
      if (deadline == null || deadline.isBefore(now)) continue;
      await scheduleTaskNotification(task);
      scheduled++;
    }
    developer.log('rescheduleAllTasks done, scheduled $scheduled (filtered by deadline > now)', name: 'NotificationService');
  }

  // ===== DAILY SUMMARIES =====

  /// Schedule morning (08:00) and evening (20:00) daily summaries
  Future<void> _scheduleDailySummaries() async {
    final now = tz.TZDateTime.now(tz.local);

    // Morning summary at 08:00
    var morningTarget = tz.TZDateTime(now.location, now.year, now.month, now.day, 8, 0);
    if (morningTarget.isBefore(now)) {
      morningTarget = morningTarget.add(const Duration(days: 1));
    }
    await _doScheduleSummary(
      id: _morningSummaryId,
      title: '🌅 Chào buổi sáng!',
      body: 'Mở SuperNote để xem hôm nay có task nào cần xử lý không nhé.',
      scheduledDate: morningTarget,
    );

    // Evening summary at 20:00 — generic daily wrap-up (no overdue push)
    var eveningTarget = tz.TZDateTime(now.location, now.year, now.month, now.day, 20, 0);
    if (eveningTarget.isBefore(now)) {
      eveningTarget = eveningTarget.add(const Duration(days: 1));
    }

    final allTasks = _getAllTasksCallback?.call() ?? [];
    final pendingCount = allTasks
        .where((t) => (t.status == TaskStatus.pending || t.status == TaskStatus.snoozed) && t.deadline != null)
        .length;

    if (pendingCount > 0) {
      final body = pendingCount == 1
          ? 'Bạn còn 1 task đang chờ xử lý. Bấm để sắp xếp lại nhé!'
          : 'Bạn còn $pendingCount task đang chờ xử lý. Bấm để sắp xếp lại nhé!';
      await _doScheduleSummary(
        id: _eveningSummaryId,
        title: '📌 Tổng kết ngày',
        body: body,
        scheduledDate: eveningTarget,
      );
    }
  }

  Future<void> _doScheduleSummary({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_summary',
      );
      developer.log('Daily summary scheduled id=$id at $scheduledDate', name: 'NotificationService');
    } catch (e) {
      developer.log('Daily summary FAILED id=$id: $e', name: 'NotificationService');
    }
  }

  // ===== OVERDUE SUMMARY =====

  void setTaskProvider(List<Task> Function() callback) {
    _getAllTasksCallback = callback;
  }

  /// No Overdue Push: KHÔNG bắn Push Notification khi task quá hạn.
  /// Task quá hạn chỉ hiển thị trong section ⚠️ Quá hạn trên In-App UI.
  /// Method này giữ lại để tương thích API, nhưng không gửi notification.
  Future<void> updateOverdueSummary([List<Task>? tasks]) async {
    if (_isLinux) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    final allTasks = tasks ?? _getAllTasksCallback?.call() ?? [];
    final now = DateTime.now();

    int overdueCount = 0;
    for (final task in allTasks) {
      if (task.status != TaskStatus.pending && task.status != TaskStatus.snoozed) continue;
      final deadline = task.deadline;
      if (deadline == null) continue;
      if (deadline.isBefore(now)) overdueCount++;
    }

    // Always cancel any legacy consolidated overdue notification
    await _notifications.cancel(_overdueNotificationId);

    // No push notification for overdue — handled by In-App UI only
    developer.log('updateOverdueSummary: $overdueCount overdue tasks (in-app only, no push)', name: 'NotificationService');
  }

  // ===== QUIET HOURS =====

  /// Returns adjusted time if in quiet hours, or null if the original time is fine.
  /// If adjusted time is too close to another notification, returns null (to signal dropping).
  Future<tz.TZDateTime?> _adjustForQuietHours(tz.TZDateTime scheduled) async {
    final (startHour, endHour) = await getQuietHours();
    final h = scheduled.hour;

    final inQuietHours = startHour > endHour
        ? (h >= startHour || h < endHour)
        : (h >= startHour && h < endHour);

    if (!inQuietHours) return scheduled;

    // Shift to end of quiet hours (07:00 or configured end)
    final shifted = tz.TZDateTime(
      scheduled.location,
      scheduled.year, scheduled.month, scheduled.day,
      endHour, 0, 0,
    );

    // If endHour is earlier than start (wraps midnight), and we're in the
    // evening part, shift to next day's endHour
    if (shifted.isBefore(scheduled)) {
      return shifted.add(const Duration(days: 1));
    }
    return shifted;
  }

  // ===== LOW-LEVEL SCHEDULING =====

  Future<void> _doSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    // Truncate microseconds
    final cleanDate = tz.TZDateTime(
      scheduledDate.location,
      scheduledDate.year, scheduledDate.month, scheduledDate.day,
      scheduledDate.hour, scheduledDate.minute, scheduledDate.second,
    );

    // Try inexact first — works reliably on all Android versions
    try {
      await _notifications.zonedSchedule(
        id, title, body, cleanDate,
        _taskNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log('zonedSchedule(inexact) OK id=$id at $cleanDate', name: 'NotificationService');
      return;
    } catch (e) {
      developer.log('Inexact alarm failed id=$id: $e', name: 'NotificationService');
    }

    // Fallback: exact alarm
    try {
      await _notifications.zonedSchedule(
        id, title, body, cleanDate,
        _taskNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log('zonedSchedule(exact) OK id=$id at $cleanDate', name: 'NotificationService');
    } catch (e) {
      developer.log('Exact alarm FAILED id=$id: $e — notification NOT scheduled', name: 'NotificationService');
    }
  }

  // ===== QUIET HOURS GET/SET =====

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

  // ===== DEFAULT PRE-REMINDER =====

  Future<void> setDefaultPreReminder(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyDefaultPreReminder, minutes);
  }

  Future<int> getDefaultPreReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyDefaultPreReminder) ?? 0;
  }

  // ===== TEST =====

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
      id: 99998,
      title: '🔔 SuperNote',
      body: 'Thông báo đã hoạt động! Bạn sẽ nhận được nhắc nhở đúng giờ.',
      payload: 'test',
    );

    return true;
  }

  Future<void> _postNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool withActions = true,
  }) async {
    try {
      await _notifications.show(id, title, body, _taskNotificationDetails(withActions: withActions), payload: payload);
      developer.log('_postNotification SUCCESS id=$id "$title"', name: 'NotificationService');
    } catch (e) {
      developer.log('_postNotification FAILED id=$id: $e', name: 'NotificationService');
    }
  }

  // ===== RANDOM VIETNAMESE MESSAGES =====

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

  String _formatDuration(int minutes) {
    if (minutes >= 1440) return '${minutes ~/ 1440} ngày';
    if (minutes >= 60) return '${minutes ~/ 60} tiếng';
    return '$minutes phút';
  }
}
