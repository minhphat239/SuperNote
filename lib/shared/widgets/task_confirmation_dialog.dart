import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/nlp_dual_stage.dart';
import '../../models/task.dart';

class TaskConfirmationDialog extends StatefulWidget {
  final List<DualStageResult> parsedList;
  final String rawInput;

  const TaskConfirmationDialog({
    super.key,
    required this.parsedList,
    required this.rawInput,
  });

  @override
  State<TaskConfirmationDialog> createState() => _TaskConfirmationDialogState();
}

class _TaskConfirmationDialogState extends State<TaskConfirmationDialog> {
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Expand all by default when only 1-3 tasks; collapse when more
    if (widget.parsedList.length <= 3) {
      _expanded.addAll(List.generate(widget.parsedList.length, (i) => i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskCount = widget.parsedList.length;
    final isMulti = taskCount > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradient.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMulti ? 'Thêm $taskCount task mới' : 'Thêm vào Task',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isMulti ? 'Kiểm tra lại danh sách trước khi lưu' : 'Kiểm tra lại trước khi lưu',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Intent badge (only when single task)
                    if (!isMulti) _buildIntentBadge(widget.parsedList.first),
                  ],
                ),
                const SizedBox(height: 14),

                // Raw input quote (smaller for multi-task)
                if (!isMulti)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '"${widget.rawInput}"',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Tasks list (scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < widget.parsedList.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < widget.parsedList.length - 1 ? 8 : 0,
                            ),
                            child: _buildTaskCard(i, widget.parsedList[i], isMulti),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Chỉnh lại',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppGradient.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isMulti ? '✓ Lưu cả $taskCount task' : '✓ Lưu task',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(int index, DualStageResult parsed, bool isMulti) {
    final expanded = _expanded.contains(index) || !isMulti;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (collapsible when multi)
          InkWell(
            onTap: isMulti
                ? () => setState(() {
                      if (expanded) {
                        _expanded.remove(index);
                      } else {
                        _expanded.add(index);
                      }
                    })
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMulti) ...[
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: parsed.category.color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: parsed.category.color.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: parsed.category.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildIntentBadge(parsed),
                        const Spacer(),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.title_rounded,
                          size: 15, color: parsed.category.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parsed.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (parsed.description != null && parsed.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description_rounded,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parsed.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Date & Time + Category on same row (collapsed mode)
                  if (!expanded) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (parsed.targetTime != null) ...[
                          Icon(Icons.access_time_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _formatParsedTime(parsed.targetTime!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (parsed.category != TaskCategory.personal) ...[
                          Icon(_categoryIcon(parsed.category),
                              size: 13, color: parsed.category.color),
                          const SizedBox(width: 4),
                          Text(
                            _categoryLabel(parsed.category),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: parsed.category.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded body
          if (expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Time
                  if (parsed.targetTime != null)
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Thời gian',
                      value: _formatParsedTime(parsed.targetTime!),
                      color: AppColors.primary,
                    ),

                  // Category
                  if (parsed.category != TaskCategory.personal)
                    _buildInfoRow(
                      icon: _categoryIcon(parsed.category),
                      label: 'Phân loại',
                      value: _categoryLabel(parsed.category),
                      color: parsed.category.color,
                    ),

                  // Tags
                  if (parsed.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.label_rounded, size: 14, color: AppColors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: parsed.tags.map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.purple.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Dual-stage reminders
                  if (parsed.hasStage1 || parsed.hasStage2) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications_active_rounded,
                                  size: 12, color: AppColors.orange),
                              const SizedBox(width: 6),
                              Text(
                                'Nhắc nhở',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.orange.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (parsed.hasStage1)
                            Text(
                              '• ${parsed.stage1Label}: ${_formatTimeShort(parsed.stage1Time!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.orange.withValues(alpha: 0.7),
                              ),
                            ),
                          if (parsed.hasStage2)
                            Text(
                              '• ${parsed.stage2Label}: ${_formatTimeShort(parsed.stage2Time!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.orange.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntentBadge(DualStageResult parsed) {
    String label;
    IconData icon;
    Color color;

    switch (parsed.intent) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.class_: return Icons.school_rounded;
      case TaskCategory.exam: return Icons.quiz_rounded;
      case TaskCategory.assignment: return Icons.assignment_rounded;
      case TaskCategory.personal: return Icons.person_rounded;
    }
  }

  String _categoryLabel(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.class_: return 'Lớp học';
      case TaskCategory.exam: return 'Kỳ thi';
      case TaskCategory.assignment: return 'Bài tập';
      case TaskCategory.personal: return 'Cá nhân';
    }
  }

  String _formatParsedTime(DateTime dt) {
    final now = DateTime.now();
    String dateStr = '';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      dateStr = 'Hôm nay';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day + 1) {
      dateStr = 'Ngày mai';
    } else {
      dateStr = DateFormat('EEEE dd/MM', 'vi').format(dt);
    }
    return '$dateStr • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeShort(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
