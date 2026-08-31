import 'package:flutter/material.dart';
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
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _noteCtrl = TextEditingController(text: widget.task.noteContent);
    _isDone = widget.task.isDone;

    _titleCtrl.addListener(() => _hasChanges = true);
    _noteCtrl.addListener(() => _hasChanges = true);
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

    final newStatus =
        _isDone ? TaskStatus.done : TaskStatus.pending;

    await widget.taskService.updateTask(
      widget.task.id,
      title: title.isNotEmpty ? title : 'Untitled',
      noteContent: _noteCtrl.text.trim(),
      status: newStatus,
    );

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleDone() async {
    setState(() => _isDone = !_isDone);
    _hasChanges = true;
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        backgroundColor: AppColors.surface,
        title: const Text('Delete Task'),
        content: Text('Delete "${_titleCtrl.text}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.taskService.deleteTask(widget.task.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // ===== HEADER BAR =====
            Container(
              height: 48,
              color: AppColors.surface,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: _save,
                  ),
                  const Spacer(),
                  // Done toggle
                  GestureDetector(
                    onTap: _toggleDone,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isDone
                            ? AppColors.success.withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: _isDone
                              ? AppColors.success.withOpacity(0.4)
                              : Colors.white.withOpacity(0.08),
                          width: 1,
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
                            _isDone ? 'Done' : 'Mark done',
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
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20,
                        color:
                            AppColors.error.withOpacity(0.6)),
                    onPressed: _delete,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // ===== CANVAS: Title + Note =====
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ===== TITLE INPUT =====
                      TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3),
                        maxLines: null,
                        keyboardType:
                            TextInputType.multiline,
                        textInputAction:
                            TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Task title...',
                          hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 22,
                              fontWeight: FontWeight.w600),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) =>
                            _hasChanges = true,
                      ),

                      const SizedBox(height: 20),

                      // ===== NOTE CONTENT =====
                      TextField(
                        controller: _noteCtrl,
                        style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.7),
                        maxLines: null,
                        keyboardType:
                            TextInputType.multiline,
                        textInputAction:
                            TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText:
                              'Ghi chú...\nViết freely, không giới hạn.',
                          hintStyle: TextStyle(
                              color: AppColors.textMuted
                                  .withOpacity(0.3),
                              fontSize: 15,
                              height: 1.7),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) =>
                            _hasChanges = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
