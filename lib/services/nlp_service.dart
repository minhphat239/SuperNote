import '../models/task.dart';

class NlpPreview {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final TaskCategory? category;
  final String? repeatRule;
  final DateTime? repeatEndDate;
  final int? preReminderOffset;
  final List<String> tags;

  NlpPreview({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.category,
    this.repeatRule,
    this.repeatEndDate,
    this.preReminderOffset,
    this.tags = const [],
  });

  bool get hasDate => dueDate != null;
  bool get hasTime => dueTime != null;
  bool get hasCategory => category != null;
  bool get hasRepeat => repeatRule != null;
  bool get hasPreReminder => preReminderOffset != null;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime?.toIso8601String(),
      'category': category?.name,
      'repeatRule': repeatRule,
      'repeatEndDate': repeatEndDate?.toIso8601String(),
      'preReminderOffset': preReminderOffset,
    };
  }
}

class NlpService {
  static NlpPreview parse(String input) {
    String title = input;
    DateTime? dueDate;
    DateTime? dueTime;
    TaskCategory? category;
    String? repeatRule;
    DateTime? repeatEndDate;
    int? preReminderOffset;
    final tags = <String>[];

    // Extract tags first
    final tagPattern = RegExp(r'#(\w+)');
    for (final m in tagPattern.allMatches(input)) {
      tags.add(m.group(1)!);
    }
    title = title.replaceAll(tagPattern, ' ');

    // Extract category first (before cleaning title)
    category = _extractCategory(input);
    if (category != null) {
      title = _removeCategoryText(title, category);
    }

    // Extract pre-reminder
    preReminderOffset = _extractPreReminder(input);
    if (preReminderOffset != null) {
      title = _removePreReminderText(title);
    }

    // Extract repeat end date
    repeatEndDate = _extractRepeatEndDate(input);
    if (repeatEndDate != null) {
      title = _removeRepeatEndDateText(title);
    }

    // Extract repeat rule
    repeatRule = _extractRepeatRule(input);
    if (repeatRule != null) {
      title = _removeRepeatText(title);
    }

    // Extract due date
    dueDate = _extractDueDate(input);
    if (dueDate != null) {
      title = _removeDueDateText(title);
    }

    // Extract due time
    dueTime = _extractDueTime(input);
    if (dueTime != null) {
      title = _removeDueTimeText(title);
    }

    // Clean up title
    title = _cleanTitle(title);

    return NlpPreview(
      title: title,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      repeatRule: repeatRule,
      repeatEndDate: repeatEndDate,
      preReminderOffset: preReminderOffset,
      tags: tags,
    );
  }

  // ========== Category Extraction ==========
  static TaskCategory? _extractCategory(String text) {
    final lower = text.toLowerCase();

    // #tag based category
    final tagCategoryMap = {
      '#class': TaskCategory.class_, '#lop': TaskCategory.class_, '#hoc': TaskCategory.class_,
      '#exam': TaskCategory.exam, '#thi': TaskCategory.exam, '#test': TaskCategory.exam,
      '#assignment': TaskCategory.assignment, '#homework': TaskCategory.assignment, '#baitap': TaskCategory.assignment, '#bt': TaskCategory.assignment,
      '#personal': TaskCategory.personal, '#canhan': TaskCategory.personal,
    };
    for (final entry in tagCategoryMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // Keywords for each category
    if (lower.contains('exam') || lower.contains('thi') || lower.contains('test') ||
        lower.contains('midterm') || lower.contains('final') || lower.contains('quiz') ||
        lower.contains('kiem tra') || lower.contains('bai thi')) {
      return TaskCategory.exam;
    }
    if (lower.contains('assignment') || lower.contains('homework') ||
        lower.contains('bai tap') || lower.contains('bài tập') ||
        lower.contains('submit') || lower.contains('nộp') ||
        lower.contains('deadline') || lower.contains('han nop') ||
        lower.contains('hạn nộp')) {
      return TaskCategory.assignment;
    }
    if (lower.contains('class') || lower.contains('lecture') ||
        lower.contains('lab') || lower.contains('hoc') || lower.contains('học') ||
        lower.contains('buoi') || lower.contains('buổi') ||
        lower.contains('mon') || lower.contains('môn')) {
      return TaskCategory.class_;
    }

    return null;
  }

  static String _removeCategoryText(String text, TaskCategory category) {
    final keywords = _getCategoryKeywords(category);
    var result = text;
    for (final kw in keywords) {
      result = result.replaceAll(RegExp(r',?\s*' + RegExp.escape(kw), caseSensitive: false), '');
    }
    // Also remove #tags
    result = result.replaceAll(RegExp(r'#\w+'), '');
    return result;
  }

  static List<String> _getCategoryKeywords(TaskCategory category) {
    switch (category) {
      case TaskCategory.exam:
        return ['exam', 'thi', 'test', 'midterm', 'final', 'quiz', 'kiem tra', 'bai thi', 'bài thi'];
      case TaskCategory.assignment:
        return ['assignment', 'homework', 'bai tap', 'bài tập', 'submit', 'nộp', 'deadline', 'han nop', 'hạn nộp'];
      case TaskCategory.class_:
        return ['class', 'lecture', 'lab', 'hoc', 'học', 'buoi', 'buổi', 'mon', 'môn'];
      case TaskCategory.personal:
        return [];
    }
  }

  // ========== Pre-reminder Extraction ==========
  static int? _extractPreReminder(String text) {
    final lower = text.toLowerCase();

    // "remind me X minutes/hours before", "notify X minutes before"
    final patterns = [
      RegExp(r'remind me (\d+)\s*(minutes?|mins?|phút) before'),
      RegExp(r'remind me (\d+)\s*(hours?|hrs?|giờ) before'),
      RegExp(r'notify (\d+)\s*(minutes?|mins?|phút) before'),
      RegExp(r'notify (\d+)\s*(hours?|hrs?|giờ) before'),
      RegExp(r'(\d+)\s*(minutes?|mins?|phút) before'),
      RegExp(r'(\d+)\s*(hours?|hrs?|giờ) before'),
      // Vietnamese
      RegExp(r'nhắc trước (\d+)\s*(phút|giờ)'),
      RegExp(r'trước (\d+)\s*(phút|giờ)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final value = int.parse(match.group(1)!);
        final unit = match.group(2)!.toLowerCase();
        if (unit.contains('hour') || unit.contains('hr') || unit.contains('giờ')) {
          return value * 60; // convert to minutes
        }
        return value; // minutes
      }
    }

    // Default pre-reminders
    if (lower.contains('remind me') || lower.contains('notify') || lower.contains('nhắc')) {
      if (lower.contains('30') || lower.contains('half')) return 30;
      if (lower.contains('1 hour') || lower.contains('1hr') || lower.contains('1 giờ') || lower.contains('mot gio')) return 60;
      if (lower.contains('1 day') || lower.contains('1 ngày') || lower.contains('mot ngay')) return 1440;
      return 60; // default 1 hour
    }

    return null;
  }

  static String _removePreReminderText(String text) {
    return text
        .replaceAll(RegExp(r',?\s*remind me.*before.*', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*notify.*before.*', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d+\s*(minutes?|mins?|hours?|hrs?|phút|giờ)\s*before', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*nhắc trước.*', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*trước\s*\d+\s*(phút|giờ)', caseSensitive: false), '');
  }

  // ========== Repeat End Date ==========
  static DateTime? _extractRepeatEndDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    // "until end of semester", "until december", "until 2024-12-31"
    final untilPatterns = [
      RegExp(r'until\s+(end of\s+)?(semester|term|june|july|august|september|october|november|december|january|february|march|april|may)'),
      RegExp(r'den\s+(cuoi|cuối)\s+(ky|kì|hoc ky|học kỳ)'),
      RegExp(r'den\s+(\d{1,2})/(\d{1,2})(?:/(\d{4}))?'),
      RegExp(r'until\s+(\d{4}-\d{2}-\d{2})'),
    ];

    for (final pattern in untilPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        if (pattern.pattern.contains('semester') || pattern.pattern.contains('kì') || pattern.pattern.contains('ky')) {
          // End of semester - roughly June or December
          final month = now.month >= 6 ? 12 : 6;
          return DateTime(now.year, month, 30);
        }
        if (match.groupCount >= 2 && match.group(1) != null && match.group(2) != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = match.group(3) != null ? int.parse(match.group(3)!) : now.year;
          return DateTime(year, month, day);
        }
        if (match.group(1) != null) {
          // ISO date
          return DateTime.parse(match.group(1)!);
        }
      }
    }

    return null;
  }

  static String _removeRepeatEndDateText(String text) {
    return text
        .replaceAll(RegExp(r',?\s*until.*', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*den\s+.*', caseSensitive: false), '');
  }

  // ========== Repeat Rule ==========
  static String? _extractRepeatRule(String text) {
    final lower = text.toLowerCase();

    // Daily
    if (lower.contains('every day') || lower.contains('daily') ||
        lower.contains('hàng ngày') || lower.contains('mỗi ngày') ||
        lower.contains('moi ngay') || lower.contains('mọi ngày')) {
      return 'daily';
    }

    // Weekdays - "every Monday", "every Mon/Wed/Fri", "monday wednesday friday"
    final weekdayPattern = RegExp(r'(every|mỗi|moi)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun|thứ\s*[2-7]|chu nhat|chủ nhật)(\s*[,&]\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun|thứ\s*[2-7]|chu nhat|chủ nhật))*');
    final weekdayMatch = weekdayPattern.firstMatch(lower);
    if (weekdayMatch != null) {
      final days = _parseWeekdays(weekdayMatch.group(0)!);
      if (days.isNotEmpty) {
        return 'weekly:${days.join(',')}';
      }
    }

    // "every week", "weekly"
    if (lower.contains('every week') || lower.contains('weekly') ||
        lower.contains('hàng tuần') || lower.contains('mỗi tuần')) {
      return 'weekly';
    }

    // Monthly
    if (lower.contains('every month') || lower.contains('monthly') ||
        lower.contains('hàng tháng') || lower.contains('mỗi tháng')) {
      return 'monthly';
    }

    // Custom: "every 2 weeks", "biweekly", "2 tuần một lần"
    final customWeek = RegExp(r'(every|mỗi)\s+(\d+)\s*(weeks?|tuần)');
    final matchCustomWeek = customWeek.firstMatch(lower);
    if (matchCustomWeek != null) {
      final weeks = int.parse(matchCustomWeek.group(2)!);
      return 'every_${weeks}_weeks';
    }

    // "cứ 2 ngày một lần"
    final customDay = RegExp(r'cứ\s+(\d+)\s*ngày\s*một\s*lần');
    final matchCustomDay = customDay.firstMatch(lower);
    if (matchCustomDay != null) {
      return 'every_${matchCustomDay.group(1)}_days';
    }

    return null;
  }

  static List<int> _parseWeekdays(String text) {
    final lower = text.toLowerCase();
    final days = <int>[];
    final dayMap = {
      'monday': 1, 'mon': 1, 'thứ 2': 1, 'thu 2': 1,
      'tuesday': 2, 'tue': 2, 'thứ 3': 2, 'thu 3': 2,
      'wednesday': 3, 'wed': 3, 'thứ 4': 3, 'thu 4': 3,
      'thursday': 4, 'thu': 4, 'thứ 5': 4, 'thu 5': 4,
      'friday': 5, 'fri': 5, 'thứ 6': 5, 'thu 6': 5,
      'saturday': 6, 'sat': 6, 'thứ 7': 6, 'thu 7': 6,
      'sunday': 7, 'sun': 7, 'chu nhat': 7, 'chủ nhật': 7, 'chủ nhat': 7,
    };

    final sortedEntries = dayMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in sortedEntries) {
      if (lower.contains(entry.key)) {
        if (!days.contains(entry.value)) days.add(entry.value);
      }
    }
    return days..sort();
  }

  static String _removeRepeatText(String text) {
    return text
        .replaceAll(RegExp(r',?\s*(every day|daily|hàng ngày|mỗi ngày|moi ngay|mọi ngày)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(every week|weekly|hàng tuần|mỗi tuần)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(every month|monthly|hàng tháng|mỗi tháng)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(every|mỗi)\s+\d+\s*(weeks?|tuần)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*cứ\s+\d+\s*ngày\s*một\s*lần', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(every|mỗi)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun|thứ\s*[2-7]|chu nhat|chủ nhật)(\s*[,&]\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun|thứ\s*[2-7]|chu nhat|chủ nhật))*', caseSensitive: false), '');
  }

  // ========== Due Date ==========
  static DateTime? _extractDueDate(String text) {
    final now = DateTime.now();
    final lower = text.toLowerCase();

    // Relative dates
    if (lower.contains('tomorrow') || lower.contains('ngày mai') || RegExp(r'\bmai\b').hasMatch(lower)) {
      return DateTime(now.year, now.month, now.day + 1);
    }
    if (lower.contains('today') || lower.contains('hôm nay')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (lower.contains('next week') || lower.contains('tuần sau') || lower.contains('tuan sau')) {
      // Calculate next Monday from now
      final daysUntilMonday = (8 - now.weekday) % 7;
      final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
      return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
    }

    // "next Monday", "this Friday", "Monday", "Friday"
    final nextWeekdayPattern = RegExp(r'(next|this)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun|thứ\s*[2-7]|chu nhat|chủ nhật)');
    final nextMatch = nextWeekdayPattern.firstMatch(lower);
    if (nextMatch != null) {
      final day = _parseWeekday(nextMatch.group(2)!);
      if (day != null) {
        final isNext = nextMatch.group(1) == 'next' ||
            (nextMatch.group(1) == null && _isPastWeekday(now, day));
        return _getNextWeekday(now, day, isNext);
      }
    }

    // "in X days"
    final inDays = RegExp(r'in\s+(\d+)\s*days?');
    final inDaysMatch = inDays.firstMatch(lower);
    if (inDaysMatch != null) {
      return now.add(Duration(days: int.parse(inDaysMatch.group(1)!)));
    }

    // Vietnamese relative
    final vnDays = RegExp(r'(\d+)\s*ngày\s*(nữa|sau)');
    final vnDaysMatch = vnDays.firstMatch(lower);
    if (vnDaysMatch != null) {
      return now.add(Duration(days: int.parse(vnDaysMatch.group(1)!)));
    }

    final vnWeeks = RegExp(r'(\d+)\s*tuần\s*(sau|nữa)');
    final vnWeeksMatch = vnWeeks.firstMatch(lower);
    if (vnWeeksMatch != null) {
      return now.add(Duration(days: int.parse(vnWeeksMatch.group(1)!) * 7));
    }

    // Specific date: "12/25", "25/12", "2024-12-25", "December 25"
    final datePatterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})(?:/(\d{4}))?'),
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        try {
          if (pattern.pattern.contains('-')) {
            return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
          } else if (pattern.pattern.contains('january')) {
            final month = _monthNameToNumber(match.group(1)!);
            final day = int.parse(match.group(2)!);
            return DateTime(now.year, month, day);
          } else {
            final g1 = int.parse(match.group(1)!);
            final g2 = int.parse(match.group(2)!);
            final year = match.group(3) != null ? int.parse(match.group(3)!) : now.year;
            int day, month;
            if (g1 > 12 && g2 <= 12) {
              day = g1; month = g2; // dd/MM
            } else if (g2 > 12 && g1 <= 12) {
              day = g2; month = g1; // MM/dd
            } else {
              day = g1; month = g2; // default dd/MM
            }
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  static int? _parseWeekday(String text) {
    final lower = text.toLowerCase().trim();
    final dayMap = {
      'monday': 1, 'mon': 1, 'thứ 2': 1, 'thu 2': 1,
      'tuesday': 2, 'tue': 2, 'thứ 3': 2, 'thu 3': 2,
      'wednesday': 3, 'wed': 3, 'thứ 4': 3, 'thu 4': 3,
      'thursday': 4, 'thu': 4, 'thứ 5': 4, 'thu 5': 4,
      'friday': 5, 'fri': 5, 'thứ 6': 5, 'thu 6': 5,
      'saturday': 6, 'sat': 6, 'thứ 7': 6, 'thu 7': 6,
      'sunday': 7, 'sun': 7, 'chu nhat': 7, 'chủ nhật': 7, 'chủ nhat': 7,
    };
    // Sort by length descending so 'thu 2' matches before 'thu'
    final sortedEntries = dayMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in sortedEntries) {
      if (lower == entry.key) return entry.value;
    }
    return null;
  }

  static bool _isPastWeekday(DateTime now, int targetWeekday) {
    final currentWeekday = now.weekday; // 1=Mon, 7=Sun
    return targetWeekday < currentWeekday;
  }

  static DateTime _getNextWeekday(DateTime now, int targetWeekday, bool isNext) {
    final currentWeekday = now.weekday;
    var daysToAdd = targetWeekday - currentWeekday;
    if (daysToAdd <= 0 || isNext) {
      daysToAdd += 7;
    }
    return now.add(Duration(days: daysToAdd));
  }

  static int _monthNameToNumber(String month) {
    final months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  static String _removeDueDateText(String text) {
    return text
        .replaceAll(RegExp(r',?\s*(tomorrow|today|next week)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(ngày mai|\bmai\b|hôm nay|tuần sau|tuan sau)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*in\s+\d+\s*days?', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d+\s*ngày\s*(nữa|sau)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d+\s*tuần\s*(sau|nữa)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(next|this)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun|thứ\s*[2-7]|chu nhat|chủ nhật)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d{1,2}/\d{1,2}(?:/\d{4})?', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d{4}-\d{2}-\d{2}', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}', caseSensitive: false), '');
  }

  // ========== Due Time ==========
  static DateTime? _extractDueTime(String text) {
    final lower = text.toLowerCase();

    // "6 PM", "18:00", "6pm", "6 p.m."
    final timePatterns = [
      RegExp(r'(\d{1,2})\s*(AM|PM|am|pm|a\.m\.|p\.m\.)'),
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?'),
      RegExp(r'(\d{1,2}):(\d{2})'),
      RegExp(r'lúc\s+(\d{1,2})[:\s]*(\d{2})?'),
      RegExp(r'(\d{1,2})h(\d{2})?'),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = 0;

        if (match.groupCount >= 2 && match.group(2) != null) {
          // Could be minutes or AM/PM
          final group2 = match.group(2)!;
          if (group2.toLowerCase().contains('am') || group2.toLowerCase().contains('pm')) {
            final ampm = group2.toLowerCase();
            if (ampm.contains('pm') && hour < 12) hour += 12;
            if (ampm.contains('am') && hour == 12) hour = 0;
          } else if (pattern.pattern.contains(':')) {
            minute = int.parse(group2);
          }
        }

        if (match.groupCount >= 3 && match.group(3) != null) {
          minute = int.parse(match.group(3)!);
        }

        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(2000, 1, 1, hour, minute); // Use dummy date, only time matters
        }
      }
    }

    return null;
  }

  static String _removeDueTimeText(String text) {
    return text
        .replaceAll(RegExp(r',?\s*at\s+\d{1,2}\s*(AM|PM|am|pm)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d{1,2}:\d{2}\s*(AM|PM|am|pm)?', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d{1,2}\s*(AM|PM|am|pm|a\.m\.|p\.m\.)', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*lúc\s+\d{1,2}[:\s]*\d{2}?', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*\d{1,2}h\d{2}?', caseSensitive: false), '');
  }

  // ========== Clean Title ==========
  static String _cleanTitle(String title) {
    title = title.trim();
    title = title.replaceAll(RegExp(r'\s+'), ' ');
    title = title.replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
    if (title.isEmpty) title = 'Untitled Task';
    return title;
  }
}