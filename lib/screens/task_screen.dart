import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/nlp_dual_stage.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../shared/widgets/nlp_input_bar.dart';
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
  TaskCategory? _selectedCategory;
  String _searchQuery = '';
  bool _showSearch = false;
  bool _showCompleted = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.taskService.init();
  }

  void _addTask(DualStageResult result) {
    final title = result.title;
    if (title.isEmpty) return;

    widget.taskService.addTask(
      title: title,
      dueDate: result.targetTime,
      dueTime: result.targetTime,
      category: result.category,
      preReminderOffset: result.stage1OffsetMinutes,
    );

    String intent = result.intent == TaskIntent.event
        ? '📅 Event'
        : result.intent == TaskIntent.deadline
            ? '🔴 Deadline'
            : '🔔 Reminder';
    String msg = '$intent: ${title.toUpperCase()}';
    if (result.targetTime != null) {
      msg += ' — ${DateFormat('MMM d, HH:mm').format(result.targetTime!)}';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      duration: const Duration(seconds: 2),
    ));
    setState(() {});
  }

  void _toggleTask(Task task) async {
    final wasDone = task.isDone;
    await widget.taskService.toggleTask(task.id);
    setState(() {});

    if (!wasDone) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Done: ${task.title}',
                  style:
                      const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        action: SnackBarAction(
            label: 'UNDO',
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
          builder: (_) => TaskDetailScreen(
              taskService: widget.taskService, task: task)),
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
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
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
      await widget.taskService.deleteTask(task.id);
      setState(() {});
    }
  }

  void _snoozeTask(Task task) async {
    final option = await showModalBottomSheet<int>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl))),
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Snooze for:',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700))),
        ListTile(
            leading: const Icon(Icons.timer_rounded,
                color: AppColors.primary),
            title: const Text('10 minutes'),
            onTap: () => Navigator.pop(context, 10)),
        ListTile(
            leading: const Icon(Icons.timer_rounded,
                color: AppColors.orange),
            title: const Text('1 hour'),
            onTap: () => Navigator.pop(context, 60)),
        ListTile(
            leading: const Icon(Icons.calendar_today_rounded,
                color: AppColors.green),
            title: const Text('Tomorrow'),
            onTap: () => Navigator.pop(context, 1440)),
        const SizedBox(height: 8),
      ])),
    );
    if (option != null) {
      await widget.taskService.snoozeTask(
          task.id, Duration(minutes: option));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTasks = widget.taskService.getTasksForDate(_selectedDate);
    final grouped = widget.taskService.getTasksGroupedByDate();
    var filtered = _selectedCategory != null
        ? grouped.map((k, v) => MapEntry(
            k,
            v.where((t) => t.category == _selectedCategory).toList()))
        : grouped;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.map((k, v) => MapEntry(
          k, v.where((t) => t.title.toLowerCase().contains(q)).toList()));
    }
    final hasAny = filtered.values.any((l) => l.isNotEmpty);
    final completedTasks = widget.taskService.completedTasks;
    final totalToday = dateTasks.length;
    final doneToday =
        dateTasks.where((t) => t.status == TaskStatus.done).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: _showSearch
                ? TextField(
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                        hintText: 'Search tasks...',
                        border: InputBorder.none,
                        hintStyle:
                            TextStyle(color: AppColors.textMuted)),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                  )
                : const Text('Tasks',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.textPrimary)),
            actions: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.textMuted),
                    onPressed: () => setState(() {
                          _searchQuery = '';
                          _showSearch = false;
                        })),
              IconButton(
                icon: Icon(
                    _showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    size: 22,
                    color: _showSearch
                        ? AppColors.primary
                        : AppColors.textSecondary),
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) _searchQuery = '';
                }),
              ),
              if (_selectedCategory != null)
                IconButton(
                    icon: const Icon(Icons.filter_alt_off_rounded,
                        size: 20, color: AppColors.primary),
                    onPressed: () => setState(
                        () => _selectedCategory = null)),
              IconButton(
                icon: Icon(Icons.filter_list_rounded,
                    size: 22,
                    color: _selectedCategory != null
                        ? AppColors.primary
                        : AppColors.textSecondary),
                onPressed: _showCategoryFilter,
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Weekly Calendar Strip
          if (!_showSearch)
            SliverToBoxAdapter(
              child: WeeklyCalendarStrip(
                selectedDate: _selectedDate,
                onDateSelected: (d) =>
                    setState(() => _selectedDate = d),
                taskCounts: _getTaskCountsForWeek(),
              ),
            ),

          // Progress Card
          if (!_showSearch)
            SliverToBoxAdapter(
              child: _buildProgressCard(totalToday, doneToday),
            ),

          // NLP Quick Input
          if (!_showSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: NlpInputBar(
                  onSubmit: _addTask,
                  hintText:
                      'Thêm nhanh task hoặc gõ "Họp 3h chiều mai"...',
                ),
              ),
            ),

          // Category Filter Chips
          if (!_showSearch)
            SliverToBoxAdapter(
                child: _buildCategoryFilterBar()),

          // Task List for selected date
          if (!_showSearch && _searchQuery.isEmpty) ...[
            if (dateTasks.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => TaskCard(
                      title: dateTasks[i].title,
                      subtitle: _formatSubtitle(dateTasks[i]),
                      categoryColor: dateTasks[i].category.color,
                      isDone: dateTasks[i].isDone,
                      isOverdue: dateTasks[i].isOverdue,
                      hasNote: dateTasks[i].hasNote,
                      onTap: () =>
                          _openTaskDetail(dateTasks[i]),
                      onToggle: () =>
                          _toggleTask(dateTasks[i]),
                      onDelete: () =>
                          _deleteTask(dateTasks[i]),
                      onSnooze: () =>
                          _snoozeTask(dateTasks[i]),
                    ),
                    childCount: dateTasks.length,
                  ),
                ),
              ),
          ],

          // Search results or grouped view
          if (_searchQuery.isNotEmpty || (_showSearch && hasAny))
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildGroupedSection(
                      _searchQuery.isNotEmpty
                          ? filtered
                          : grouped,
                      i),
                  childCount: _countGroups(
                      _searchQuery.isNotEmpty ? filtered : grouped),
                ),
              ),
            ),

          // Completed Section
          if (!_showSearch &&
              completedTasks.isNotEmpty &&
              _searchQuery.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                  onTap: () => setState(
                      () => _showCompleted = !_showCompleted),
                  child: Row(children: [
                    Icon(
                        _showCompleted
                            ? Icons
                                .keyboard_arrow_down_rounded
                            : Icons
                                .keyboard_arrow_right_rounded,
                        size: 18,
                        color: AppColors.textMuted
                            .withOpacity(0.5)),
                    Icon(Icons.check_circle_outline_rounded,
                        size: 14,
                        color: AppColors.success
                            .withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(
                        'Completed (${completedTasks.length})',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted
                                .withOpacity(0.6))),
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
                      subtitle:
                          _formatSubtitle(completedTasks[i]),
                      categoryColor:
                          completedTasks[i].category.color,
                      isDone: true,
                      hasNote: completedTasks[i].hasNote,
                      onTap: () =>
                          _openTaskDetail(completedTasks[i]),
                      onToggle: () =>
                          _toggleTask(completedTasks[i]),
                      onDelete: () =>
                          _deleteTask(completedTasks[i]),
                    ),
                    childCount: completedTasks.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ===== PROGRESS CARD =====
  Widget _buildProgressCard(int total, int done) {
    final progress = total == 0 ? 0.0 : done / total;
    final percentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
            width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã xong $done/$total task',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted
                          .withOpacity(0.8)),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                      AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor:
                        Colors.white.withOpacity(0.06),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      progress < 0.3
                          ? AppColors.error
                          : (progress < 0.7
                              ? AppColors.orange
                              : AppColors.success),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$percentage%',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ],
      ),
    );
  }

  // ===== CATEGORY FILTER BAR =====
  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterPill(
              label: 'All',
              icon: Icons.all_inclusive_rounded,
              color: AppColors.textSecondary,
              selected: _selectedCategory == null,
              onTap: () =>
                  setState(() => _selectedCategory = null)),
          const SizedBox(width: 6),
          ...TaskCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildFilterPill(
                  label: cat.label,
                  icon: _getCategoryIcon(cat),
                  color: cat.color,
                  selected: _selectedCategory == cat,
                  onTap: () => setState(
                      () => _selectedCategory = cat),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
      {required String label,
      required IconData icon,
      required Color color,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
              color: selected
                  ? color
                  : Colors.white.withOpacity(0.08),
              width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: -2)
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected
                    ? color
                    : AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? color
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TaskCategory cat) {
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

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl))),
      builder: (_) => SafeArea(
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filter by Category',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700))),
        RadioListTile<TaskCategory?>(
            value: null,
            groupValue: _selectedCategory,
            onChanged: (v) {
              Navigator.pop(context);
              setState(() => _selectedCategory = null);
            },
            title: const Text('All Categories'),
            activeColor: AppColors.primary),
        ...TaskCategory.values.map((cat) =>
            RadioListTile<TaskCategory?>(
              value: cat,
              groupValue: _selectedCategory,
              onChanged: (v) {
                Navigator.pop(context);
                setState(() => _selectedCategory = cat);
              },
              title: Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(cat.label)
              ]),
              activeColor: cat.color,
            )),
        const SizedBox(height: 8),
      ])),
    );
  }

  Map<int, int> _getTaskCountsForWeek() {
    final now = DateTime.now();
    final start =
        now.subtract(Duration(days: now.weekday - 1));
    final counts = <int, int>{};
    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final count = widget.taskService.pendingTasks
          .where((t) =>
              t.dueDate != null &&
              t.dueDate!.year == day.year &&
              t.dueDate!.month == day.month &&
              t.dueDate!.day == day.day)
          .length;
      if (count > 0) counts[day.day] = count;
    }
    return counts;
  }

  // ===== GROUPED LIST =====
  static const _groupOrder = [
    'Overdue',
    'Today',
    'Tomorrow',
    'This Week',
    'Later',
    'No Date'
  ];
  static const _groupColors = {
    'Overdue': AppColors.red,
    'Today': AppColors.orange,
    'Tomorrow': AppColors.primary,
    'This Week': AppColors.green,
    'Later': AppColors.purple,
    'No Date': AppColors.textMuted,
  };

  int _countGroups(Map<String, List<Task>> grouped) {
    int count = 0;
    for (final g in _groupOrder) {
      final tasks = grouped[g] ?? [];
      if (tasks.isNotEmpty) count += 1 + tasks.length;
    }
    return count;
  }

  Widget? _buildGroupedSection(
      Map<String, List<Task>> grouped, int flatIndex) {
    int cursor = 0;
    for (final g in _groupOrder) {
      final tasks = grouped[g] ?? [];
      if (tasks.isEmpty) continue;
      if (flatIndex == cursor) {
        return Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: _groupColors[g],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _groupColors[g]!
                              .withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: -1)
                    ])),
            const SizedBox(width: 8),
            Text(g,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted
                        .withOpacity(0.7))),
            const SizedBox(width: 8),
            Text('${tasks.length}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _groupColors[g])),
          ]),
        );
      }
      cursor++;
      for (final task in tasks) {
        if (flatIndex == cursor) {
          return TaskCard(
            title: task.title,
            subtitle: _formatSubtitle(task),
            categoryColor: task.category.color,
            isDone: task.isDone,
            isOverdue: task.isOverdue,
            hasNote: task.hasNote,
            onTap: () => _openTaskDetail(task),
            onToggle: () => _toggleTask(task),
            onDelete: () => _deleteTask(task),
            onSnooze: () => _snoozeTask(task),
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
      if (d.year == now.year &&
          d.month == now.month &&
          d.day == now.day) {
        dateStr = 'Today';
      } else if (d.year == now.year &&
          d.month == now.month &&
          d.day == now.day + 1) {
        dateStr = 'Tomorrow';
      } else {
        dateStr = DateFormat('MMM d').format(d);
      }
      if (task.dueTime != null) {
        dateStr +=
            ' ${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}';
      }
      parts.add(dateStr);
    }
    if (task.repeatRule != null) {
      parts.add('🔁 ${task.repeatRule}');
    }
    if (task.preReminderOffset != null &&
        task.preReminderOffset! > 0) {
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(quote,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                  height: 1.5)),
          const SizedBox(height: 8),
          Text('Nhập task ở ô phía trên',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted
                      .withOpacity(0.3))),
        ],
      ),
    );
  }
}
