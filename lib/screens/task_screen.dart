import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/startup_log.dart';
import '../core/utils/nlp_dual_stage.dart';
import '../models/task.dart';
import '../services/gemini_service.dart';
import '../services/task_service.dart';
import '../shared/widgets/ai_chat_panel.dart';
import '../shared/widgets/nlp_input_bar.dart';
import '../shared/widgets/task_card.dart';
import '../shared/widgets/progress_widgets.dart';
import 'task_detail_screen.dart';
import '../l10n/app_localizations.dart';

class TaskScreen extends StatefulWidget {
  final TaskService taskService;
  final GeminiService? geminiService;
  const TaskScreen({super.key, required this.taskService, this.geminiService});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  TaskCategory? _selectedCategory;
  bool _showOverdueOnly = false;
  String _searchQuery = '';
  bool _showSearch = false;
  DateTime _selectedDate = DateTime.now();
  StreamSubscription<List<Task>>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    StartupLog.mark('taskScreen-initState');
    _taskSubscription = widget.taskService.taskStream.listen((_) {
      if (mounted) setState(() {});
    });
    StartupLog.mark('taskScreen-subscribed');
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  void _submitNlpTask(List<DualStageResult> results) {
    if (results.isEmpty) return;
    for (final result in results) {
      DateTime? dueDate;
      DateTime? dueTime;
      if (result.targetTime != null) {
        dueDate = DateTime(result.targetTime!.year, result.targetTime!.month, result.targetTime!.day);
        dueTime = DateTime(2000, 1, 1, result.targetTime!.hour, result.targetTime!.minute);
      }

      final preReminder = result.preReminderOffset ??
          (result.hasStage1 ? result.stage1OffsetMinutes : null);

      widget.taskService.addTask(
        title: result.title.isEmpty ? 'Untitled Task' : result.title,
        description: result.description ?? '',
        dueDate: dueDate,
        dueTime: dueTime,
        category: result.category,
        preReminderOffset: preReminder,
      );
    }

    if (!mounted) return;
    if (results.length > 1) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: AppColors.onAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Đã thêm ${results.length} task mới',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 3),
      ));
    }
    setState(() {});
  }

  void _toggleTask(Task task) async {
    final wasDone = task.isDone;
    try {
      await widget.taskService.toggleTask(task.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: $e'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!mounted) return;
    setState(() {});

    if (!wasDone) {
      ScaffoldMessenger.of(context).clearSnackBars();
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: AppColors.onAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Đã hoàn thành: ${task.title}',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        action: SnackBarAction(
            label: 'HOÀN TÁC',
            textColor: AppColors.primaryLight,
            onPressed: () async {
              await widget.taskService.toggleTask(task.id);
              if (mounted) setState(() {});
            }),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 3),
      ));
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) messenger.hideCurrentSnackBar();
      });
    }
  }

  void _openTaskDetail(Task task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              TaskDetailScreen(taskService: widget.taskService, task: task)),
    );
    if (result == true) setState(() {});
  }

  void _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
                    AppLocalizations.of(context)!.deleteTaskTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.deleteTaskConfirm(task.title),
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
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppColors.textMuted.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.delete,
                            style: TextStyle(color: AppColors.error),
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
      ),
    );
    if (confirm == true) {
      await widget.taskService.deleteTask(task.id);
      setState(() {});
    }
  }

  void _snoozeTask(Task task) async {
    final option = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                        color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('${AppLocalizations.of(context)!.snoozed}:',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                ListTile(
                    leading: Icon(Icons.timer_rounded, color: AppColors.primary),
                    title: const Text('10 phút'),
                    onTap: () => Navigator.pop(context, 10)),
                ListTile(
                    leading: Icon(Icons.timer_rounded, color: AppColors.orange),
                    title: const Text('1 giờ'),
                    onTap: () => Navigator.pop(context, 60)),
                ListTile(
                    leading: Icon(Icons.calendar_today_rounded, color: AppColors.green),
                    title: Text(AppLocalizations.of(context)!.tomorrow),
                    onTap: () => Navigator.pop(context, 1440)),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
    if (option != null) {
      await widget.taskService.snoozeTask(task.id, Duration(minutes: option));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = widget.taskService.getTasksGroupedByDate();
    var filtered = grouped;
    if (_showOverdueOnly) {
      // Chỉ hiện task quá hạn
      filtered = grouped.map((k, v) => MapEntry(
          k, k == 'Overdue' ? v : []));
    } else if (_selectedCategory != null) {
      // Filter theo category, bỏ qua task quá hạn
      filtered = grouped.map((k, v) => MapEntry(
          k, k == 'Overdue' ? [] : v.where((t) => t.category == _selectedCategory).toList()));
    } else {
      // "Tất cả": ẩn task quá hạn, chỉ hiện các nhóm còn lại
      filtered = grouped.map((k, v) => MapEntry(
          k, k == 'Overdue' ? [] : v));
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.map((k, v) => MapEntry(
          k, v.where((t) => t.title.toLowerCase().contains(q)).toList()));
    }
    final hasAny = filtered.values.any((l) => l.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        bottom: true,
        child: CustomScrollView(
          slivers: [
            // App Bar with integrated stats subtitle
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 4),
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 56,
              title: _showSearch
                  ? TextField(
                      autofocus: true,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          hintText: 'Tìm task...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppColors.textMuted)),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.tasksTitle,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Tổng ${widget.taskService.tasks.length} · Đang chờ ${widget.taskService.pendingTasks.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFA0AAB2),
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppColors.textMuted),
                      onPressed: () =>
                          setState(() { _searchQuery = ''; _showSearch = false; })),
                IconButton(
                  icon: Icon(
                      _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                      size: 22,
                      color: _showSearch ? AppColors.primary : AppColors.textSecondary),
                  onPressed: () => setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _searchQuery = '';
                  }),
                ),
                if (_selectedCategory != null || _showOverdueOnly)
                  IconButton(
                      icon: Icon(Icons.filter_alt_off_rounded, size: 20, color: AppColors.primary),
                      onPressed: () => setState(() { _selectedCategory = null; _showOverdueOnly = false; })),
                IconButton(
                  icon: Icon(Icons.filter_list_rounded, size: 22,
                      color: (_selectedCategory != null || _showOverdueOnly) ? AppColors.primary : AppColors.textSecondary),
                  onPressed: _showCategoryFilter,
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Weekly Calendar Strip (72px)
            if (!_showSearch)
              SliverToBoxAdapter(
                child: WeeklyCalendarStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                  taskCounts: _getTaskCountsForWeek(),
                ),
              ),

            // Quick Task Input
            if (!_showSearch)
              SliverToBoxAdapter(
                child: _buildQuickTaskInput(),
              ),

            // Category Filter Chips
            if (!_showSearch)
              SliverToBoxAdapter(child: _buildCategoryFilterBar()),

            // Task List
            if (!_showSearch && _searchQuery.isEmpty) ...[
              if (!hasAny)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 20),
                  sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildGroupedSection(filtered, i),
                      childCount: _countGroups(filtered),
                    ),
                  ),
                ),
            ],

            // Search results
            if (_searchQuery.isNotEmpty || (_showSearch && hasAny))
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildGroupedSection(
                        _searchQuery.isNotEmpty ? filtered : grouped, i),
                    childCount: _countGroups(
                        _searchQuery.isNotEmpty ? filtered : grouped),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== QUICK TASK INPUT (NlpInputBar) =====
  Widget _buildQuickTaskInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: NlpInputBar(
        onSubmit: _submitNlpTask,
        geminiService: widget.geminiService,
        hintText: 'Thêm nhanh task (VD: Họp 2h chiều mai gấp)...',
      ),
    );
  }

  // ===== CATEGORY FILTER BAR =====
  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterPill(label: AppLocalizations.of(context)!.filterAll, icon: Icons.all_inclusive_rounded,
              color: AppColors.primary, selected: !_showOverdueOnly && _selectedCategory == null,
              onTap: () => setState(() { _showOverdueOnly = false; _selectedCategory = null; })),
          const SizedBox(width: 8),
          _buildFilterPill(label: AppLocalizations.of(context)!.overdue, icon: Icons.warning_rounded,
              color: AppColors.error, selected: _showOverdueOnly,
              onTap: () => setState(() { _showOverdueOnly = true; _selectedCategory = null; }),
              count: widget.taskService.pendingTasks.where((t) => t.isOverdue).length),
          const SizedBox(width: 8),
          ...TaskCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterPill(
                  label: _getCategoryLabel(cat), icon: _getCategoryIcon(cat),
                  color: cat.color, selected: !_showOverdueOnly && _selectedCategory == cat,
                  onTap: () => setState(() { _showOverdueOnly = false; _selectedCategory = cat; }),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
      {required String label, required IconData icon, required Color color,
       required bool selected, required VoidCallback onTap, int? count}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: selected ? color : AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? color : AppColors.textSecondary)),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(TaskCategory cat) {
    final l10n = AppLocalizations.of(context)!;
    switch (cat) {
      case TaskCategory.class_: return l10n.filterClass;
      case TaskCategory.exam: return l10n.filterExam;
      case TaskCategory.assignment: return l10n.filterAssignment;
      case TaskCategory.personal: return l10n.filterPersonal;
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

  void _showCategoryFilter() {
    final overdueCount = widget.taskService.pendingTasks.where((t) => t.isOverdue).length;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Lọc theo danh mục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        RadioListTile<bool>(
            groupValue: _showOverdueOnly,
            value: false,
            onChanged: (v) { Navigator.pop(context); setState(() { _showOverdueOnly = false; _selectedCategory = null; }); },
            title: const Text('Tất cả danh mục'),
            activeColor: AppColors.primary),
        RadioListTile<bool>(
            groupValue: _showOverdueOnly,
            value: true,
            onChanged: (v) { Navigator.pop(context); setState(() { _showOverdueOnly = true; _selectedCategory = null; }); },
            title: Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text('Quá hạn ($overdueCount)')
            ]),
            activeColor: AppColors.error),
        ...TaskCategory.values.map((cat) =>
            RadioGroup<TaskCategory?>(
              groupValue: _selectedCategory,
              onChanged: (v) { Navigator.pop(context); setState(() { _showOverdueOnly = false; _selectedCategory = cat; }); },
              child: RadioListTile<TaskCategory?>(
                value: cat,
                title: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(_getCategoryLabel(cat))
                ]),
                activeColor: cat.color,
              ),
            )),
        const SizedBox(height: 8),
      ])),
    );
  }

  Map<int, int> _getTaskCountsForWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final counts = <int, int>{};
    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final count = widget.taskService.pendingTasks
          .where((t) => t.dueDate != null && t.dueDate!.year == day.year &&
              t.dueDate!.month == day.month && t.dueDate!.day == day.day)
          .length;
      if (count > 0) counts[day.day] = count;
    }
    return counts;
  }

  static const _groupOrder = ['Overdue', 'Today', 'Tomorrow', 'This Week', 'Later', 'No Date'];

  Map<String, String> _getGroupLabels() {
    final l10n = AppLocalizations.of(context)!;
    return {
      'Overdue': l10n.overdue, 'Today': l10n.today, 'Tomorrow': l10n.tomorrow,
      'This Week': l10n.thisWeek, 'Later': l10n.later, 'No Date': l10n.noDate,
    };
  }
  static final _groupColors = {
    'Overdue': AppColors.red, 'Today': AppColors.orange,
    'Tomorrow': AppColors.primary, 'This Week': AppColors.green,
    'Later': AppColors.purple, 'No Date': AppColors.textMuted,
  };

  int _countGroups(Map<String, List<Task>> grouped) {
    int count = 0;
    for (final g in _groupOrder) {
      final tasks = grouped[g] ?? [];
      if (tasks.isNotEmpty) count += 1 + tasks.length;
    }
    return count;
  }

  Widget? _buildGroupedSection(Map<String, List<Task>> grouped, int flatIndex) {
    int cursor = 0;
    for (final g in _groupOrder) {
      final tasks = grouped[g] ?? [];
      if (tasks.isEmpty) continue;
      if (flatIndex == cursor) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: _groupColors[g], shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _groupColors[g]!.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: -1)])),
            const SizedBox(width: 8),
            Text(_getGroupLabels()[g] ?? g, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textMuted.withValues(alpha: 0.7))),
            const SizedBox(width: 8),
            Text('${tasks.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _groupColors[g])),
          ]),
        );
      }
      cursor++;
      for (final task in tasks) {
        if (flatIndex == cursor) {
          return _SwipeToDelete(
            key: ValueKey(task.id),
            onDelete: () => _deleteTask(task),
            child: TaskCard(
              title: task.title, subtitle: _formatSubtitle(task),
              categoryColor: task.category.color, isDone: task.isDone,
              isOverdue: task.isOverdue, hasNote: task.hasNote,
              onTap: () => _openTaskDetail(task), onToggle: () => _toggleTask(task),
              onDelete: () => _deleteTask(task), onSnooze: () => _snoozeTask(task),
              trailing: task.isOverdue
                  ? GestureDetector(
                      onTap: () => _deleteTask(task),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                      ),
                    )
                  : null,
            ),
          );
        }
        cursor++;
      }
    }
    return null;
  }

  String _formatSubtitle(Task task) {
    final parts = <String>[];
    if (task.dueDate != null) {
      final d = task.dueDate!;
      final now = DateTime.now();
      String dateStr;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        dateStr = AppLocalizations.of(context)!.today;
      } else if (d.isAtSameMomentAs(DateTime(now.year, now.month, now.day + 1))) {
        dateStr = AppLocalizations.of(context)!.tomorrow;
      } else {
        dateStr = DateFormat('dd/MM').format(d);
      }
      if (task.dueTime != null) {
        dateStr += ' ${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}';
      }
      parts.add(dateStr);
    }
    if (task.repeatRule != null) parts.add('🔁 ${task.repeatRule}');
    if (task.preReminderOffset != null && task.preReminderOffset! > 0) {
      parts.add('⏰ ${task.preReminderOffset}m');
    }
    return parts.join('  ·  ');
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final quotes = [
      l10n.emptyRelax,
      l10n.emptyRelaxDesc,
      l10n.emptyDone,
      l10n.emptyFree,
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Soft gradient orb instead of tick icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 32,
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 24),
            Text(quote, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic, height: 1.5)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.emptyHint,
                style: const TextStyle(fontSize: 12,
                    color: Color(0xFFA0AAB2))),
            const SizedBox(height: 24),
            if (widget.geminiService != null)
              GestureDetector(
                onTap: () => AiChatPanel.show(context, widget.geminiService!, widget.taskService),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Thêm task ngay', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeToDelete({super.key, required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: child,
    );
  }
}
