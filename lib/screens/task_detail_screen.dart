import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskService taskService;
  final Task task;

  const TaskDetailScreen(
      {super.key, required this.taskService, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _noteCtrl = TextEditingController(text: widget.task.noteContent);
    _isDone = widget.task.isDone;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty && _noteCtrl.text.trim().isEmpty) return;

    final newStatus = _isDone ? TaskStatus.done : TaskStatus.pending;

    await widget.taskService.updateTask(
      widget.task.id,
      title: title.isNotEmpty ? title : 'Untitled',
      noteContent: _noteCtrl.text.trim(),
      status: newStatus,
    );

    if (mounted) Navigator.pop(context, true);
  }

  void _toggleDone() => setState(() => _isDone = !_isDone);

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 36, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Xóa task?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${_titleCtrl.text}"',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassDialogBtn(
                          label: 'Hủy',
                          color: AppColors.textMuted,
                          onTap: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassDialogBtn(
                          label: 'Xóa',
                          color: AppColors.error,
                          onTap: () => Navigator.pop(ctx, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirm == true) {
      await widget.taskService.deleteTask(widget.task.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildGlassDialogBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.class_:
        return Icons.school_rounded;
      case TaskCategory.exam:
        return Icons.quiz_rounded;
      case TaskCategory.assignment:
        return Icons.assignment_rounded;
      case TaskCategory.personal:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _save();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ===== GLASS APP BAR =====
            _buildGlassAppBar(),

            // ===== SCROLLABLE CONTENT =====
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, 24 + bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== TITLE GLASS CARD =====
                      _buildTitleCard(task),
                      const SizedBox(height: 14),

                      // ===== TIME & DATE GLASS CARD =====
                      _buildTimeDateCard(task),
                      const SizedBox(height: 14),

                      // ===== NOTES GLASS CARD =====
                      _buildNotesCard(),
                    ],
                  ),
                ),
              ),
            ),

            // ===== BOTTOM ACTION TOOLBAR =====
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  // ===== GLASS APP BAR =====
  Widget _buildGlassAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              // Back button
              _buildGlassIconBtn(
                icon: Icons.arrow_back_rounded,
                onTap: _save,
              ),
              const Spacer(),
              // Done toggle
              GestureDetector(
                onTap: _toggleDone,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isDone
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: _isDone
                          ? AppColors.success.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: _isDone
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isDone ? 'Xong' : 'Đánh dấu xong',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isDone
                                ? AppColors.success
                                : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              _buildGlassIconBtn(
                icon: Icons.delete_outline_rounded,
                onTap: _delete,
                iconColor: AppColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
      ),
    );
  }

  // ===== TITLE GLASS CARD =====
  Widget _buildTitleCard(Task task) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: task.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.category.color.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  _categoryIcon(task.category),
                  size: 20,
                  color: task.category.color,
                ),
              ),
              const SizedBox(width: 14),

              // Title input
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Tiêu đề task...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== TIME & DATE GLASS CARD =====
  Widget _buildTimeDateCard(Task task) {
    final timeStr = task.dueTime != null
        ? DateFormat('HH:mm').format(task.dueTime!)
        : '--:--';
    final dateStr = task.dueDate != null
        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
        : '--/--/----';
    final hasTime = task.dueTime != null;
    final hasDate = task.dueDate != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Time block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\u{1F552}',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Giờ học',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: hasTime
                            ? AppColors.primary
                            : AppColors.textMuted.withValues(alpha: 0.3),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.08),
              ),

              // Date block
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '\u{1F4C5}',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ngày',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: hasDate
                              ? AppColors.orange
                              : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overdue warning
              if (task.isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'Quá hạn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== NOTES GLASS CARD =====
  Widget _buildNotesCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notes_rounded,
                      size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Ghi chú',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.7),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Viết ghi chú...\nHỗ trợ checklist, bullet points, freely.',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      fontSize: 15,
                      height: 1.7),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BOTTOM ACTION TOOLBAR =====
  Widget _buildBottomToolbar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _buildToolbarBtn(
                  icon: Icons.notifications_active_rounded,
                  label: 'Báo thức',
                  color: AppColors.orange,
                ),
                const SizedBox(width: 10),
                _buildToolbarBtn(
                  icon: Icons.label_rounded,
                  label: 'Tag',
                  color: AppColors.teal,
                ),
                const SizedBox(width: 10),
                _buildToolbarBtn(
                  icon: Icons.attach_file_rounded,
                  label: 'File',
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarBtn({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
