import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/feedback_service.dart';
import '../l10n/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  final TaskService taskService;

  const CalendarScreen({super.key, required this.taskService});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
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

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AddTaskDialog(selectedDate: _selectedDay, taskService: widget.taskService),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(AppLocalizations.of(context)!.calendarTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.textPrimary)),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime.now();
                      _selectedDay = DateTime.now();
                    });
                  },
                  icon: Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.primary),
                  label: Text(AppLocalizations.of(context)!.today,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ===== BLUR GLASS MINI MONTH =====
            SliverToBoxAdapter(
              child: _buildBlurGlassMiniMonth(),
            ),

            // ===== SELECTED DAY HEADER =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatVietnameseDate(_selectedDay),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${_getTasksForDay(_selectedDay).length} ${AppLocalizations.of(context)!.taskCount}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // ===== TASK LIST OR UPCOMING TASKS =====
            _buildTaskSection(_selectedDay),
          ],
        ),
            // FAB
            Positioned(
              bottom: 80,
              right: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openAddTaskDialog,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradient.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== BLUR GLASS MINI MONTH =====
  Widget _buildBlurGlassMiniMonth() {
    final now = DateTime.now();
    final year = _focusedDay.year;
    final month = _focusedDay.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Month/Year header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(year, month - 1);
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'vi').format(_focusedDay),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(year, month + 1);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Weekday headers
              Row(
                children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 4),

              // Day grid with dots
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 0,
                ),
                itemCount: (firstWeekday - 1) + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstWeekday - 1) return const SizedBox();
                  final day = index - (firstWeekday - 1) + 1;
                  final date = DateTime(year, month, day);
                  final isToday = _isSameDay(date, now);
                  final isSelected = _isSameDay(date, _selectedDay);
                  final tasksForDay = _getTasksForDay(date);
                  final hasTasks = tasksForDay.isNotEmpty;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = date),
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              )
                            : isToday
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : isToday
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      spreadRadius: -1,
                                    ),
                                  ]
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          // Event dots (4px)
                          if (hasTasks)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (tasksForDay.length > 1) ...[
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.5)
                                          : AppColors.warning.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                if (tasksForDay.length > 2)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Text(
                                      '+${tasksForDay.length - 2}',
                                      style: TextStyle(
                                        fontSize: 7,
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.7)
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else
                            const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== TASK SECTION =====
  Widget _buildTaskSection(DateTime day) {
    final tasks = _getTasksForDay(day);

    if (tasks.isEmpty) {
      final upcomingTasks = _getUpcomingTasks(7);

      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upcoming tasks
            if (upcomingTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.upcomingTasks,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${upcomingTasks.length} ${AppLocalizations.of(context)!.taskCount}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ...upcomingTasks.map((task) => _buildUpcomingCard(task)),
              const SizedBox(height: 16),
            ],

            // No tasks at all — empty state with quick action
            if (upcomingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_today_rounded,
                            size: 28,
                            color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppLocalizations.of(context)!.noUpcoming,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 16),
                      // Quick action button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openAddTaskDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 16, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!.addTaskForDay,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Has tasks: group by time slots
    final morning = tasks.where((t) {
      if (t.dueTime == null) return true;
      return t.dueTime!.hour < 12;
    }).toList();

    final afternoon = tasks.where((t) {
      if (t.dueTime == null) return false;
      return t.dueTime!.hour >= 12 && t.dueTime!.hour < 18;
    }).toList();

    final evening = tasks.where((t) {
      if (t.dueTime == null) return false;
      return t.dueTime!.hour >= 18;
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (morning.isNotEmpty) ...[
            _buildTimeSlotHeader(AppLocalizations.of(context)!.morning, Icons.wb_sunny_rounded, AppColors.orange),
            ...morning.map((t) => _buildEventCard(t)),
            const SizedBox(height: 8),
          ],
          if (afternoon.isNotEmpty) ...[
            _buildTimeSlotHeader(AppLocalizations.of(context)!.afternoon, Icons.wb_cloudy_rounded, AppColors.blue),
            ...afternoon.map((t) => _buildEventCard(t)),
            const SizedBox(height: 8),
          ],
          if (evening.isNotEmpty) ...[
            _buildTimeSlotHeader(AppLocalizations.of(context)!.evening, Icons.nightlight_round, AppColors.purple),
            ...evening.map((t) => _buildEventCard(t)),
          ],
        ]),
      ),
    );
  }

  // ===== UPCOMING TASK CARD (compact with date badge + category tag) =====
  Widget _buildUpcomingCard(Task task) {
    final now = DateTime.now();
    final taskDate = task.dueDate!;
    final daysDiff = taskDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    String dateLabel;
    if (daysDiff == 0) {
      dateLabel = AppLocalizations.of(context)!.today;
    } else if (daysDiff == 1) {
      dateLabel = AppLocalizations.of(context)!.tomorrow;
    } else if (daysDiff < 7) {
      dateLabel = AppLocalizations.of(context)!.daysLeft(daysDiff);
    } else {
      dateLabel = DateFormat('dd/MM').format(taskDate);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Date/time badge (left)
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: task.category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Text(
                  task.dueTime != null
                      ? DateFormat('HH:mm').format(task.dueTime!)
                      : dateLabel.split(' ').last,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: task.category.color),
                ),
                if (task.dueTime == null)
                  Text(
                    dateLabel,
                    style: TextStyle(
                        fontSize: 7,
                        color: task.category.color.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: task.isOverdue
                            ? AppColors.error
                            : AppColors.textPrimary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // Date label
                    Icon(Icons.calendar_today_rounded,
                        size: 10, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(width: 3),
                    Text(dateLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted.withValues(alpha: 0.7))),
                    if (task.dueTime != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.access_time_rounded,
                          size: 10, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text(DateFormat('HH:mm').format(task.dueTime!),
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted.withValues(alpha: 0.7))),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: task.category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              task.category.label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: task.category.color),
            ),
          ),
          const SizedBox(width: 6),

          Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.textMuted.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildTimeSlotHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(height: 1, color: color.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Time column
          if (task.dueTime != null)
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: task.category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  DateFormat('HH:mm').format(task.dueTime!),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: task.category.color),
                ),
              ),
            )
          else
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.allDay,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                ),
              ),
            ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: task.isOverdue ? AppColors.error : AppColors.textPrimary)),
                if (task.description.isNotEmpty)
                  Text(task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.7))),
              ],
            ),
          ),

          // Category dot
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: task.category.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),

          Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.textMuted.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  // ===== HELPERS =====
  List<Task> _getTasksForDay(DateTime day) {
    final tasks = widget.taskService.tasks;
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final target = DateTime(day.year, day.month, day.day);
      return taskDate.isAtSameMomentAs(target) && task.status != TaskStatus.done;
    }).toList();
  }

  List<Task> _getUpcomingTasks(int limit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tasks = widget.taskService.tasks;

    final upcoming = tasks.where((task) {
      if (task.dueDate == null) return false;
      if (task.status == TaskStatus.done) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(today);
    }).toList();

    upcoming.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return upcoming.take(limit).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatVietnameseDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final daysDiff = target.difference(today).inDays;

    String dayOfWeek;
    switch (date.weekday) {
      case 1: dayOfWeek = AppLocalizations.of(context)!.monday; break;
      case 2: dayOfWeek = AppLocalizations.of(context)!.tuesday; break;
      case 3: dayOfWeek = AppLocalizations.of(context)!.wednesday; break;
      case 4: dayOfWeek = AppLocalizations.of(context)!.thursday; break;
      case 5: dayOfWeek = AppLocalizations.of(context)!.friday; break;
      case 6: dayOfWeek = AppLocalizations.of(context)!.saturday; break;
      case 7: dayOfWeek = AppLocalizations.of(context)!.sunday; break;
      default: dayOfWeek = '';
    }

    final l10n = AppLocalizations.of(context)!;
    final monthNames = [
      '', l10n.month1, l10n.month2, l10n.month3, l10n.month4,
      l10n.month5, l10n.month6, l10n.month7, l10n.month8,
      l10n.month9, l10n.month10, l10n.month11, l10n.month12
    ];

    final dateStr = '${date.day} ${monthNames[date.month]}, ${date.year}';
    if (daysDiff == 0) {
      return l10n.todayDate(dateStr);
    } else if (daysDiff == 1) {
      return l10n.tomorrowDate(dateStr);
    } else if (daysDiff == -1) {
      return l10n.yesterdayDate(dateStr);
    }

    return '$dayOfWeek, ${date.day} ${monthNames[date.month]}, ${date.year}';
  }
}

// ===== QUICK ADD TASK DIALOG =====
class _AddTaskDialog extends StatefulWidget {
  final DateTime selectedDate;
  final TaskService taskService;

  const _AddTaskDialog({required this.selectedDate, required this.taskService});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _dueTime;
  TaskCategory _category = TaskCategory.personal;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    await widget.taskService.addTask(
      title: title,
      noteContent: _noteCtrl.text.trim(),
      dueDate: widget.selectedDate,
      dueTime: _dueTime,
      category: _category,
    );
    FeedbackService().trigger(FeedbackType.complete);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueTime = DateTime(2000, 1, 1, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: Icon(Icons.add_rounded,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.addNewTask,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy', 'vi').format(widget.selectedDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title input
                  TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.taskTitleHint,
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notes
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.notesOptional,
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time + Category row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _dueTime != null
                                      ? DateFormat('HH:mm').format(_dueTime!)
                                       : AppLocalizations.of(context)!.setTime,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _dueTime != null
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Category selector
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCategoryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _category.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _category.color.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(_categoryIcon(_category),
                                    size: 16, color: _category.color),
                                const SizedBox(width: 6),
                                Text(
                                  _category.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _category.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: AppGradient.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.saveTask,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.class_: return Icons.school_rounded;
      case TaskCategory.exam: return Icons.quiz_rounded;
      case TaskCategory.assignment: return Icons.assignment_rounded;
      case TaskCategory.personal: return Icons.person_rounded;
    }
  }

  void _showCategoryPicker() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                children: TaskCategory.values.map((cat) {
                  final isSelected = cat == _category;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _category = cat);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_categoryIcon(cat), size: 18, color: cat.color),
                          const SizedBox(width: 10),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? cat.color : AppColors.textPrimary,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            Icon(Icons.check_circle_rounded,
                                size: 18, color: cat.color),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
