import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

/// FCM Service — subscribes to admin broadcast topic,
/// handles foreground messages via local notification display.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static const String _topicAllUsers = 'all_users';
  static const int _fcmForegroundNotifId = 555555;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // ===== INIT =====

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return;
    _initialized = true;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      developer.log('FCM permission: ${settings.authorizationStatus}', name: 'FcmService');

      // Get token
      _fcmToken = await _messaging.getToken();
      developer.log('FCM token: $_fcmToken', name: 'FcmService');

      // Subscribe to topic
      await _messaging.subscribeToTopic(_topicAllUsers);
      developer.log('Subscribed to topic: $_topicAllUsers', name: 'FcmService');

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Handle notification tap when app was terminated/background
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Check if app opened from notification (cold start)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedApp(initialMessage);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        developer.log('FCM token refreshed: $token', name: 'FcmService');
      });
    } catch (e) {
      developer.log('FCM init failed: $e', name: 'FcmService');
    }
  }

  // ===== MESSAGE OPENED (TERMINATED/BACKGROUND) =====

  void _onMessageOpenedApp(RemoteMessage message) {
    developer.log('FCM onMessageOpenedApp: ${message.messageId}', name: 'FcmService');
    // The notification was already shown by the OS when app was terminated/background.
    // If app needs to navigate somewhere based on data, handle it here.
  }

  // ===== FOREGROUND MESSAGE HANDLING =====

  void _onForegroundMessage(RemoteMessage message) {
    developer.log('FCM foreground message: ${message.messageId}', name: 'FcmService');

    final notification = message.notification;
    if (notification == null) return;

    // Display as local notification when app is in foreground
    _showForegroundNotification(
      title: notification.title ?? 'SuperNote',
      body: notification.body ?? '',
      payload: message.data.isNotEmpty ? message.data.toString() : 'fcm_broadcast',
    );
  }

  Future<void> _showForegroundNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _notifications.show(
        _fcmForegroundNotifId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'supernote_reminders',
            'Task Reminders',
            channelDescription: 'Admin broadcast and system notifications',
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
        payload: payload,
      );
      developer.log('Foreground FCM displayed as local notif', name: 'FcmService');
    } catch (e) {
      developer.log('Foreground FCM display failed: $e', name: 'FcmService');
    }
  }
}
