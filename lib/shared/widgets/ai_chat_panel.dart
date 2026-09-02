import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../services/gemini_service.dart';
import '../../services/task_service.dart';
import 'glass_widgets.dart';

// ===== CHAT MESSAGE MODEL =====
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isChecklist;
  final List<ChecklistItem>? checklistItems;
  final List<TaskSuggestion>? taskSuggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isChecklist = false,
    this.checklistItems,
    this.taskSuggestions,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasTaskSuggestions =>
      taskSuggestions != null && taskSuggestions!.isNotEmpty;
}

class ChecklistItem {
  final String title;
  bool done;

  ChecklistItem({required this.title, this.done = false});
}

class TaskSuggestion {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final TaskCategory category;
  final int? preReminderOffset;

  TaskSuggestion({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.category = TaskCategory.personal,
    this.preReminderOffset,
  });
}

// ===== AI CHAT PANEL =====
class AiChatPanel extends StatefulWidget {
  final GeminiService geminiService;
  final TaskService taskService;

  const AiChatPanel({super.key, required this.geminiService, required this.taskService});

  static void show(BuildContext context, GeminiService geminiService, TaskService taskService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiChatPanel(geminiService: geminiService, taskService: taskService),
    );
  }

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _addedSuggestionKeys = {};
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: 'Xin chào! Mình là AI trợ lý của SuperNote.\n'
          'Bạn có thể hỏi mình về task, lịch trình, hoặc nhờ mình phân tích công việc.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Determine intent and build prompt
    final prompt = _buildPrompt(text);
    final systemInstruction = _buildSystemInstruction();

    try {
      final response = await widget.geminiService.generate(
        prompt,
        systemInstruction: systemInstruction,
      );

      if (!mounted) return;

      final reply = response ?? 'Xin lỗi, mình không thể xử lý yêu cầu này.';
      final parsed = _parseResponse(reply);

      setState(() {
        _messages.add(parsed);
        _isLoading = false;
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Đã xảy ra lỗi: ${e.toString()}',
          isUser: false,
        ));
        _isLoading = false;
        _isTyping = false;
      });
    }
  }

  String _buildPrompt(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('tóm tắt') || lower.contains('summarize')) {
      return 'Tóm tắt ngắn gọn yêu cầu sau:\n$input';
    }
    if (lower.contains('checklist') ||
        lower.contains('chia nhỏ') ||
        lower.contains('bước')) {
      return 'Tạo checklist cho task sau. Trả về JSON array [{"title": "..."}]:\n$input';
    }
    if (lower.contains('phân tích') || lower.contains('analyze')) {
      return 'Phân tích task sau và gợi ý thời gian, ưu tiên:\n$input';
    }
    if (lower.contains('tag') || lower.contains('category') || lower.contains('phân loại')) {
      return 'Gợi ý tag phù hợp cho:\n$input';
    }
    if (lower.contains('lịch') ||
        lower.contains('schedule') ||
        lower.contains('kế hoạch')) {
      return 'Giúp tôi lên lịch cho:\n$input';
    }
    if (lower.contains('hôm nay') || lower.contains('today')) {
      return 'Tóm tắt hoạt động hôm nay và gợi ý cho ngày mai.';
    }
    return input;
  }

  String _buildSystemInstruction() {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return 'Bạn là trợ lý AI thông minh của SuperNote, '
        'một ứng dụng quản lý task cho sinh viên Việt Nam. '
        'Hôm nay là $dateStr, giờ hiện tại là $timeStr. '
        'Trả lời ngắn gọn, thân thiện bằng tiếng Việt. '
        'Người dùng có thể yêu cầu tạo MỘT hoặc NHIỀU task trong một câu. '
        'Nếu người dùng yêu cầu tạo task hoặc lên lịch, '
        'bạn PHẢI trả về đúng 2 phần, phân tách bằng dòng "---":\n'
        'Phần 1: JSON task với format {"tasks":[{...},{...}]}: mỗi phần tử có '
        '{"title":"...","date":"YYYY-MM-DD","time":"HH:mm","category":"class|exam|assignment|personal","reminder_minutes":0}\n'
        'Phần 2: Tin nhắn giải thích bằng tiếng Việt.\n\n'
        'Ví dụ 1 task:\n'
        '{"tasks":[{"title":"Đá bóng","date":"2026-09-11","time":"18:00","category":"personal","reminder_minutes":60}]}\n'
        '---\n'
        'Mình đã lên lịch trận đấu bóng vào thứ 6 ngày 11/09/2026 lúc 18:00. Nhắc trước 1 giờ.\n\n'
        'Ví dụ nhiều task:\n'
        '{"tasks":['
        '{"title":"Họp team","date":"2026-09-03","time":"09:00","category":"personal","reminder_minutes":30},'
        '{"title":"Nộp báo cáo","date":"2026-09-05","time":"17:00","category":"assignment","reminder_minutes":120},'
        '{"title":"Mua quà mẹ","date":"2026-09-02","time":"20:00","category":"personal","reminder_minutes":null}'
        ']}\n'
        '---\n'
        'Mình đã lên lịch 3 việc cho bạn: họp team sáng mai 9h, nộp báo cáo thứ 6 lúc 17h, và mua quà cho mẹ tối nay.\n\n'
        'KHÔNG BAO GIỜ dùng năm 2024 hoặc 2025. Luôn dùng năm ${now.year}. '
        'Nếu KHÔNG phải yêu cầu tạo task, chỉ trả lời bằng tiếng Việt bình thường, KHÔNG có JSON. '
        'Output LUÔN là {"tasks":[...]} chứ KHÔNG phải {"task":{...}}.';
  }

  ChatMessage _parseResponse(String response) {
    final trimmed = response.trim();

    // Try parse task JSON + message format (separated by ---)
    if (trimmed.contains('---')) {
      final parts = trimmed.split('---');
      if (parts.length >= 2) {
        final jsonPart = parts[0].trim();
        final messagePart = parts.sublist(1).join('---').trim();

        try {
          final data = jsonDecode(jsonPart) as Map<String, dynamic>;
          // Support both new {"tasks":[...]} and legacy {"task":{...}}
          List<dynamic> rawTasks;
          if (data['tasks'] is List) {
            rawTasks = data['tasks'] as List;
          } else if (data['task'] is Map) {
            rawTasks = [data['task'] as Map<String, dynamic>];
          } else {
            rawTasks = [];
          }

          if (rawTasks.isNotEmpty) {
            final suggestions = <TaskSuggestion>[];
            for (final raw in rawTasks) {
              if (raw is! Map) continue;
              final task = raw;
              final title = (task['title'] as String?)?.trim() ?? '';
              if (title.isEmpty) continue;

              DateTime? dueDate;
              if (task['date'] != null) {
                dueDate = DateTime.tryParse(task['date'] as String);
              }

              DateTime? dueTime;
              if (task['time'] != null && dueDate != null) {
                final timeParts = (task['time'] as String).split(':');
                if (timeParts.length == 2) {
                  dueTime = DateTime(
                    dueDate.year, dueDate.month, dueDate.day,
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                }
              }

              TaskCategory category = TaskCategory.personal;
              if (task['category'] != null) {
                final catStr = (task['category'] as String).toLowerCase();
                if (catStr == 'class') {
                  category = TaskCategory.class_;
                } else if (catStr == 'exam') {
                  category = TaskCategory.exam;
                } else if (catStr == 'assignment') {
                  category = TaskCategory.assignment;
                }
              }

              int? reminderMinutes;
              if (task['reminder_minutes'] != null) {
                reminderMinutes = task['reminder_minutes'] as int;
              }

              suggestions.add(TaskSuggestion(
                title: title,
                dueDate: dueDate,
                dueTime: dueTime,
                category: category,
                preReminderOffset: reminderMinutes,
              ));
            }

            if (suggestions.isNotEmpty) {
              final defaultText = suggestions.length == 1
                  ? 'Đã tạo task: ${suggestions.first.title}'
                  : 'Mình đã lên lịch ${suggestions.length} việc cho bạn.';
              return ChatMessage(
                text: messagePart.isNotEmpty ? messagePart : defaultText,
                isUser: false,
                taskSuggestions: suggestions,
              );
            }
          }
        } catch (_) {}
      }
    }

    // Try parse as checklist JSON
    try {
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final List<dynamic> items = jsonDecode(trimmed);
        if (items.isNotEmpty && items[0] is Map && items[0].containsKey('title')) {
          return ChatMessage(
            text: response,
            isUser: false,
            isChecklist: true,
            checklistItems: items
                .map((e) => ChecklistItem(title: e['title'] as String))
                .toList(),
          );
        }
      }
    } catch (_) {}

    return ChatMessage(text: response, isUser: false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // ===== DRAG HANDLE =====
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ===== HEADER =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppGradient.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.onAccent,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Powered by Gemini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== DIVIDER =====
          Divider(height: 1, color: AppColors.border),

          // ===== MESSAGES =====
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[i]);
                    },
                  ),
          ),

          // ===== INPUT BAR =====
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Hỏi AI bất cứ điều gì!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Task, lịch trình, phân tích công việc...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    if (msg.isUser) return _buildUserMessage(msg);
    if (msg.hasTaskSuggestions) return _buildTaskSuggestionMessage(msg);
    if (msg.isChecklist) return _buildChecklistMessage(msg);
    return _buildAiMessage(msg);
  }

  void _addSingleTaskFromSuggestion(ChatMessage msg, int index) async {
    final suggestion = msg.taskSuggestions![index];
    await widget.taskService.addTask(
      title: suggestion.title,
      dueDate: suggestion.dueDate,
      dueTime: suggestion.dueTime,
      category: suggestion.category,
      preReminderOffset: suggestion.preReminderOffset,
    );
    if (!mounted) return;
    setState(() {
      _addedSuggestionKeys.add('${msg.timestamp.millisecondsSinceEpoch}_$index');
    });
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.onAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Đã thêm "${suggestion.title}" vào lịch')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  void _addAllTasksFromSuggestions(ChatMessage msg) async {
    final suggestions = msg.taskSuggestions!;
    for (final suggestion in suggestions) {
      await widget.taskService.addTask(
        title: suggestion.title,
        dueDate: suggestion.dueDate,
        dueTime: suggestion.dueTime,
        category: suggestion.category,
        preReminderOffset: suggestion.preReminderOffset,
      );
    }
    if (!mounted) return;
    setState(() {
      final ts = msg.timestamp.millisecondsSinceEpoch;
      for (int i = 0; i < suggestions.length; i++) {
        _addedSuggestionKeys.add('${ts}_$i');
      }
      _messages.add(ChatMessage(
        text: 'Đã thêm tất cả ${suggestions.length} task vào lịch!',
        isUser: false,
      ));
    });
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.onAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Đã thêm ${suggestions.length} task vào lịch')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  Widget _buildTaskSuggestionMessage(ChatMessage msg) {
    final suggestions = msg.taskSuggestions!;
    final ts = msg.timestamp.millisecondsSinceEpoch;

    return SlideIn(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ]),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primaryLight.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg),
                    ),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Text(
                        msg.text,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Multi-task summary header
                      if (suggestions.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.task_alt_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                'Đã tách thành ${suggestions.length} task:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Per-task cards with individual "Thêm vào lịch" buttons
                      for (int i = 0; i < suggestions.length; i++) ...[
                        _buildSuggestionCard(
                          msg: msg,
                          suggestion: suggestions[i],
                          index: i,
                          total: suggestions.length,
                          ts: ts,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Footer: "Add all" + timestamp
                      Row(
                        children: [
                          if (suggestions.length > 1)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _addAllTasksFromSuggestions(msg),
                                icon: const Icon(Icons.add_task_rounded, size: 14),
                                label: Text(
                                  'Thêm tất cả ${suggestions.length} task',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(msg.timestamp),
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required ChatMessage msg,
    required TaskSuggestion suggestion,
    required int index,
    required int total,
    required int ts,
  }) {
    final addedKey = '${ts}_$index';
    final isAdded = _addedSuggestionKeys.contains(addedKey);

    final dateStr = suggestion.dueDate != null
        ? DateFormat('EEEE, dd/MM/yyyy', 'vi').format(suggestion.dueDate!)
        : 'Chưa rõ ngày';
    final timeStr = suggestion.dueTime != null
        ? DateFormat('HH:mm').format(suggestion.dueTime!)
        : '';
    final catLabel = {
      TaskCategory.class_: 'Lớp học',
      TaskCategory.exam: 'Kỳ thi',
      TaskCategory.assignment: 'Bài tập',
      TaskCategory.personal: 'Cá nhân',
    }[suggestion.category] ?? 'Cá nhân';

    return Padding(
      padding: EdgeInsets.only(bottom: index < total - 1 ? 10 : 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isAdded
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.border,
            width: isAdded ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: index badge + title + added checkmark
            Row(
              children: [
                if (total > 1) ...[
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: suggestion.category.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: suggestion.category.color.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: suggestion.category.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.task_alt_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isAdded)
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 6),
            // Date + time
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.7))),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(timeStr, style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.7))),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Category + reminder
            Row(
              children: [
                Icon(Icons.label_rounded, size: 11, color: suggestion.category.color.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(catLabel, style: TextStyle(fontSize: 11, color: suggestion.category.color.withValues(alpha: 0.8))),
                if (suggestion.preReminderOffset != null && suggestion.preReminderOffset! > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.notifications_active_rounded, size: 11, color: AppColors.orange.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('Nhắc trước ${suggestion.preReminderOffset} phút',
                      style: TextStyle(fontSize: 11, color: AppColors.orange.withValues(alpha: 0.8))),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // "Thêm lịch" button (per-task)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isAdded ? null : () => _addSingleTaskFromSuggestion(msg, index),
                icon: Icon(
                  isAdded ? Icons.check_rounded : Icons.add_task_rounded,
                  size: 14,
                ),
                label: Text(
                  isAdded ? 'Đã thêm' : 'Thêm lịch',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isAdded ? AppColors.success : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage msg) {
    return SlideIn(
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppGradient.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.onAccent,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiMessage(ChatMessage msg) {
    return SlideIn(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI avatar
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ),
              // Message bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg),
                    ),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        msg.text,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            DateFormat('HH:mm').format(msg.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: msg.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã copy'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: AppColors.textMuted.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistMessage(ChatMessage msg) {
    return SlideIn(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI avatar
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ),
              // Checklist card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg),
                    ),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 14,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Checklist (${msg.checklistItems?.length ?? 0} items)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...?msg.checklistItems?.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                item.done
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: item.done
                                    ? AppColors.success
                                    : AppColors.textMuted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: item.done
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary,
                                    decoration: item.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: AppColors.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600 + (i * 200)),
                      builder: (_, value, __) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3 + (value * 0.5)),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return GlassContainer(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                ),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Hỏi AI về task, lịch...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? null
                      : AppGradient.primary,
                  color: _isLoading ? AppColors.textMuted.withValues(alpha: 0.3) : null,
                  shape: BoxShape.circle,
                  boxShadow: _isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 14,
                        color: AppColors.onAccent,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
