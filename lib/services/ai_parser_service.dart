import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../models/task.dart';

class AiParsedTask {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final TaskCategory category;
  final String? repeatRule;
  final DateTime? repeatEndDate;
  final int? preReminderOffset;
  final List<String> tags;
  final String? description;
  final bool success;
  final String? errorMessage;

  const AiParsedTask({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.category = TaskCategory.personal,
    this.repeatRule,
    this.repeatEndDate,
    this.preReminderOffset,
    this.tags = const [],
    this.description,
    this.success = true,
    this.errorMessage,
  });

  Task toTask() {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description ?? '',
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      repeatRule: repeatRule,
      repeatEndDate: repeatEndDate,
      preReminderOffset: preReminderOffset,
      status: TaskStatus.pending,
    );
  }
}

class AiParserService {
  static final AiParserService _instance = AiParserService._internal();
  factory AiParserService() => _instance;
  AiParserService._internal();

  static const String _apiKeyPref = 'gemini_api_key';
  static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY';
  static const String _modelName = 'gemini-3.1-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';

  String _apiKey = _defaultApiKey;
  bool _initialized = false;

  bool get isConfigured => _apiKey != _defaultApiKey && _apiKey.isNotEmpty;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_apiKeyPref) ?? _defaultApiKey;
      _initialized = true;
    } catch (e) {
      developer.log('AiParserService init failed', error: e, name: 'AiParserService');
    }
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == _defaultApiKey || key.isEmpty) {
      await prefs.remove(_apiKeyPref);
    } else {
      await prefs.setString(_apiKeyPref, key);
    }
  }

  Future<AiParsedTask> parseTaskInput(String input) async {
    if (isConfigured) {
      try {
        final result = await _parseWithGemini(input)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw Exception('AI timeout — dùng parser nội bộ'),
            );
        if (result.success) return result;
      } catch (e) {
        developer.log('Gemini parse failed/timeout, fallback to regex', error: e, name: 'AiParserService');
      }
    }
    return _parseWithRegex(input);
  }

  Future<AiParsedTask> _parseWithGemini(String input) async {
    try {
      final prompt = '''
Parse the following task input into structured JSON. Return ONLY valid JSON, no extra text.

Input: "$input"

Return JSON with these keys:
- "title": string (required) - the main task title
- "dueDate": string or null - date in YYYY-MM-DD format, or relative like "tomorrow", "next monday"
- "dueTime": string or null - time in HH:MM format
- "category": string - one of: "class_", "exam", "assignment", "personal"
- "repeatRule": string or null - e.g., "daily", "weekly", "weekly:1,3,5", "monthly"
- "repeatEndDate": string or null - date in YYYY-MM-DD format
- "preReminderOffset": number or null - minutes before the task to remind
- "tags": array of strings - extracted tags
- "description": string or null - additional description

Example input: "Nộp bài tập toán trước 11h đêm mai #Bài_tập nhắc trước 30 phút"
Example output: {"title":"Nộp bài tập toán","dueDate":"tomorrow","dueTime":"23:00","category":"assignment","repeatRule":null,"repeatEndDate":null,"preReminderOffset":30,"tags":["Bài_tập"],"description":null}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 512,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          final text = parts[0]['text'] as String;

          final jsonStr = _extractJson(text);
          if (jsonStr != null) {
            final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
            return _mapGeminiResponse(parsed, input);
          }
        }
        return _parseWithRegex(input);
      } else {
        developer.log('Gemini API error: ${response.statusCode}', name: 'AiParserService');
        return _parseWithRegex(input);
      }
    } catch (e) {
      developer.log('Gemini parse exception', error: e, name: 'AiParserService');
      return _parseWithRegex(input);
    }
  }

  AiParsedTask _mapGeminiResponse(Map<String, dynamic> data, String originalInput) {
    try {
      final title = (data['title'] as String?)?.trim() ?? _extractTitleFromInput(originalInput);

      DateTime? dueDate;
      final dueDateStr = data['dueDate'] as String?;
      if (dueDateStr != null) {
        dueDate = _parseDateString(dueDateStr);
      }

      DateTime? dueTime;
      final dueTimeStr = data['dueTime'] as String?;
      if (dueTimeStr != null) {
        dueTime = _parseTimeString(dueTimeStr);
      }

      TaskCategory category;
      try {
        final catStr = data['category'] as String?;
        if (catStr != null) {
          category = TaskCategory.values.byName(catStr);
        } else {
          category = _detectCategoryFromInput(originalInput);
        }
      } catch (_) {
        category = _detectCategoryFromInput(originalInput);
      }

      final tags = (data['tags'] as List?)
              ?.map((t) => t.toString())
              .toList() ??
          [];

      return AiParsedTask(
        title: title,
        dueDate: dueDate,
        dueTime: dueTime,
        category: category,
        repeatRule: data['repeatRule'] as String?,
        repeatEndDate: data['repeatEndDate'] != null
            ? _parseDateString(data['repeatEndDate'] as String)
            : null,
        preReminderOffset: data['preReminderOffset'] as int?,
        tags: tags,
        description: data['description'] as String?,
      );
    } catch (e) {
      developer.log('Failed to map Gemini response', error: e, name: 'AiParserService');
      return _parseWithRegex(originalInput);
    }
  }

  // ===== REGEX FALLBACK PARSER =====

  AiParsedTask _parseWithRegex(String input) {
    String title = input;
    DateTime? dueDate;
    DateTime? dueTime;
    TaskCategory category = TaskCategory.personal;
    String? repeatRule;
    int? preReminderOffset;
    final tags = <String>[];

    final now = DateTime.now();

    // Extract tags
    final tagPattern = RegExp(r'#(\w+)');
    for (final m in tagPattern.allMatches(input)) {
      tags.add(m.group(1)!);
    }
    title = title.replaceAll(tagPattern, '');

    // Detect category
    category = _detectCategoryFromInput(input);

    // Extract date
    final lower = input.toLowerCase();
    if (lower.contains('tomorrow') || lower.contains('ngày mai') || lower.contains('mai ')) {
      dueDate = DateTime(now.year, now.month, now.day + 1);
      title = title.replaceAll(RegExp(r'tomorrow|ngày mai|mai ', caseSensitive: false), '');
    } else if (lower.contains('today') || lower.contains('hôm nay')) {
      dueDate = DateTime(now.year, now.month, now.day);
      title = title.replaceAll(RegExp(r'today|hôm nay', caseSensitive: false), '');
    } else if (lower.contains('next week') || lower.contains('tuần sau')) {
      dueDate = now.add(const Duration(days: 7));
      title = title.replaceAll(RegExp(r'next week|tuần sau', caseSensitive: false), '');
    }

    // Date patterns: dd/mm, dd/mm/yyyy
    final dateMatch = RegExp(r'(\d{1,2})/(\d{1,2})(?:/(\d{4}))?').firstMatch(input);
    if (dateMatch != null && dueDate == null) {
      try {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = dateMatch.group(3) != null ? int.parse(dateMatch.group(3)!) : now.year;
        dueDate = DateTime(year, month, day);
        title = title.replaceAll(RegExp(r'\d{1,2}/\d{1,2}(?:/\d{4})?'), '');
      } catch (_) {}
    }

    // Extract time
    final timeMatch = RegExp(r'(\d{1,2})[:h](\d{2})?\s*(AM|PM|am|pm)?').firstMatch(lower);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = 0;
      if (timeMatch.group(2) != null) {
        minute = int.parse(timeMatch.group(2)!);
      }
      final ampm = timeMatch.group(3)?.toLowerCase();
      if (ampm != null) {
        if (ampm.contains('pm') && hour < 12) hour += 12;
        if (ampm.contains('am') && hour == 12) hour = 0;
      }
      if (hour >= 0 && hour <= 23) {
        dueTime = DateTime(2000, 1, 1, hour, minute);
        title = title.replaceAll(RegExp(r'\d{1,2}[:h]\d{2}?\s*(AM|PM|am|pm)?', caseSensitive: false), '');
      }
    }

    // Extract pre-reminder
    final reminderMatch = RegExp(r'nhắc trước\s+(\d+)\s*(phút|giờ)').firstMatch(lower);
    if (reminderMatch != null) {
      final value = int.parse(reminderMatch.group(1)!);
      final unit = reminderMatch.group(2)!;
      preReminderOffset = unit.contains('giờ') ? value * 60 : value;
      title = title.replaceAll(RegExp(r'nhắc trước\s+\d+\s*(phút|giờ)', caseSensitive: false), '');
    }

    // Extract repeat
    if (lower.contains('every day') || lower.contains('hàng ngày') || lower.contains('mỗi ngày')) {
      repeatRule = 'daily';
      title = title.replaceAll(RegExp(r'every day|hàng ngày|mỗi ngày', caseSensitive: false), '');
    } else if (lower.contains('every week') || lower.contains('hàng tuần') || lower.contains('mỗi tuần')) {
      repeatRule = 'weekly';
      title = title.replaceAll(RegExp(r'every week|hàng tuần|mỗi tuần', caseSensitive: false), '');
    } else if (lower.contains('every month') || lower.contains('hàng tháng') || lower.contains('mỗi tháng')) {
      repeatRule = 'monthly';
      title = title.replaceAll(RegExp(r'every month|hàng tháng|mỗi tháng', caseSensitive: false), '');
    }

    // Clean title
    title = title.replaceAll(RegExp(r'[,\s]+$'), '').replaceAll(RegExp(r'^[,\s]+'), '').trim();
    if (title.isEmpty) title = 'Untitled Task';

    return AiParsedTask(
      title: title,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      repeatRule: repeatRule,
      preReminderOffset: preReminderOffset,
      tags: tags,
    );
  }

  TaskCategory _detectCategoryFromInput(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('exam') || lower.contains('thi') || lower.contains('test') ||
        lower.contains('midterm') || lower.contains('final') || lower.contains('quiz') ||
        lower.contains('kiem tra') || lower.contains('bai thi') || lower.contains('bài thi') ||
        lower.contains('#exam') || lower.contains('#thi') || lower.contains('#test')) {
      return TaskCategory.exam;
    }

    if (lower.contains('assignment') || lower.contains('homework') ||
        lower.contains('bai tap') || lower.contains('bài tập') ||
        lower.contains('submit') || lower.contains('nộp') || lower.contains('nop') ||
        lower.contains('deadline') || lower.contains('han nop') || lower.contains('hạn nộp') ||
        lower.contains('#assignment') || lower.contains('#baitap') || lower.contains('#bt')) {
      return TaskCategory.assignment;
    }

    if (lower.contains('class') || lower.contains('lecture') ||
        lower.contains('lab') || lower.contains('hoc') || lower.contains('học') ||
        lower.contains('buoi') || lower.contains('buổi') ||
        lower.contains('mon') || lower.contains('môn') ||
        lower.contains('#class') || lower.contains('#lop') || lower.contains('#hoc')) {
      return TaskCategory.class_;
    }

    return TaskCategory.personal;
  }

  String _extractTitleFromInput(String input) {
    var title = input;
    title = title.replaceAll(RegExp(r'#\w+'), '');
    title = title.replaceAll(RegExp(r'tomorrow|today|next week|ngày mai|hôm nay|tuần sau', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\d{1,2}/\d{1,2}(?:/\d{4})?'), '');
    title = title.replaceAll(RegExp(r'\d{1,2}[:h]\d{2}?\s*(AM|PM|am|pm)?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'nhắc trước\s+\d+\s*(phút|giờ)', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'every (day|week|month)|hàng (ngày|tuần|tháng)|mỗi (ngày|tuần|tháng)', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'[,\s]+$'), '').replaceAll(RegExp(r'^[,\s]+'), '').trim();
    return title.isEmpty ? 'Untitled Task' : title;
  }

  DateTime? _parseDateString(String str) {
    final now = DateTime.now();
    final lower = str.toLowerCase();

    if (lower == 'tomorrow') return DateTime(now.year, now.month, now.day + 1);
    if (lower == 'today') return DateTime(now.year, now.month, now.day);
    if (lower == 'next week') return now.add(const Duration(days: 7));

    try {
      return DateTime.parse(str);
    } catch (_) {}

    final match = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
    if (match != null) {
      try {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      } catch (_) {}
    }

    return null;
  }

  DateTime? _parseTimeString(String str) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?').firstMatch(str);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final ampm = match.group(3)?.toLowerCase();
      if (ampm != null) {
        if (ampm.contains('pm') && hour < 12) hour += 12;
        if (ampm.contains('am') && hour == 12) hour = 0;
      }
      if (hour >= 0 && hour <= 23) {
        return DateTime(2000, 1, 1, hour, minute);
      }
    }
    return null;
  }

  String? _extractJson(String text) {
    final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(text);
    return jsonMatch?.group(0);
  }
}
