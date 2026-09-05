import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// UserFeedbackService - Gửi feedback ẩn danh qua Google Apps Script
///
/// Setup:
/// 1. Tạo Google Sheet mới
/// 2. Vào Extensions → Apps Script
/// 3. Copy code từ assets/apps_script_example.js vào
/// 4. Deploy as Web App (Anyone can access)
/// 5. Copy URL Web App vào setting trong app
class UserFeedbackService {
  static final UserFeedbackService _instance = UserFeedbackService._internal();
  factory UserFeedbackService() => _instance;
  UserFeedbackService._internal();

  static const String _prefsKeyFeedbackUrl = 'feedback_webhook_url';
  static const String _prefsKeyLastFeedbackTime = 'feedback_last_time';
  static const int _cooldownSeconds = 60; // Chống spam: 60 giây giữa 2 lần gửi

  /// URL Web App từ Google Apps Script
  Future<String?> getFeedbackUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyFeedbackUrl);
  }

  /// Lưu URL Web App
  Future<void> setFeedbackUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyFeedbackUrl, url);
  }

  /// Kiểm tra cooldown (chống spam)
  Future<bool> _canSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(_prefsKeyLastFeedbackTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - lastTime) >= _cooldownSeconds;
  }

  /// Cập nhật thời gian gửi cuối
  Future<void> _updateLastSubmitTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await prefs.setInt(_prefsKeyLastFeedbackTime, now);
  }

  /// Gửi feedback qua Google Apps Script
  Future<FeedbackResult> submitFeedback(String message) async {
    if (message.trim().isEmpty) {
      return FeedbackResult(success: false, message: 'Message is empty');
    }

    // Kiểm tra cooldown
    if (!await _canSubmit()) {
      return FeedbackResult(
        success: false,
        message: 'Please wait before sending another feedback',
      );
    }

    final url = await getFeedbackUrl();
    if (url == null || url.isEmpty) {
      return FeedbackResult(
        success: false,
        message: 'Feedback URL not configured',
      );
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final payload = {
        'message': message.trim(),
        'platform': defaultTargetPlatform.name,
        'appVersion': packageInfo.version,
        'appBuild': packageInfo.buildNumber,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _updateLastSubmitTime();
        developer.log('Feedback submitted successfully', name: 'UserFeedbackService');
        return FeedbackResult(success: true, message: 'Feedback sent');
      } else {
        developer.log('Feedback failed: ${response.statusCode}', name: 'UserFeedbackService');
        return FeedbackResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('Feedback error: $e', name: 'UserFeedbackService');
      return FeedbackResult(
        success: false,
        message: 'Network error: ${e.runtimeType}',
      );
    }
  }
}

class FeedbackResult {
  final bool success;
  final String message;

  FeedbackResult({required this.success, required this.message});
}
