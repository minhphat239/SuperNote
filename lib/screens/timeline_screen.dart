import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../shared/widgets/glass_widgets.dart';
import '../l10n/app_localizations.dart';
import 'task_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  final TaskService taskService;

  const TimelineScreen({super.key, required this.taskService});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  TaskCategory? _selectedCategory;
  StreamSubscription<List<Task>>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _taskSubscription = widget.taskService.taskStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final allTasks = _getFilteredTasks();

    final todayTasks = allTasks.where((t) => _isToday(t.dueDate, now)).toList()
      ..sort(_sortByTime);

    final tomorrowTasks =
        allTasks.where((t) => _isTomorrow(t.dueDate, now)).toList()
          ..sort(_sortByTime);

    final thisWeekTasks = allTasks
        .where((t) =>
            t.dueDate != null &&
            _isThisWeek(t.dueDate, now) &&
            !_isToday(t.dueDate, now) &&
            !_isTomorrow(t.dueDate, now))
        .toList()
      ..sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));

    final upcomingTasks = allTasks
        .where((t) =>
            t.dueDate == null ||
            (!_isToday(t.dueDate, now) && !_isThisWeek(t.dueDate, now)))
        .toList()
      ..sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));

    final totalToday = todayTasks.length;
    final doneToday =
        todayTasks.where((t) => t.status == TaskStatus.done).length;

    // Build timeline nodes
    final nodes = <_TimelineNode>[
      _TimelineNode(
        title: AppLocalizations.of(context)!.timelineToday,
        subtitle: DateFormat('dd/MM').format(now),
        icon: Icons.today_rounded,
        color: AppColors.primary,
        count: todayTasks.length,
        progress: totalToday > 0 ? doneToday / totalToday : 0,
        tasks: todayTasks,
        showTime: false,
      ),
      if (tomorrowTasks.isNotEmpty)
        _TimelineNode(
          title: AppLocalizations.of(context)!.tomorrow,
          subtitle: DateFormat('dd/MM', 'vi')
              .format(now.add(const Duration(days: 1))),
          icon: Icons.wb_sunny_outlined,
          color: AppColors.orange,
          count: tomorrowTasks.length,
          tasks: tomorrowTasks,
          showTime: false,
        ),
      _TimelineNode(
        title: AppLocalizations.of(context)!.timelineThisWeek,
        subtitle: '${thisWeekTasks.length} ${AppLocalizations.of(context)!.taskCount}',
        icon: Icons.date_range_rounded,
        color: AppColors.primaryLight,
        count: thisWeekTasks.length,
        tasks: thisWeekTasks,
        showTime: true,
      ),
      _TimelineNode(
        title: AppLocalizations.of(context)!.timelineUpcoming,
        subtitle: '${upcomingTasks.length} ${AppLocalizations.of(context)!.taskCount}',
        icon: Icons.upcoming_rounded,
        color: AppColors.teal,
        count: upcomingTasks.length,
        tasks: upcomingTasks,
        showTime: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===== SLIVER APP BAR =====
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('Timeline',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textPrimary)),
          ),

          // ===== GLASS PROGRESS STATS =====
          SliverToBoxAdapter(
            child: _buildProgressStatsCard(context, todayTasks, doneToday, totalToday),
          ),

          // ===== QUICK FILTERS =====
          SliverToBoxAdapter(
            child: _buildQuickFilters(context),
          ),

          // ===== BRANCH TIMELINE =====
          SliverToBoxAdapter(
            child: _buildBranchTimeline(nodes),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  // ===== GLASS PROGRESS STATS =====
  Widget _buildProgressStatsCard(BuildContext context, List<Task> tasks, int done, int total) {
    final now = DateTime.now();
    final pct = total > 0 ? done / total : 0.0;

    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      blur: 12,
      opacity: 0.1,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.12),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.progressLabel,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM').format(now),
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0
                    ? AppColors.success
                    : pct > 0
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              // Percentage
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: pct >= 1.0
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$done/$total Task',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),

              // Badge: Đã xong
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.done,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge: Đang chờ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.pending,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== QUICK FILTERS =====
  Widget _buildQuickFilters(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(AppLocalizations.of(context)!.filterAll, null),
          _buildFilterChip(AppLocalizations.of(context)!.filterClass, TaskCategory.class_),
          _buildFilterChip(AppLocalizations.of(context)!.filterExam, TaskCategory.exam),
          _buildFilterChip(AppLocalizations.of(context)!.filterAssignment, TaskCategory.assignment),
          _buildFilterChip(AppLocalizations.of(context)!.filterPersonal, TaskCategory.personal),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskCategory? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textMuted),
        ),
      ),
    );
  }

  // ===== BRANCH TIMELINE =====
  Widget _buildBranchTimeline(List<_TimelineNode> nodes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(nodes.length, (i) {
          final node = nodes[i];
          final isFirst = i == 0;
          final isLast = i == nodes.length - 1;
          return _buildTimelineItem(node, isFirst, isLast);
        }),
      ),
    );
  }

  // ===== SINGLE TIMELINE ITEM (date + line + card) =====
  Widget _buildTimelineItem(_TimelineNode node, bool isFirst, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== LEFT: Date + task count =====
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    node.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${node.count} ${AppLocalizations.of(context)!.taskCount}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== CENTER: Vertical line + neon dot =====
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Top line (connect to previous)
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            node.color.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isFirst) const Spacer(),

                // Neon dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.color,
                    boxShadow: [
                      BoxShadow(
                        color: node.color.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Bottom line (connect to next)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            node.color.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isLast) const Spacer(),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ===== RIGHT: Glass content card =====
          Expanded(
            child: GlassContainer(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              blur: 12,
              opacity: 0.05,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header
                  Row(
                    children: [
                      Icon(node.icon, size: 15, color: node.color),
                      const SizedBox(width: 8),
                      Text(
                        node.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (node.count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: node.color.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '${node.count}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: node.color),
                          ),
                        ),
                      if (node.progress > 0) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: node.progress,
                              backgroundColor: AppColors.surfaceLight,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Card body: task list or empty state
                  if (node.tasks.isEmpty)
                    _buildBoxEmptyState(context)
                  else
                    ...node.tasks
                        .map((task) => _buildBoxTaskItem(task)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== BOX EMPTY STATE =====
  Widget _buildBoxEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 14, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.noSchedule,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ===== BOX TASK ITEM =====
  Widget _buildBoxTaskItem(Task task) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                  taskService: widget.taskService, task: task)),
        );
        if (result == true) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: task.isOverdue
                ? AppColors.error.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Category indicator
            Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: task.category.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: task.isDone
                            ? AppColors.textMuted
                            : (task.isOverdue
                                ? AppColors.error
                                : AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.dueTime != null) ...[
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: AppColors.textMuted.withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('HH:mm').format(task.dueTime!),
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.7)),
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today_rounded,
                            size: 11,
                            color: AppColors.textMuted.withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('dd/MM').format(task.dueDate!),
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.7)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Status
            if (task.isDone)
              Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.success)
            else if (task.isOverdue)
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.error)
            else
              Icon(Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: AppColors.textMuted.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  // ===== HELPERS =====
  List<Task> _getFilteredTasks() {
    final tasks = widget.taskService.tasks;
    if (_selectedCategory == null) return tasks;
    return tasks.where((t) => t.category == _selectedCategory).toList();
  }

  bool _isToday(DateTime? date, DateTime now) {
    if (date == null) return false;
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime? date, DateTime now) {
    if (date == null) return false;
    final tomorrow = now.add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  bool _isThisWeek(DateTime? date, DateTime now) {
    if (date == null) return false;
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    return date.isAfter(now) && date.isBefore(weekEnd);
  }

  int _sortByTime(Task a, Task b) {
    if (a.dueTime == null && b.dueTime == null) return 0;
    if (a.dueTime == null) return 1;
    if (b.dueTime == null) return -1;
    return a.dueTime!.compareTo(b.dueTime!);
  }
}

// ===== TIMELINE NODE DATA =====
class _TimelineNode {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final double progress;
  final List<Task> tasks;
  final bool showTime;

  const _TimelineNode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.count = 0,
    this.progress = 0,
    this.tasks = const [],
    this.showTime = false,
  });
}
