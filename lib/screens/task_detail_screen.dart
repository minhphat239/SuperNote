import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../l10n/app_localizations.dart';
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
  bool _isSaving = false;

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

  Future<void> _saveAndPop() async {
    if (_isSaving) return;
    _isSaving = true;
    final title = _titleCtrl.text.trim();
    if (title.isNotEmpty || _noteCtrl.text.trim().isNotEmpty) {
      final newStatus = _isDone ? TaskStatus.done : TaskStatus.pending;
      await widget.taskService.updateTask(
        widget.task.id,
        title: title.isNotEmpty ? title : 'Untitled',
        noteContent: _noteCtrl.text.trim(),
        status: newStatus,
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _showTimePicker() async {
    final now = DateTime.now();
    final initial = widget.task.dueTime != null
        ? TimeOfDay(hour: widget.task.dueTime!.hour, minute: widget.task.dueTime!.minute)
        : TimeOfDay(hour: now.hour, minute: now.minute);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final newDueTime = DateTime(2000, 1, 1, picked.hour, picked.minute);
      await widget.taskService.updateTask(widget.task.id, dueTime: newDueTime);
      if (mounted) setState(() {});
    }
  }

  Future<void> _showDatePicker() async {
    final initial = widget.task.dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      await widget.taskService.updateTask(widget.task.id, dueDate: picked);
      if (mounted) setState(() {});
    }
  }

  void _toggleDone() => setState(() => _isDone = !_isDone);

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 36, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.deleteTask,
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
                          label: AppLocalizations.of(context)!.cancel,
                          color: AppColors.textMuted,
                          onTap: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassDialogBtn(
                          label: AppLocalizations.of(context)!.delete,
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
        _saveAndPop();
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
                      if (widget.task.attachments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildAttachmentsCard(),
                      ],
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
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52 + topPadding,
          padding: EdgeInsets.only(top: topPadding),
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
                onTap: _saveAndPop,
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
                        _isDone ? AppLocalizations.of(context)!.markDoneShort : AppLocalizations.of(context)!.markDone,
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
            color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 1.5),
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
                    hintText: AppLocalizations.of(context)!.taskTitle,
                    hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                    filled: false,
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
            color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 1.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Time block - tappable
              Expanded(
                child: GestureDetector(
                  onTap: _showTimePicker,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.selectTime,
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
              ),

              // Divider
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.08),
              ),

              // Date block - tappable
              Expanded(
                child: GestureDetector(
                  onTap: _showDatePicker,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.selectDate,
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
                    AppLocalizations.of(context)!.expired,
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
            color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 1.5),
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
                    AppLocalizations.of(context)!.taskNotes,
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
                  hintText: AppLocalizations.of(context)!.taskNotesHint,
                  hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      fontSize: 15,
                      height: 1.7),
                  filled: false,
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

  // ===== ATTACHMENTS GLASS CARD =====
  Widget _buildAttachmentsCard() {
    final files = widget.task.attachments;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 1.5),
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
                  Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.attachmentCount(files.length),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              ...files.map((path) {
                final name = path.split(Platform.pathSeparator).last;
                final ext = name.split('.').last.toLowerCase();
                final icon = _getFileIcon(ext);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BOTTOM ACTION TOOLBAR =====
  Widget _buildBottomToolbar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, 10 + bottomPad),
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
                  label: AppLocalizations.of(context)!.alarm,
                  color: AppColors.orange,
                  onTap: _showAlarmPicker,
                ),
                const SizedBox(width: 10),
                _buildToolbarBtn(
                  icon: Icons.label_rounded,
                  label: AppLocalizations.of(context)!.filterAll,
                  color: AppColors.teal,
                  onTap: _showCategoryPicker,
                ),
                const SizedBox(width: 10),
                _buildToolbarBtn(
                  icon: Icons.attach_file_rounded,
                  label: AppLocalizations.of(context)!.attachmentFile,
                  color: AppColors.primaryLight,
                  onTap: _showFileOption,
                  badge: widget.task.attachments.isNotEmpty ? widget.task.attachments.length : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlarmPicker() {
    final offsets = <int?>[5, 10, 15, 30, 60, 120, 1440];
    final labels = <String>['5 min', '10 min', '15 min', '30 min', '1 giờ', '2 giờ', '1 ngày'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.alarm,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (widget.task.preReminderOffset != null)
                      GestureDetector(
                        onTap: () async {
                          await widget.taskService.updateTask(
                            widget.task.id, preReminderOffset: null);
                          if (mounted) setState(() {});
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(AppLocalizations.of(context)!.delete,
                            style: TextStyle(fontSize: 13, color: AppColors.error)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(offsets.length, (i) {
                  final isSelected = widget.task.preReminderOffset == offsets[i];
                  return GestureDetector(
                    onTap: () async {
                      await widget.taskService.updateTask(
                        widget.task.id, preReminderOffset: offsets[i]);
                      if (mounted) setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.orange.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.orange : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 16,
                              color: isSelected ? AppColors.orange : AppColors.textMuted),
                          const SizedBox(width: 12),
                          Text('Nhắc trước ${labels[i]}',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? AppColors.orange : AppColors.textPrimary)),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, size: 18, color: AppColors.orange),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final cats = TaskCategory.values;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.label_rounded, size: 18, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.categoryBreakdown,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                ...cats.map((cat) {
                  final isSelected = widget.task.category == cat;
                  return GestureDetector(
                    onTap: () async {
                      await widget.taskService.updateTask(
                        widget.task.id, category: cat);
                      if (mounted) setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cat.color : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_categoryIcon(cat), size: 18,
                              color: isSelected ? cat.color : AppColors.textMuted),
                          const SizedBox(width: 12),
                          Text(cat.label,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? cat.color : AppColors.textPrimary)),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, size: 18, color: cat.color),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFileOption() {
    final files = widget.task.attachments;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_file_rounded, size: 18, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.attachFile,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                // Add file button
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                    if (result != null) {
                      final newPaths = result.paths.whereType<String>().toList();
                      final updated = [...widget.task.attachments, ...newPaths];
                      await widget.taskService.updateTask(widget.task.id, attachments: updated);
                      if (mounted) setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.chooseFromDevice,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                if (files.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.filesAttached(files.length),
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  ...files.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final path = entry.value;
                    final name = path.split(Platform.pathSeparator).last;
                    final ext = name.split('.').last.toLowerCase();
                    final icon = _getFileIcon(ext);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                Text(ext.toUpperCase(),
                                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final updated = List<String>.from(files)..removeAt(idx);
                              await widget.taskService.updateTask(widget.task.id, attachments: updated);
                              if (mounted) setState(() {});
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam_rounded;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildToolbarBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
            if (badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
