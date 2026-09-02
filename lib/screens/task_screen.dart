import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../shared/widgets/task_card.dart';
import '../shared/widgets/progress_widgets.dart';
import 'task_detail_screen.dart';

class TaskScreen extends StatefulWidget {
  final TaskService taskService;
  const TaskScreen({super.key, required this.taskService});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  TaskCategory? _selectedCategory;
  String _searchQuery = '';
  bool _showSearch = false;
  bool _showCompleted = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _submitTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    widget.taskService.addTask(title: title);
    _taskController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _toggleTask(Task task) async {
    final wasDone = task.isDone;
    await widget.taskService.toggleTask(task.id);
    setState(() {});

    if (!wasDone) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
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
              setState(() {});
            }),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 4),
      ));
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        backgroundColor: AppColors.surface,
        title: const Text('Xóa task'),
        content: Text('Xóa "${task.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa',
                  style: TextStyle(color: AppColors.error))),
        ],
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tạm hoãn:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ListTile(
            leading: Icon(Icons.timer_rounded, color: AppColors.primary),
            title: const Text('10 phút'),
            onTap: () => Navigator.pop(context, 10)),
        ListTile(
            leading: const Icon(Icons.timer_rounded, color: AppColors.orange),
            title: const Text('1 giờ'),
            onTap: () => Navigator.pop(context, 60)),
        ListTile(
            leading: const Icon(Icons.calendar_today_rounded, color: AppColors.green),
            title: const Text('Ngày mai'),
            onTap: () => Navigator.pop(context, 1440)),
        const SizedBox(height: 8),
      ])),
    );
    if (option != null) {
      await widget.taskService.snoozeTask(task.id, Duration(minutes: option));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = widget.taskService.getTasksGroupedByDate();
    var filtered = _selectedCategory != null
        ? grouped.map((k, v) => MapEntry(
            k, v.where((t) => t.category == _selectedCategory).toList()))
        : grouped;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.map((k, v) => MapEntry(
          k, v.where((t) => t.title.toLowerCase().contains(q)).toList()));
    }
    final hasAny = filtered.values.any((l) => l.isNotEmpty);
    final completedTasks = widget.taskService.completedTasks;
    final totalDone = completedTasks.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: true,
        child: CustomScrollView(
          slivers: [
            // App Bar with integrated stats subtitle
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
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
                        const Text('Tasks',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Tổng ${widget.taskService.tasks.length} · Đang chờ ${widget.taskService.pendingTasks.length} · Hoàn thành $totalDone',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted.withValues(alpha: 0.7),
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
                if (_selectedCategory != null)
                  IconButton(
                      icon: Icon(Icons.filter_alt_off_rounded, size: 20, color: AppColors.primary),
                      onPressed: () => setState(() => _selectedCategory = null)),
                IconButton(
                  icon: Icon(Icons.filter_list_rounded, size: 22,
                      color: _selectedCategory != null ? AppColors.primary : AppColors.textSecondary),
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
                      (ctx, i) => _buildGroupedSection(grouped, i),
                      childCount: _countGroups(grouped),
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

            // Completed Section
            if (!_showSearch && completedTasks.isNotEmpty && _searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompleted = !_showCompleted),
                    child: Row(children: [
                      Icon(_showCompleted ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 18, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      Icon(Icons.check_circle_outline_rounded, size: 14,
                          color: AppColors.success.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text('Đã hoàn thành (${completedTasks.length})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.textMuted.withValues(alpha: 0.6))),
                    ]),
                  ),
                ),
              ),
              if (_showCompleted)
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => TaskCard(
                        title: completedTasks[i].title,
                        subtitle: _formatSubtitle(completedTasks[i]),
                        categoryColor: completedTasks[i].category.color,
                        isDone: true,
                        hasNote: completedTasks[i].hasNote,
                        onTap: () => _openTaskDetail(completedTasks[i]),
                        onToggle: () => _toggleTask(completedTasks[i]),
                        onDelete: () => _deleteTask(completedTasks[i]),
                      ),
                      childCount: completedTasks.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== QUICK TASK INPUT (Glass Blur) =====
  Widget _buildQuickTaskInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Thêm nhanh task...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _submitTask(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                Material(
                  color: AppColors.cyberBlueViolet,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    onPressed: _submitTask,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          _buildFilterPill(label: 'Tất cả', icon: Icons.all_inclusive_rounded,
              color: AppColors.textSecondary, selected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null)),
          const SizedBox(width: 5),
          ...TaskCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 5),
                child: _buildFilterPill(
                  label: _getCategoryLabel(cat), icon: _getCategoryIcon(cat),
                  color: cat.color, selected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
      {required String label, required IconData icon, required Color color,
       required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyberBlueViolet
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? AppColors.cyberBlueViolet
                  : Colors.white.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12,
                color: selected ? Colors.white : AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
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

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
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
        RadioGroup<TaskCategory?>(
            groupValue: _selectedCategory,
            onChanged: (v) { Navigator.pop(context); setState(() => _selectedCategory = null); },
            child: RadioListTile<TaskCategory?>(
                value: null, title: const Text('Tất cả danh mục'), activeColor: AppColors.primary)),
        ...TaskCategory.values.map((cat) =>
            RadioGroup<TaskCategory?>(
              groupValue: _selectedCategory,
              onChanged: (v) { Navigator.pop(context); setState(() => _selectedCategory = cat); },
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
  static const _groupLabels = {
    'Overdue': 'Quá hạn', 'Today': 'Hôm nay', 'Tomorrow': 'Ngày mai',
    'This Week': 'Tuần này', 'Later': 'Sau đó', 'No Date': 'Không có ngày',
  };
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
            Text(_groupLabels[g] ?? g, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textMuted.withValues(alpha: 0.7))),
            const SizedBox(width: 8),
            Text('${tasks.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _groupColors[g])),
          ]),
        );
      }
      cursor++;
      for (final task in tasks) {
        if (flatIndex == cursor) {
          return TaskCard(
            title: task.title, subtitle: _formatSubtitle(task),
            categoryColor: task.category.color, isDone: task.isDone,
            isOverdue: task.isOverdue, hasNote: task.hasNote,
            onTap: () => _openTaskDetail(task), onToggle: () => _toggleTask(task),
            onDelete: () => _deleteTask(task), onSnooze: () => _snoozeTask(task),
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
        dateStr = 'Hôm nay';
      } else if (d.year == now.year && d.month == now.month && d.day == now.day + 1) {
        dateStr = 'Ngày mai';
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
    final quotes = [
      "Hôm nay thật thư giãn — chưa có task nào!",
      "Tận hưởng ngày mới, task sẽ đến sau.",
      "Đã xong hết rồi, nghỉ ngơi thôi!",
      "Một ngày trống trải — hãy thêm task mới.",
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.task_alt_rounded, size: 32,
                  color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text(quote, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic, height: 1.5)),
            const SizedBox(height: 6),
            Text('Nhập task ở ô phía trên',
                style: TextStyle(fontSize: 11,
                    color: AppColors.textMuted.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }
}
