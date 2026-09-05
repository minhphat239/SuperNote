import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

/// Duolingo-style inactivity retention notifications.
///
/// Mốc 1 (24h): Nhắc nhẹ lúc 20:00 PM tối hôm sau
/// Mốc 2 (3d):  Nhắc níu kéo lúc 09:00 AM
/// Mốc 3 (7d):  Thông báo chốt lúc 09:00 AM trước khi dừng
///
/// Auto-reset on resume → xóa 3 lịch cũ, tạo lại mới.
class InactivityRetentionService {
  static final InactivityRetentionService _instance = InactivityRetentionService._internal();
  factory InactivityRetentionService() => _instance;
  InactivityRetentionService._internal();

  static const int _notifId24h = 9001;
  static const int _notifId3d = 9003;
  static const int _notifId7d = 9007;

  static const String _keyLastOpen = 'inactivity_last_open';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ===== INIT =====

  /// Called on app start. Records last open time and schedules retention.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_keyLastOpen, now.toIso8601String());

    await _scheduleRetentionIfNeeded();
  }

  /// Called on every resume. Resets the inactivity clock.
  Future<void> onResume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastOpen, DateTime.now().toIso8601String());
    await _cancelAllRetention();
    await _scheduleRetentionIfNeeded();
  }

  // ===== SCHEDULE =====

  Future<void> _scheduleRetentionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenStr = prefs.getString(_keyLastOpen);
    if (lastOpenStr == null) return;

    final lastOpen = DateTime.tryParse(lastOpenStr);
    if (lastOpen == null) return;

    final now = DateTime.now();
    final inactiveHours = now.difference(lastOpen).inHours;

    // Mốc 1: 24h → schedule at 20:00 PM next day
    if (inactiveHours >= 24) {
      await _scheduleRetentionNotif(
        id: _notifId24h,
        title: 'Hôm nay bạn chưa vào app 📝',
        body: 'SuperNote nhớ bạn! Mở app để sắp xếp lịch thôi.',
        hour: 20, minute: 0,
      );
    }

    // Mốc 2: 3 ngày → schedule at 09:00 AM
    if (inactiveHours >= 72) {
      await _scheduleRetentionNotif(
        id: _notifId3d,
        title: '📌 Bạn đã bỏ lỡ vài task!',
        body: 'Đã 3 ngày bạn chưa mở app. Có task đang chờ bạn xử lý đó!',
        hour: 9, minute: 0,
      );
    }

    // Mốc 3: 7 ngày → schedule at 09:00 AM (final)
    if (inactiveHours >= 168) {
      await _scheduleRetentionNotif(
        id: _notifId7d,
        title: '🔔 SuperNote sắp quên bạn rồi...',
        body: 'Đã 1 tuần! Mở app ngay để không bỏ lỡ bất kỳ task nào nhé.',
        hour: 9, minute: 0,
      );
    }
  }

  Future<void> _scheduleRetentionNotif({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var target = tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        target,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'supernote_reminders',
            'Task Reminders',
            channelDescription: 'Inactivity retention notifications',
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
        payload: 'retention_$id',
      );
      developer.log('Retention notif scheduled id=$id at $target', name: 'InactivityRetention');
    } catch (e) {
      developer.log('Retention notif FAILED id=$id: $e', name: 'InactivityRetention');
    }
  }

  // ===== CANCEL =====

  Future<void> _cancelAllRetention() async {
    try {
      await _notifications.cancel(_notifId24h);
      await _notifications.cancel(_notifId3d);
      await _notifications.cancel(_notifId7d);
      developer.log('All retention notifs cancelled', name: 'InactivityRetention');
    } catch (e) {
      developer.log('Cancel retention FAILED: $e', name: 'InactivityRetention');
    }
  }
}
