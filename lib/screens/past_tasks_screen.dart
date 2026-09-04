import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/task_service.dart';

enum _FilterStatus { completed, missed, pastEvents }

class PastTasksScreen extends StatefulWidget {
  final TaskService taskService;

  const PastTasksScreen({super.key, required this.taskService});

  @override
  State<PastTasksScreen> createState() => _PastTasksScreenState();
}

class _PastTasksScreenState extends State<PastTasksScreen> with SingleTickerProviderStateMixin {
  _FilterStatus _filterStatus = _FilterStatus.completed;
  late TabController _tabController;
  StreamSubscription<List<Task>>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _taskSubscription = widget.taskService.taskStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _getFilteredTasks(_FilterStatus status) {
    final now = DateTime.now();
    final allTasks = widget.taskService.tasks;

    switch (status) {
      case _FilterStatus.completed:
        return allTasks.where((t) => t.status == TaskStatus.done).toList();
      case _FilterStatus.missed:
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return allTasks.where((t) => t.status != TaskStatus.done && t.dueDate != null && t.dueDate!.isBefore(todayEnd)).toList();
      case _FilterStatus.pastEvents:
        return allTasks.where((t) => t.repeatRule != null).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _getFilteredTasks(_FilterStatus.completed);
    final missed = _getFilteredTasks(_FilterStatus.missed);
    final events = _getFilteredTasks(_FilterStatus.pastEvents);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ===== GLASS APP BAR =====
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                          child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pastTasksTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.pastTasksHistory,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Stats badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${completed.length + missed.length} ${AppLocalizations.of(context)!.taskCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== STATUS FILTERS =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.completed,
                    icon: Icons.check_circle_rounded,
                    status: _FilterStatus.completed,
                    color: AppColors.success,
                    count: completed.length,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.missed,
                    icon: Icons.warning_amber_rounded,
                    status: _FilterStatus.missed,
                    color: AppColors.error,
                    count: missed.length,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.pastEvents,
                    icon: Icons.event_rounded,
                    status: _FilterStatus.pastEvents,
                    color: AppColors.orange,
                    count: events.length,
                  ),
                ],
              ),
            ),

            // ===== SUB TABS =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(icon: const Icon(Icons.timeline_rounded, size: 16), text: AppLocalizations.of(context)!.byDay),
                  Tab(icon: const Icon(Icons.bar_chart_rounded, size: 16), text: AppLocalizations.of(context)!.statistics),
                ],
              ),
            ),

            // ===== CONTENT =====
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimelineTab(),
                  _buildAnalyticsTab(completed, missed, events),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required _FilterStatus status,
    required Color color,
    required int count,
  }) {
    final isSelected = _filterStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    final tasks = _getFilteredTasks(_filterStatus);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textMuted.withValues(alpha: 0.06),
              ),
                  child: Icon(Icons.history_rounded, size: 28,
                    color: AppColors.textMuted.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noPastTasks,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date descending
    tasks.sort((a, b) => (b.dueDate ?? DateTime.now()).compareTo(a.dueDate ?? DateTime.now()));

    // Group by date
    final groups = <String, List<Task>>{};
    for (final task in tasks) {
      final key = task.dueDate != null
          ? DateFormat('dd/MM/yyyy', 'vi').format(task.dueDate!)
          : AppLocalizations.of(context)!.noDateLabel;
      groups.putIfAbsent(key, () => []).add(task);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: groups.length,
      itemBuilder: (ctx, i) {
        final entry = groups.entries.elementAt(i);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ),
            ...entry.value.map((t) => _buildPastTaskCard(t)),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsTab(List<Task> completed, List<Task> missed, List<Task> events) {
    final total = completed.length + missed.length;
    final completionRate = total > 0 ? completed.length / total : 0.0;

    // Group by category
    final byCategory = <TaskCategory, int>{};
    for (final t in [...completed, ...missed]) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Overall completion rate
        _buildStatCard(
          title: AppLocalizations.of(context)!.completionRate,
          value: '${(completionRate * 100).round()}%',
          subtitle: AppLocalizations.of(context)!.completedOf,
          color: completionRate >= 0.7 ? AppColors.success : completionRate >= 0.4 ? AppColors.orange : AppColors.error,
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: 12),

        // Missed count
        _buildStatCard(
          title: AppLocalizations.of(context)!.missedCount,
          value: '${missed.length}',
          subtitle: AppLocalizations.of(context)!.missedDesc,
          color: AppColors.error,
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 12),

        // Past events
        _buildStatCard(
          title: AppLocalizations.of(context)!.pastEventsCount,
          value: '${events.length}',
          subtitle: AppLocalizations.of(context)!.pastEventsDesc,
          color: AppColors.orange,
          icon: Icons.event_rounded,
        ),
        const SizedBox(height: 16),

        // Category breakdown
        if (byCategory.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.categoryBreakdown,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...byCategory.entries.map((e) {
                      final pct = total > 0 ? e.value / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: e.key.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.key.label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Container(
                              width: 80,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: pct,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: e.key.color.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${(pct * 100).round()}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: e.key.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastTaskCard(Task task) {
    final isOverdue = task.isOverdue;
    final statusColor = task.status == TaskStatus.done ? AppColors.success : isOverdue ? AppColors.error : AppColors.textMuted;

    return GestureDetector(
      onTap: () {},
      onLongPress: () => _showTaskOptions(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: task.category.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
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
                      color: task.status == TaskStatus.done
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text(
                        task.dueDate != null ? DateFormat('dd/MM', 'vi').format(task.dueDate!) : '--',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.6)),
                      ),
                      if (task.dueTime != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.access_time_rounded, size: 10, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('HH:mm').format(task.dueTime!),
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.6)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              task.status == TaskStatus.done ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              size: 18,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskOptions(Task task) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${task.title}"',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  if (task.status != TaskStatus.done)
                    _buildDialogOption(
                      icon: Icons.check_circle_rounded,
                      label: AppLocalizations.of(context)!.markCompleted,
                      color: AppColors.success,
                      onTap: () async {
                        await widget.taskService.toggleTask(task.id);
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  _buildDialogOption(
                    icon: Icons.restore_rounded,
                    label: AppLocalizations.of(context)!.reactivate,
                    color: AppColors.primary,
                    onTap: () async {
                      final newDate = DateTime.now().add(const Duration(days: 1));
                      await widget.taskService.updateTask(
                        task.id,
                        dueDate: newDate,
                        status: TaskStatus.pending,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  _buildDialogOption(
                    icon: Icons.delete_outline_rounded,
                    label: AppLocalizations.of(context)!.deletePermanently,
                    color: AppColors.error,
                    onTap: () async {
                      await widget.taskService.deleteTask(task.id);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
