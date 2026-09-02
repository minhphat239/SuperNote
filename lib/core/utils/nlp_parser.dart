import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NlpResult {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final List<String> tags;
  final String? priority;

  const NlpResult({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.tags = const [],
    this.priority,
  });

  DateTime? get deadline {
    if (dueDate == null && dueTime == null) return null;
    final now = DateTime.now();
    final date = dueDate ?? DateTime(now.year, now.month, now.day);
    if (dueTime != null) {
      return DateTime(date.year, date.month, date.day, dueTime!.hour, dueTime!.minute);
    }
    // No specific time → end-of-day so a task created today with no time isn't
    // marked overdue until midnight passes.
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  Color? get priorityColor {
    if (priority == null) return null;
    return AppColors.priorityColors[priority];
  }
}

class NlpParser {
  // ===== TIME: "3pm", "15:30", "3h30", "lúc 3h", "3 giờ" =====
  static final _timePatterns = [
    RegExp(r'(\d{1,2})\s*(AM|PM|am|pm)', caseSensitive: false),
    RegExp(r'(\d{1,2}):(\d{2})'),
    RegExp(r'(\d{1,2})h(\d{2})'),
    RegExp(r'lúc\s+(\d{1,2})[:\s]*(\d{0,2})'),
    RegExp(r'(\d{1,2})\s*giờ'),
  ];

  // ===== DATE: "mai", "ngày mai", "hom nay", "3 ngày nữa", "thứ 2", "friday", "12/25" =====
  static final _relativeDayPatterns = {
    RegExp(r'tomorrow|ngày\s*mai|mai\b'): 1,
    RegExp(r'hôm\s*nay|today|hnay'): 0,
    RegExp(r'next\s*week|tuần\s*sau'): 7,
  };

  static final _relativeNDaysPattern = RegExp(r'(\d+)\s*(ngày|days?)\s*(nữa|sau)?', caseSensitive: false);

  static final _weekdayMap = {
    'monday': 1, 'mon': 1, 'thứ 2': 1, 'thu 2': 1, 't2': 1,
    'tuesday': 2, 'tue': 2, 'thứ 3': 2, 'thu 3': 2, 't3': 2,
    'wednesday': 3, 'wed': 3, 'thứ 4': 3, 'thu 4': 3, 't4': 3,
    'thursday': 4, 'thu': 4, 'thứ 5': 4, 'thu 5': 4, 't5': 4,
    'friday': 5, 'fri': 5, 'thứ 6': 5, 'thu 6': 5, 't6': 5,
    'saturday': 6, 'sat': 6, 'thứ 7': 6, 'thu 7': 6, 't7': 6,
    'sunday': 7, 'sun': 7, 'chủ nhật': 7, 'cn': 7,
  };

  // ===== TAG: "#work", "#study" =====
  static final _tagPattern = RegExp(r'#(\w+)');

  // ===== PRIORITY: "!high", "!urgent", "!medium", "!low" =====
  static final _priorityPattern = RegExp(r'!(high|urgent|medium|low|cao|thấp)', caseSensitive: false);

  static NlpResult parse(String input) {
    String remaining = input.trim();
    if (remaining.isEmpty) return const NlpResult(title: '');

    DateTime? dueDate;
    DateTime? dueTime;
    final tags = <String>[];
    String? priority;

    // 1. Extract tags
    for (final m in _tagPattern.allMatches(remaining)) {
      tags.add(m.group(1)!);
    }
    remaining = remaining.replaceAll(_tagPattern, ' ');

    // 2. Extract priority
    final priMatch = _priorityPattern.firstMatch(remaining);
    if (priMatch != null) {
      final raw = priMatch.group(1)!.toLowerCase();
      if (raw == 'high' || raw == 'urgent' || raw == 'cao') {
        priority = 'high';
      } else if (raw == 'medium') {
        priority = 'medium';
      } else {
        priority = 'low';
      }
      remaining = remaining.replaceAll(_priorityPattern, ' ');
    }

    // 3. Extract time
    for (final pattern in _timePatterns) {
      final match = pattern.firstMatch(remaining);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = 0;

        final group2 = match.groupCount >= 2 ? match.group(2) : null;
        if (group2 != null) {
          if (group2.toLowerCase().contains('pm') && hour < 12) hour += 12;
          if (group2.toLowerCase().contains('am') && hour == 12) hour = 0;
          if (RegExp(r'^\d+$').hasMatch(group2)) minute = int.parse(group2);
        }
        if (match.groupCount >= 3 && match.group(3) != null && RegExp(r'^\d+$').hasMatch(match.group(3)!)) {
          minute = int.parse(match.group(3)!);
        }
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          dueTime = DateTime(2000, 1, 1, hour, minute);
        }
        remaining = remaining.replaceAll(match.group(0)!, ' ');
        break;
      }
    }

    // 4. Extract date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final entry in _relativeDayPatterns.entries) {
      if (entry.key.hasMatch(remaining)) {
        dueDate = today.add(Duration(days: entry.value));
        remaining = remaining.replaceAll(entry.key, ' ');
        break;
      }
    }

    if (dueDate == null) {
      final ndMatch = _relativeNDaysPattern.firstMatch(remaining);
      if (ndMatch != null) {
        final n = int.parse(ndMatch.group(1)!);
        dueDate = today.add(Duration(days: n));
        remaining = remaining.replaceAll(_relativeNDaysPattern, ' ');
      }
    }

    if (dueDate == null) {
      final lower = remaining.toLowerCase();
      for (final entry in _weekdayMap.entries) {
        if (lower.contains(entry.key)) {
          final target = entry.value;
          var diff = target - now.weekday;
          if (diff <= 0) diff += 7;
          dueDate = today.add(Duration(days: diff));
          remaining = remaining.replaceAll(RegExp(RegExp.escape(entry.key), caseSensitive: false), ' ');
          break;
        }
      }
    }

    if (dueDate == null) {
      final slashDate = RegExp(r'(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?').firstMatch(remaining);
      if (slashDate != null) {
        final day = int.parse(slashDate.group(1)!);
        final month = int.parse(slashDate.group(2)!);
        final year = slashDate.group(3) != null ? int.parse(slashDate.group(3)!) : now.year;
        try {
          dueDate = DateTime(year < 100 ? 2000 + year : year, month, day);
        } catch (_) {}
        remaining = remaining.replaceAll(slashDate.group(0)!, ' ');
      }
    }

    // 5. Clean title
    String title = remaining
        .replaceAll(RegExp(r'[,\-:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isEmpty) title = 'Untitled Task';

    return NlpResult(
      title: title,
      dueDate: dueDate,
      dueTime: dueTime,
      tags: tags,
      priority: priority,
    );
  }
}
