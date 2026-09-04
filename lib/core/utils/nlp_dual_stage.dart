import '../../models/task.dart';

// ===== INTENT TYPE =====
enum TaskIntent {
  event,    // Họp, sự kiện, buổi học → nhắc trước 30p
  deadline, // Deadline, bài tập, nộp → nhắc trước 2h
  reminder, // Nhắc nhở chung → nhắc trước 15p
}

// ===== DUAL-STAGE RESULT =====
class DualStageResult {
  final String title;
  final TaskIntent intent;
  final DateTime? targetTime;
  final TaskCategory category;
  final List<String> tags;

  // Stage 1: Preparation reminder
  final DateTime? stage1Time;
  final String stage1Label;

  // Stage 2: Main reminder
  final DateTime? stage2Time;
  final String stage2Label;

  // Extra fields from AI
  final int? preReminderOffset;
  final String? description;

  const DualStageResult({
    required this.title,
    required this.intent,
    this.targetTime,
    this.category = TaskCategory.personal,
    this.tags = const [],
    this.stage1Time,
    this.stage1Label = '',
    this.stage2Time,
    this.stage2Label = '',
    this.preReminderOffset,
    this.description,
  });

  bool get hasTime => targetTime != null;
  bool get hasStage1 => stage1Time != null;
  bool get hasStage2 => stage2Time != null;

  /// Pre-reminder offset in minutes for Stage 1
  int? get stage1OffsetMinutes {
    if (stage1Time == null || targetTime == null) return null;
    return targetTime!.difference(stage1Time!).inMinutes;
  }
}

// ===== NLP DUAL-STAGE PARSER =====
class NlpDualStageParser {
  // ===== EVENT keywords =====
  static final _eventKeywords = RegExp(
    r'(họp|hop|meeting|interview|phỏng vấn|buổi|session|class|tiết|lớp|lecture|seminar|webinar|sự kiện|event|thuyết trình|presentation|demo|standup|daily|review|sync|call|gọi|zoom|teams|meet)',
    caseSensitive: false,
  );

  // ===== DEADLINE keywords =====
  static final _deadlineKeywords = RegExp(
    r'(nộp|nop|submit|deadline|hạn|hand-in|bài tập|assignment|homework|lab|report|báo cáo|project|đồ án|thesis|luận văn|essay|paper|bài kiểm tra|quiz|exam|thi|test|midterm|final)',
    caseSensitive: false,
  );

  // ===== REMINDER keywords =====
  static final _reminderKeywords = RegExp(
    r'(nhắc|nhac|remind|remember|đừng quên|don.t forget|ghi nhớ|note|lưu ý|提醒)',
    caseSensitive: false,
  );

  // ===== TIME patterns =====
  static final _timePatterns = [
    RegExp(r'(\d{1,2})\s*(AM|PM|am|pm)', caseSensitive: false),
    RegExp(r'(\d{1,2}):(\d{2})'),
    RegExp(r'(\d{1,2})h(\d{0,2})'),
    RegExp(r'lúc\s+(\d{1,2})[:\s]*(\d{0,2})'),
    RegExp(r'(\d{1,2})\s*giờ'),
  ];

  // ===== DATE patterns =====
  static final _relativeDayMap = {
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

  // ===== TAG & CATEGORY patterns =====
  static final _tagPattern = RegExp(r'#(\w+)');

  static final _categoryKeywordMap = {
    TaskCategory.class_: RegExp(r'(class|lecture|lab|hoc|học|buoi|buổi|mon|môn|tiết|lớp)', caseSensitive: false),
    TaskCategory.exam: RegExp(r'(exam|thi|test|midterm|final|quiz|kiem tra|bai thi)', caseSensitive: false),
    TaskCategory.assignment: RegExp(r'(assignment|homework|bai tap|bài tập|submit|nộp|deadline|han nop)', caseSensitive: false),
  };

  // ===== MAIN PARSE FUNCTION =====
  static DualStageResult parse(String input) {
    if (input.trim().isEmpty) {
      return const DualStageResult(title: '', intent: TaskIntent.reminder);
    }

    String remaining = input.trim();

    // 1. Extract tags
    final tags = <String>[];
    for (final m in _tagPattern.allMatches(remaining)) {
      tags.add(m.group(1)!);
    }
    remaining = remaining.replaceAll(_tagPattern, ' ');

    // 2. Detect intent
    final intent = _detectIntent(remaining, tags);

    // 3. Detect category from tags + keywords
    final category = _detectCategory(remaining, tags);

    // 4. Extract time
    final time = _extractTime(remaining);

    // 5. Extract date
    final date = _extractDate(remaining);

    // 6. Build target time
    DateTime? targetTime;
    if (date != null && time != null) {
      targetTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } else if (date != null) {
      targetTime = date;
    } else if (time != null) {
      // If only time given, use today if time hasn't passed, else tomorrow
      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      targetTime = todayTime.isAfter(now) ? todayTime : todayTime.add(const Duration(days: 1));
    }

    // 7. Clean title
    String title = _cleanTitle(remaining);

    // 8. Calculate 2-stage reminders
    DateTime? stage1Time;
    String stage1Label = '';
    DateTime? stage2Time;
    String stage2Label = '';

    if (targetTime != null) {
      stage2Time = targetTime;
      final now = DateTime.now();

      // Calculate stage1 (pre-reminder) based on intent, but cap it:
      // - stage1 must be in the future
      // - stage1 must be at least 5 min before target
      // - if task is < 30min away, no stage1 (too close)
      int defaultMinutes;
      switch (intent) {
        case TaskIntent.event:
          defaultMinutes = 30;
          break;
        case TaskIntent.deadline:
          defaultMinutes = 120;
          break;
        case TaskIntent.reminder:
          defaultMinutes = 15;
          break;
      }

      final gapToTarget = targetTime.difference(now).inMinutes;
      if (gapToTarget > 30) {
        // Task is far enough — cap stage1 to be at least 5min before target
        final maxOffset = gapToTarget - 5;
        final offset = defaultMinutes < maxOffset ? defaultMinutes : maxOffset;
        if (offset >= 5) {
          stage1Time = targetTime.subtract(Duration(minutes: offset));
          stage1Label = intent == TaskIntent.reminder ? 'Nhắc nhở' : 'Nhắc chuẩn bị';
        }
      }
      // If task is <= 30 min away, skip stage1 entirely (no point reminding)

      stage2Label = switch (intent) {
        TaskIntent.event => 'Bắt đầu',
        TaskIntent.deadline => 'Hạn cuối',
        TaskIntent.reminder => 'Đúng giờ',
      };
    }

    return DualStageResult(
      title: title,
      intent: intent,
      targetTime: targetTime,
      category: category,
      tags: tags,
      stage1Time: stage1Time,
      stage1Label: stage1Label,
      stage2Time: stage2Time,
      stage2Label: stage2Label,
    );
  }

  // ===== INTENT DETECTION =====
  static TaskIntent _detectIntent(String text, List<String> tags) {
    final lower = text.toLowerCase();

    // Check tags first
    for (final tag in tags) {
      final t = tag.toLowerCase();
      if (['meeting', 'hop', 'họp', 'event', 'class', 'session'].contains(t)) return TaskIntent.event;
      if (['deadline', 'nop', 'nộp', 'assignment', 'exam', 'thi'].contains(t)) return TaskIntent.deadline;
    }

    // Check keywords
    if (_eventKeywords.hasMatch(lower)) return TaskIntent.event;
    if (_deadlineKeywords.hasMatch(lower)) return TaskIntent.deadline;
    if (_reminderKeywords.hasMatch(lower)) return TaskIntent.reminder;

    // Default: if has time → event, else → reminder
    return _timePatterns.any((p) => p.hasMatch(lower)) ? TaskIntent.event : TaskIntent.reminder;
  }

  // ===== CATEGORY DETECTION =====
  static TaskCategory _detectCategory(String text, List<String> tags) {
    final lower = text.toLowerCase();

    // From tags
    for (final tag in tags) {
      final t = tag.toLowerCase();
      if (['class', 'hoc', 'học', 'lop', 'lop'].contains(t)) return TaskCategory.class_;
      if (['exam', 'thi', 'test'].contains(t)) return TaskCategory.exam;
      if (['assignment', 'homework', 'baitap', 'bt', 'deadline'].contains(t)) return TaskCategory.assignment;
      if (['personal', 'canhan'].contains(t)) return TaskCategory.personal;
    }

    // From keywords
    for (final entry in _categoryKeywordMap.entries) {
      if (entry.value.hasMatch(lower)) return entry.key;
    }

    return TaskCategory.personal;
  }

  // ===== TIME EXTRACTION =====
  static DateTime? _extractTime(String text) {
    for (final pattern in _timePatterns) {
      final match = pattern.firstMatch(text);
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
          return DateTime(2000, 1, 1, hour, minute);
        }
      }
    }
    return null;
  }

  // ===== DATE EXTRACTION =====
  static DateTime? _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lower = text.toLowerCase();

    // Relative days
    for (final entry in _relativeDayMap.entries) {
      if (entry.key.hasMatch(lower)) {
        return today.add(Duration(days: entry.value));
      }
    }

    // "X ngày nữa"
    final ndMatch = _relativeNDaysPattern.firstMatch(lower);
    if (ndMatch != null) {
      return today.add(Duration(days: int.parse(ndMatch.group(1)!)));
    }

    // Weekdays
    for (final entry in _weekdayMap.entries) {
      if (lower.contains(entry.key)) {
        final target = entry.value;
        var diff = target - now.weekday;
        if (diff <= 0) diff += 7;
        return today.add(Duration(days: diff));
      }
    }

    // Slash dates: 12/25, 25/12
    final slashDate = RegExp(r'(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?').firstMatch(lower);
    if (slashDate != null) {
      final day = int.parse(slashDate.group(1)!);
      final month = int.parse(slashDate.group(2)!);
      final year = slashDate.group(3) != null ? int.parse(slashDate.group(3)!) : now.year;
      try { return DateTime(year < 100 ? 2000 + year : year, month, day); } catch (_) {}
    }

    return null;
  }

  // ===== TITLE CLEANING =====
  static String _cleanTitle(String text) {
    var result = text;
    // Remove time patterns
    for (final pattern in _timePatterns) {
      result = result.replaceAll(pattern, ' ');
    }
    // Remove date patterns
    result = result.replaceAll(RegExp(r'tomorrow|ngày\s*mai|mai\b|hôm\s*nay|today|hnay|next\s*week|tuần\s*sau', caseSensitive: false), ' ');
    result = result.replaceAll(_relativeNDaysPattern, ' ');
    for (final key in _weekdayMap.keys) {
      result = result.replaceAll(RegExp(RegExp.escape(key), caseSensitive: false), ' ');
    }
    result = result.replaceAll(RegExp(r'\d{1,2}/\d{1,2}(?:/\d{2,4})?', caseSensitive: false), ' ');
    // Remove event/deadline keywords
    result = result.replaceAll(_eventKeywords, ' ');
    result = result.replaceAll(_deadlineKeywords, ' ');
    result = result.replaceAll(_reminderKeywords, ' ');
    // Clean up
    result = result.replaceAll(RegExp(r'[,\-:]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result.isEmpty) result = 'Untitled Task';
    return result;
  }
}
