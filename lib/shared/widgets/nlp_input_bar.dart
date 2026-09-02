import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/nlp_dual_stage.dart';
import '../../models/task.dart';
import '../../services/feedback_service.dart';
import '../../services/gemini_service.dart';
import 'glass_widgets.dart';
import 'task_confirmation_dialog.dart';

class NlpInputBar extends StatefulWidget {
  final Function(List<DualStageResult>) onSubmit;
  final GeminiService? geminiService;
  final String hintText;

  const NlpInputBar({
    super.key,
    required this.onSubmit,
    this.geminiService,
    this.hintText = 'Thêm nhanh task...',
  });

  @override
  State<NlpInputBar> createState() => _NlpInputBarState();
}

class _NlpInputBarState extends State<NlpInputBar> with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DualStageResult? _preview;
  bool _aiEnabled = true;
  bool _isProcessing = false;

  // Sparkle animation
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnim;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _sparkleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      if (_aiEnabled && value.trim().isNotEmpty) {
        _preview = NlpDualStageParser.parse(value);
      } else {
        _preview = null;
      }
    });
  }

  void _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    final input = _ctrl.text.trim();

    List<DualStageResult> results = [];

    // Decide: Gemini (configured + online) vs Local NLP
    final gemini = widget.geminiService;
    final canUseGemini =
        _aiEnabled && gemini != null && gemini.isConfigured;

    if (canUseGemini) {
      final hasInternet = await _checkInternet();
      if (hasInternet) {
        setState(() => _isProcessing = true);
        if (!mounted) return;
        try {
          final parsedList = await gemini.parseTaskInput(input).timeout(
                const Duration(seconds: 10),
                onTimeout: () => <GeminiParsedTask>[],
              );
          if (!mounted) return;
          setState(() => _isProcessing = false);
          if (parsedList.isNotEmpty) {
            results = parsedList.map(_convertGeminiToDual).toList();
          } else {
            results = _splitAndParseLocal(input);
          }
        } catch (_) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          results = _splitAndParseLocal(input);
        }
      } else {
        results = _splitAndParseLocal(input);
      }
    } else {
      results = _splitAndParseLocal(input);
    }

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => TaskConfirmationDialog(
        parsedList: results,
        rawInput: input,
      ),
    );

    if (confirmed == true && mounted) {
      FeedbackService().trigger(FeedbackType.complete);
      widget.onSubmit(results);
      _ctrl.clear();
      setState(() => _preview = null);
      _focusNode.unfocus();
    }
  }

  /// Split input by commas/semicolons/conjunctions and parse each chunk locally.
  /// If only 1 chunk (no clear separators), parse the whole input as one task.
  List<DualStageResult> _splitAndParseLocal(String input) {
    final chunks = _splitMultiTaskInput(input);
    return chunks.map(NlpDualStageParser.parse).toList();
  }

  List<String> _splitMultiTaskInput(String input) {
    // First try splitting on common Vietnamese/English separators between tasks.
    // Use a heuristic: split on ";" or numbered list, or " và ", " rồi ", " sau đó ", " còn ", " then ", " and ".
    // BUT only split if the chunk still looks like a task (has content after trim).
    final primarySplits = input.split(RegExp(r'\s*(?:\.\s|;\s|,\s*(?=\S+\s+(?:lúc|vào|lúc|nhắc|gấp|sau|mai|nay|tối|sáng|chiều))|(?:\s+và\s+|\s+rồi\s+|\s+sau\s*đó\s+|\s+còn\s+|\s+then\s+|\s+and\s+))'));
    if (primarySplits.length <= 1) return [input];

    final cleaned = primarySplits
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (cleaned.length <= 1) return [input];

    return cleaned;
  }

  Future<bool> _checkInternet() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  DualStageResult _convertGeminiToDual(GeminiParsedTask parsed) {
    // Build targetTime from parsed date + time
    DateTime? targetTime;
    if (parsed.dueDate != null && parsed.dueTime != null) {
      targetTime = DateTime(
        parsed.dueDate!.year, parsed.dueDate!.month, parsed.dueDate!.day,
        parsed.dueTime!.hour, parsed.dueTime!.minute,
      );
    } else if (parsed.dueDate != null) {
      targetTime = DateTime(
        parsed.dueDate!.year, parsed.dueDate!.month, parsed.dueDate!.day,
        9, 0, // default 9:00 AM if only date provided
      );
    } else if (parsed.dueTime != null) {
      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day,
          parsed.dueTime!.hour, parsed.dueTime!.minute);
      targetTime = todayTime.isAfter(now)
          ? todayTime
          : todayTime.add(const Duration(days: 1));
    }

    // Determine intent from category
    TaskIntent intent;
    switch (parsed.category) {
      case TaskCategory.class_:
      case TaskCategory.personal:
        intent = TaskIntent.event;
        break;
      case TaskCategory.exam:
      case TaskCategory.assignment:
        intent = TaskIntent.deadline;
        break;
    }

    // Calculate dual-stage reminders
    DateTime? stage1Time;
    String stage1Label = '';
    DateTime? stage2Time;
    String stage2Label = '';

    if (targetTime != null) {
      stage2Time = targetTime;
      final remMin = parsed.preReminderOffset;
      if (remMin != null && remMin > 0) {
        stage1Time = targetTime.subtract(Duration(minutes: remMin));
        if (remMin >= 60) {
          final h = remMin ~/ 60;
          stage1Label = 'Nhắc trước $h giờ';
        } else {
          stage1Label = 'Nhắc trước $remMin phút';
        }
      } else {
        switch (intent) {
          case TaskIntent.event:
            stage1Time = targetTime.subtract(const Duration(minutes: 30));
            stage1Label = 'Nhắc chuẩn bị';
            stage2Label = 'Bắt đầu';
            break;
          case TaskIntent.deadline:
            stage1Time = targetTime.subtract(const Duration(hours: 2));
            stage1Label = 'Nhắc chuẩn bị';
            stage2Label = 'Hạn cuối';
            break;
          case TaskIntent.reminder:
            stage1Time = targetTime.subtract(const Duration(minutes: 15));
            stage1Label = 'Nhắc nhở';
            stage2Label = 'Đúng giờ';
            break;
        }
      }
      if (stage2Label.isEmpty) {
        stage2Label = intent == TaskIntent.event ? 'Bắt đầu' : 'Đúng giờ';
      }
    }

    return DualStageResult(
      title: parsed.title,
      intent: intent,
      targetTime: targetTime,
      category: parsed.category,
      tags: parsed.tags,
      stage1Time: stage1Time,
      stage1Label: stage1Label,
      stage2Time: stage2Time,
      stage2Label: stage2Label,
      preReminderOffset: parsed.preReminderOffset,
      description: parsed.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(14),
      blur: 16,
      border: Border.all(
        color: _focusNode.hasFocus
            ? AppColors.primary.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        width: _focusNode.hasFocus ? 1 : 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input row
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(left: 12, right: 8, top: 6, bottom: 6),
            child: Row(
              children: [
                // AI sparkle icon
                _buildSparkleIcon(),
                const SizedBox(width: 8),
                Expanded(
                  child: _isProcessing
                      ? _buildProcessingIndicator()
                      : TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          onChanged: _onChanged,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: _aiEnabled
                                ? 'AI thêm nhanh task (ví dụ: Nộp bài trước 11h đêm mai #Bài_tập)'
                                : 'Thêm task...',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.5),
                                fontSize: 12.5,
                                height: 1.4),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _submit(),
                          textInputAction: TextInputAction.send,
                        ),
                ),
                const SizedBox(width: 4),

                // AI toggle button
                _buildAiToggle(),
                const SizedBox(width: 4),

                // Send button
                GestureDetector(
                  onTap: _isProcessing ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: _isProcessing
                          ? null
                          : AppGradient.primary,
                      color: _isProcessing ? AppColors.textMuted.withValues(alpha: 0.3) : null,
                      shape: BoxShape.circle,
                      boxShadow: _isProcessing
                          ? null
                          : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Preview chips
          if (_preview != null && (_preview!.hasTime || _preview!.tags.isNotEmpty || _preview!.intent != TaskIntent.reminder))
            _buildSmartPreview(_preview!),
        ],
      ),
    );
  }

  // ===== AI SPARKLE ICON =====
  Widget _buildSparkleIcon() {
    return AnimatedBuilder(
      animation: _sparkleAnim,
      builder: (context, child) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15 * _sparkleAnim.value),
                AppColors.warning.withValues(alpha: 0.1 * _sparkleAnim.value),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2 * _sparkleAnim.value),
              width: 0.5,
            ),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 15,
            color: Color.lerp(
              AppColors.primary,
              AppColors.warning,
              _sparkleAnim.value * 0.5,
            ),
          ),
        );
      },
    );
  }

  // ===== AI TOGGLE =====
  Widget _buildAiToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _aiEnabled = !_aiEnabled;
        if (!_aiEnabled) _preview = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _aiEnabled
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: _aiEnabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 10,
              color: _aiEnabled ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 3),
            Text(
              'AI',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _aiEnabled ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== PROCESSING INDICATOR =====
  Widget _buildProcessingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'AI đang phân tích...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // ===== SMART PREVIEW CHIPS =====
  Widget _buildSmartPreview(DualStageResult result) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Intent + Time + Tags
          Row(
            children: [
              _intentBadge(result.intent),
              if (result.targetTime != null) ...[
                const SizedBox(width: 6),
                _smartChip(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDateTime(result.targetTime!),
                  color: AppColors.primary,
                ),
              ],
              if (result.tags.isNotEmpty) ...[
                const SizedBox(width: 4),
                ...result.tags.take(2).map((t) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _smartChip(
                    icon: Icons.label_rounded,
                    label: '#$t',
                    color: AppColors.purple,
                  ),
                )),
              ],
              if (result.category != TaskCategory.personal) ...[
                const SizedBox(width: 4),
                _smartChip(
                  icon: _getCategoryIcon(result.category),
                  label: _getCategoryLabel(result.category),
                  color: result.category.color,
                ),
              ],
            ],
          ),

          // Row 2: Dual-stage reminders
          if (result.hasStage1 || result.hasStage2) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (result.hasStage1)
                  _reminderChip(
                    icon: Icons.notifications_active_rounded,
                    time: result.stage1Time!,
                    label: result.stage1Label,
                    color: AppColors.orange,
                  ),
                if (result.hasStage1 && result.hasStage2) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 10, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                ],
                if (result.hasStage2)
                  _reminderChip(
                    icon: result.intent == TaskIntent.event ? Icons.event_rounded : Icons.flag_rounded,
                    time: result.stage2Time!,
                    label: result.stage2Label,
                    color: result.intent == TaskIntent.event ? AppColors.primary : AppColors.error,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===== SMART CHIP =====
  Widget _smartChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _intentBadge(TaskIntent intent) {
    String label;
    IconData icon;
    Color color;

    switch (intent) {
      case TaskIntent.event:
        label = 'Sự kiện';
        icon = Icons.event_rounded;
        color = AppColors.primary;
        break;
      case TaskIntent.deadline:
        label = 'Deadline';
        icon = Icons.flag_rounded;
        color = AppColors.error;
        break;
      case TaskIntent.reminder:
        label = 'Nhắc nhở';
        icon = Icons.notifications_rounded;
        color = AppColors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _reminderChip({
    required IconData icon,
    required DateTime time,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  String _getCategoryLabel(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.class_: return 'Lớp học';
      case TaskCategory.exam: return 'Kỳ thi';
      case TaskCategory.assignment: return 'Bài tập';
      case TaskCategory.personal: return 'Cá nhân';
    }
  }

  IconData _getCategoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.class_: return Icons.school_rounded;
      case TaskCategory.exam: return Icons.quiz_rounded;
      case TaskCategory.assignment: return Icons.assignment_rounded;
      case TaskCategory.personal: return Icons.person_rounded;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    String dateStr = '';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      dateStr = 'Hôm nay';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day + 1) {
      dateStr = 'Ngày mai';
    } else {
      dateStr = '${dt.day}/${dt.month}';
    }
    return '$dateStr ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
