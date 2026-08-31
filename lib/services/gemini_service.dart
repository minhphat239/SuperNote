import 'dart:convert';
import 'package:http/http.dart' as http;

// ===== GEMINI SERVICE =====
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY';
  String _apiKey = _defaultApiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  bool get isConfigured => _apiKey != _defaultApiKey;

  void setApiKey(String key) => _apiKey = key;

  // ===== GENERATE CONTENT =====
  Future<String?> generate(String prompt, {String? systemInstruction}) async {
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
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      if (systemInstruction != null) {
        body['systemInstruction'] = {
          'parts': [{'text': systemInstruction}]
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
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
      }
      return null;
    } catch (e) {
      return _getMockResponse(prompt);
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
Bạn là trợ lý AI của SuperNote. Tóm tắt hoạt động hôm nay của người dùng:
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
