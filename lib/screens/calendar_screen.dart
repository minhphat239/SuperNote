import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class CalendarScreen extends StatefulWidget {
  final TaskService taskService;

  const CalendarScreen({super.key, required this.taskService});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: const Text('Lịch',
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
                  label: Text('Hôm nay',
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
                      '${_getTasksForDay(_selectedDay).length} việc',
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
                            ? AppColors.primary
                            : isToday
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
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
                                  ? Colors.white
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
                                        ? Colors.white.withValues(alpha: 0.8)
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
                                          ? Colors.white.withValues(alpha: 0.6)
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
                                            ? Colors.white.withValues(alpha: 0.7)
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
                    const Text(
                      'Công việc sắp tới',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${upcomingTasks.length} việc',
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
                        'Không có task nào sắp tới',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 16),
                      // Quick action button
                      GestureDetector(
                        onTap: () {
                          // Navigate to task creation (placeholder)
                        },
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
                                'Thêm task cho ngày này',
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
            _buildTimeSlotHeader('Buổi sáng', Icons.wb_sunny_rounded, AppColors.orange),
            ...morning.map((t) => _buildEventCard(t)),
            const SizedBox(height: 8),
          ],
          if (afternoon.isNotEmpty) ...[
            _buildTimeSlotHeader('Buổi chiều', Icons.wb_cloudy_rounded, AppColors.blue),
            ...afternoon.map((t) => _buildEventCard(t)),
            const SizedBox(height: 8),
          ],
          if (evening.isNotEmpty) ...[
            _buildTimeSlotHeader('Buổi tối', Icons.nightlight_round, AppColors.purple),
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
      dateLabel = 'Hôm nay';
    } else if (daysDiff == 1) {
      dateLabel = 'Ngày mai';
    } else if (daysDiff < 7) {
      dateLabel = 'Còn $daysDiff ngày';
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
                  'Cả ngày',
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
      case 1: dayOfWeek = 'Thứ Hai'; break;
      case 2: dayOfWeek = 'Thứ Ba'; break;
      case 3: dayOfWeek = 'Thứ Tư'; break;
      case 4: dayOfWeek = 'Thứ Năm'; break;
      case 5: dayOfWeek = 'Thứ Sáu'; break;
      case 6: dayOfWeek = 'Thứ Bảy'; break;
      case 7: dayOfWeek = 'Chủ Nhật'; break;
      default: dayOfWeek = '';
    }

    final monthNames = [
      '', 'tháng 1', 'tháng 2', 'tháng 3', 'tháng 4',
      'tháng 5', 'tháng 6', 'tháng 7', 'tháng 8',
      'tháng 9', 'tháng 10', 'tháng 11', 'tháng 12'
    ];

    if (daysDiff == 0) {
      return 'Hôm nay, ${date.day} ${monthNames[date.month]}, ${date.year}';
    } else if (daysDiff == 1) {
      return 'Ngày mai, ${date.day} ${monthNames[date.month]}, ${date.year}';
    } else if (daysDiff == -1) {
      return 'Hôm qua, ${date.day} ${monthNames[date.month]}, ${date.year}';
    }

    return '$dayOfWeek, ${date.day} ${monthNames[date.month]}, ${date.year}';
  }
}
