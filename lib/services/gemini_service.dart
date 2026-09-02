import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

// ===== PARSED TASK FROM GEMINI =====
class GeminiParsedTask {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final TaskCategory category;
  final int? preReminderOffset;
  final String? description;
  final List<String> tags;
  final String? rawMessage;
  final bool success;
  final String? errorMessage;

  const GeminiParsedTask({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.category = TaskCategory.personal,
    this.preReminderOffset,
    this.description,
    this.tags = const [],
    this.rawMessage,
    this.success = true,
    this.errorMessage,
  });

  bool get hasTime => dueDate != null && dueTime != null;

  DateTime? get targetTime {
    if (dueDate != null && dueTime != null) {
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day,
          dueTime!.hour, dueTime!.minute);
    }
    return dueDate;
  }
}

// ===== GEMINI SERVICE =====
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY';
  static const String _apiKeyPref = 'gemini_api_key';
  String _apiKey = _defaultApiKey;
  static const String _modelName = 'gemini-3.1-flash-lite';
  static String get _baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';

  bool get isConfigured => _apiKey != _defaultApiKey;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref) ?? _defaultApiKey;
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

  // ===== GENERATE CONTENT =====
  Future<String?> generate(String prompt, {String? systemInstruction, int retryCount = 0}) async {
    if (!isConfigured) return _getMockResponse(prompt);

    try {
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        },
      };

      if (systemInstruction != null) {
        body['systemInstruction'] = {
          'parts': [{'text': systemInstruction}]
        };
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          return parts[0]['text'] as String;
        }
        return 'Không nhận được phản hồi từ AI. Thử lại sau.';
      } else if (response.statusCode == 503 && retryCount < 2) {
        await Future.delayed(const Duration(seconds: 3));
        return generate(prompt, systemInstruction: systemInstruction, retryCount: retryCount + 1);
      } else {
        final body = response.body;
        if (response.statusCode == 400) {
          return 'Sai tham số request. Chi tiết: $body';
        } else if (response.statusCode == 403) {
          return 'API key bị từ chối. Kiểm tra key có đúng và chưa hết quota không?';
        } else if (response.statusCode == 404) {
          return 'Model không tồn tại ($_modelName). Vui lòng cập nhật model trong code.';
        } else if (response.statusCode == 429) {
          return 'Đã gửi quá nhiều yêu cầu. Chờ một chút rồi thử lại.';
        }
        return 'Lỗi API (${response.statusCode}): $body';
      }
    } catch (e) {
      return 'Lỗi kết nối: ${e.toString().contains('SocketException') ? 'Không có Internet' : e}';
    }
  }

  // ===== PROMPT TEMPLATES =====

  /// Tóm tắt ghi chú
  Future<String?> summarizeNote(String title, String content) async {
    return generate(
      'Tóm tắt ngắn gọn ghi chú sau (2-3 dòng):\n\nTiêu đề: $title\nNội dung: $content',
      systemInstruction: 'Bạn là trợ lý AI giúp tóm tắt ghi chú. Trả lời ngắn gọn bằng tiếng Việt.',
    );
  }

  /// Phân tích task và gợi ý thời gian
  Future<String?> analyzeTask(String taskTitle) async {
    return generate(
      'Phân tích task sau và gợi ý:\n1. Loại task (họp/sự kiện/deadline/bài tập)\n2. Thời gian ước tính\n3. Mức độ ưu tiên\n\nTask: $taskTitle',
      systemInstruction: 'Bạn là trợ lý AI phân tích công việc. Trả lời JSON format bằng tiếng Việt.',
    );
  }

  /// Tạo checklist từ task
  Future<String?> generateChecklist(String taskTitle) async {
    return generate(
      'Tạo checklist (danh sách công việc con) cho task sau. Trả về dạng JSON array:\n\nTask: $taskTitle',
      systemInstruction: 'Bạn là trợ lý AI tạo checklist. Trả về JSON array [{"title": "...", "done": false}] bằng tiếng Việt.',
    );
  }

  /// Gợi ý tag/category cho task
  Future<String?> suggestTags(String text) async {
    return generate(
      'Gợi ý 2-3 tag phù hợp cho văn bản sau (định dạng #tag):\n\n$text',
      systemInstruction: 'Bạn là trợ lý AI gợi ý tag. Chỉ trả về danh sách tag, mỗi tag trên 1 dòng, bắt đầu bằng #.',
    );
  }

  /// Viết lại nội dung ghi chú
  Future<String?> rewriteNote(String content, {String? style}) async {
    return generate(
      'Viết lại nội dung sau${style != null ? " theo phong cách $style" : ""}:\n\n$content',
      systemInstruction: 'Bạn là trợ lý AI viết nội dung. Viết lại bằng tiếng Việt, giữ nguyên ý nghĩa.',
    );
  }

  /// Trả lời câu hỏi về ghi chú
  Future<String?> askAboutNote(String question, String noteContent) async {
    return generate(
      'Dựa trên nội dung ghi chú sau, trả lời câu hỏi:\n\nGhi chú:\n$noteContent\n\nCâu hỏi: $question',
      systemInstruction: 'Bạn là trợ lý AI trả lời câu hỏi dựa trên dữ liệu được cung cấp. Trả lời bằng tiếng Việt.',
    );
  }

  /// Parse user input into 1+ structured tasks via Gemini AI.
  /// Returns empty list if parsing failed (caller should fall back to local parser).
  Future<List<GeminiParsedTask>> parseTaskInput(String userInput) async {
    if (!isConfigured) return const [];

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final weekdayStr = _vietnameseWeekday(now.weekday);
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final systemInstruction =
        'Bạn là trợ lý AI phân tích yêu cầu tạo task từ ngôn ngữ tự nhiên tiếng Việt.\n'
        'Hôm nay là $weekdayStr, $dateStr, giờ hiện tại là $timeStr.\n'
        'Người dùng có thể nhập MỘT hoặc NHIỀU công việc trong cùng một câu. Các công việc thường được phân tách bằng dấu phẩy, chấm phẩy, dấu chấm, hoặc từ nối như "và", "rồi", "sau đó", "còn".\n'
        'Mỗi công việc có thể kèm theo thời gian riêng (VD: "mai", "thứ 3 tuần sau", "2h chiều", "lúc 14:30", "tối nay"), địa điểm, người liên quan, mức độ khẩn cấp.\n\n'
        'NHIỆM VỤ: Phân tách câu thành CÁC task RIÊNG BIỆT. Với MỖI task, trích xuất CHÍNH XÁC các trường sau:\n'
        '1. "title" (string, BẮT BUỘC): Tên công việc, loại bỏ thời gian/địa điểm/người liên quan.\n'
        '2. "date" (string|null): Ngày diễn ra theo định dạng "YYYY-MM-DD". Mặc định hôm nay nếu không có thời gian.\n'
        '3. "time" (string|null): Giờ theo định dạng "HH:mm" (24h). null nếu không có giờ cụ thể.\n'
        '4. "category" (string, BẮT BUỘC): Một trong 4 giá trị:\n'
        '   - "class" nếu liên quan đến lớp học, môn học, buổi học, giảng viên, lecture\n'
        '   - "exam" nếu liên quan đến thi, kiểm tra, test, quiz, midterm, final\n'
        '   - "assignment" nếu liên quan đến bài tập, đồ án, nộp bài, deadline, báo cáo\n'
        '   - "personal" các trường hợp còn lại (cá nhân, họp, sự kiện, mua sắm, ...)\n'
        '5. "reminder_minutes" (int|null): Phút nhắc trước. Suy luận từ ngữ cảnh:\n'
        '   - "gấp", "khẩn cấp", "ngay", "gấp lắm" → 5-15 phút\n'
        '   - "họp", "sự kiện", "buổi", meeting, event → 30 phút\n'
        '   - "nộp bài", "deadline", "hạn chót", "submit" → 120 phút (2 tiếng)\n'
        '   - "nhắc trước X phút/giờ" → dùng đúng giá trị X (đổi giờ sang phút)\n'
        '   - Mặc định: null (không nhắc trước)\n'
        '6. "tags" (array<string>): 1-3 tag ngắn gọn liên quan, KHÔNG kèm dấu #.\n'
        '7. "description" (string|null): Mô tả ngắn nếu có chi tiết bổ sung.\n\n'
        'ĐỊNH DẠNG TRẢ VỀ: CHỈ trả về JSON hợp lệ duy nhất với cấu trúc {"tasks":[...]}. KHÔNG có markdown, KHÔNG giải thích thêm.\n\n'
        'Ví dụ input ĐƠN: "Họp với bên thiết kế sửa UI trang chủ lúc 2h chiều mai gấp"\n'
        'Ví dụ output: {"tasks":[{"title":"Họp với bên thiết kế sửa UI trang chủ","date":"$tomorrowStr","time":"14:00","category":"personal","reminder_minutes":15,"tags":["hop","UI"],"description":null}]}\n\n'
        'Ví dụ input NHIỀU task: "Họp team lúc 9h sáng mai, nộp báo cáo tuần trước 5h chiều thứ 6, mua quà sinh nhật mẹ tối nay"\n'
        'Ví dụ output: {"tasks":['
        '{"title":"Họp team","date":"$tomorrowStr","time":"09:00","category":"personal","reminder_minutes":30,"tags":["hop"],"description":null},'
        '{"title":"Nộp báo cáo tuần","date":"<ngày thứ 6 tuần này/sau>","time":"17:00","category":"assignment","reminder_minutes":120,"tags":["baocao"],"description":null},'
        '{"title":"Mua quà sinh nhật mẹ","date":"<ngày hiện tại>","time":"20:00","category":"personal","reminder_minutes":null,"tags":["sinhNhat","me"],"description":null}]}\n\n'
        'QUAN TRỌNG: Luôn dùng năm ${now.year}. Tách tất cả task có trong câu, kể cả khi chỉ có 1 task. Output LUÔN là {"tasks":[...]} chứ KHÔNG phải {"task":{...}}.';

    final prompt = 'Phân tích câu sau, tách thành các task và trả về JSON {"tasks":[...]}:\n"$userInput"';

    try {
      final response = await generate(
        prompt,
        systemInstruction: systemInstruction,
      );
      if (response == null || response.isEmpty) return const [];

      final jsonStr = _extractFirstJson(response);
      if (jsonStr == null) return const [];

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Support both {"tasks":[...]} (new) and {"task":{...}} (legacy single)
      List<dynamic> rawTasks;
      if (data['tasks'] is List) {
        rawTasks = data['tasks'] as List;
      } else if (data['task'] is Map) {
        rawTasks = [data['task'] as Map<String, dynamic>];
      } else {
        return const [];
      }

      final result = <GeminiParsedTask>[];
      for (final raw in rawTasks) {
        if (raw is! Map) continue;
        final parsed = _mapParsedTask(raw as Map<String, dynamic>);
        if (parsed != null) result.add(parsed);
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  GeminiParsedTask? _mapParsedTask(Map<String, dynamic> data) {
    final title = (data['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return null;

    DateTime? dueDate;
    final dateRaw = data['date'] as String?;
    if (dateRaw != null && dateRaw.isNotEmpty) {
      try {
        dueDate = DateTime.parse(dateRaw);
      } catch (_) {}
    }

    DateTime? dueTime;
    final timeRaw = data['time'] as String?;
    if (timeRaw != null && timeRaw.isNotEmpty) {
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeRaw);
      if (match != null) {
        final h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        if (h >= 0 && h < 24 && m >= 0 && m < 60) {
          dueTime = DateTime(2000, 1, 1, h, m);
        }
      }
    }

    TaskCategory category = TaskCategory.personal;
    final catRaw = (data['category'] as String?)?.toLowerCase();
    if (catRaw == 'class') {
      category = TaskCategory.class_;
    } else if (catRaw == 'exam') {
      category = TaskCategory.exam;
    } else if (catRaw == 'assignment') {
      category = TaskCategory.assignment;
    }

    int? reminderMinutes;
    final remRaw = data['reminder_minutes'];
    if (remRaw is int) {
      reminderMinutes = remRaw;
    } else if (remRaw is num) {
      reminderMinutes = remRaw.toInt();
    }

    final tags = (data['tags'] as List?)
            ?.map((t) => t.toString())
            .where((t) => t.isNotEmpty)
            .toList() ??
        const <String>[];

    return GeminiParsedTask(
      title: title,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      preReminderOffset: reminderMinutes,
      tags: tags,
      description: data['description'] as String?,
    );
  }

  static String _vietnameseWeekday(int weekday) {
    const names = [
      'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static String? _extractFirstJson(String text) {
    final trimmed = text.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final candidate = trimmed.substring(start, end + 1);
    try {
      jsonDecode(candidate);
      return candidate;
    } catch (_) {
      final match = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(trimmed);
      return match?.group(0);
    }
  }

  /// Mock response when API not configured
  String _getMockResponse(String prompt) {
    if (prompt.contains('tóm tắt') || prompt.contains('summarize')) {
      return '📝 Tóm tắt: Đây là một ghi chú quan trọng cần được theo dõi.';
    }
    if (prompt.contains('checklist') || prompt.contains('danh sách')) {
      return '[{"title":"Research & Prepare","done":false},{"title":"Draft Content","done":false},{"title":"Review & Finalize","done":false}]';
    }
    if (prompt.contains('tag') || prompt.contains('#')) {
      return '#work\n#important\n#todo';
    }
    if (prompt.contains('task') || prompt.contains('phân tích')) {
      return '{"type":"deadline","estimatedTime":"2 hours","priority":"high"}';
    }
    return '🤖 Gemini API chưa được cấu hình. Vui lòng thêm API key vào GeminiService.';
  }
}

// ===== PROMPT TEMPLATES COLLECTION =====
class PromptTemplates {
  // Daily summary
  static const String dailySummary = '''
Bạn là trợ lý AI của SuperNote(MinhPhat là người tạo ra bạn). Tóm tắt hoạt động hôm nay của người dùng:
- Số task đã hoàn thành
- Số task đang chờ
- Gợi ý cho ngày mai

Trả lời ngắn gọn bằng tiếng Việt, thân thiện.
''';

  // Smart reminder suggestion
  static const String reminderSuggestion = '''
Phân tích task và gợi ý thời gian nhắc nhở phù hợp:
- Nếu là sự kiện/họp: nhắc trước 30 phút
- Nếu là deadline/bài tập: nhắc trước 2 giờ
- Nếu là nhắc nhở chung: nhắc trước 15 phút

Trả về JSON: {"stage1_minutes": X, "stage2_minutes": Y, "reason": "..."}
''';

  // Task breakdown
  static const String taskBreakdown = '''
Chia nhỏ task thành các bước cụ thể:
1. Phân tích task
2. Liệt kê các bước cần thực hiện
3. Ước tính thời gian cho mỗi bước

Trả về JSON array [{"step": "...", "time_estimate": "...", "priority": "high/medium/low"}]
''';

  // Note enhancement
  static const String noteEnhancement = '''
Cải thiện nội dung ghi chú:
1. Tổ chức lại nội dung logic hơn
2. Bổ sung thông tin quan trọng
3. Format lại cho dễ đọc

Giữ nguyên ý nghĩa gốc, chỉ cải thiện cách trình bày.
''';

  // Weekly review
  static const String weeklyReview = '''
Tạo báo cáo tuần:
1. Tổng task đã hoàn thành
2. Task đang pending
3. Thống kê theo category
4. Gợi ý cải thiện

Trả lời bằng tiếng Việt, formato dễ đọc.
''';
}
