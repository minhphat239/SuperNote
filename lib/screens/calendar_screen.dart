import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../screens/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final TaskService taskService;

  const CalendarScreen({super.key, required this.taskService});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('Calendar',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.today,
                    size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: TableCalendar<Task>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getTasksForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(
                    color: AppColors.textPrimary),
                weekendTextStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.7)),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary),
                leftChevronIcon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textSecondary),
                rightChevronIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
                formatButtonTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                  DateFormat('EEEE, MMMM d')
                      .format(_selectedDay),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted)),
            ),
          ),
          _buildTaskListForDay(_selectedDay),
        ],
      ),
    );
  }

  List<Task> _getTasksForDay(DateTime day) {
    final tasks = widget.taskService.tasks;
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year,
          task.dueDate!.month, task.dueDate!.day);
      return isSameDay(taskDate, day) &&
          task.status != TaskStatus.done;
    }).toList();
  }

  Widget _buildTaskListForDay(DateTime day) {
    final tasks = _getTasksForDay(day);

    if (tasks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available_rounded,
                  size: 48,
                  color:
                      AppColors.textMuted.withOpacity(0.15)),
              const SizedBox(height: 12),
              Text(
                'No tasks on ${DateFormat('MMM d').format(day)}',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted
                        .withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final task = tasks[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: task.category.color,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: task.isOverdue
                                    ? AppColors.error
                                    : AppColors
                                        .textPrimary)),
                        if (task.dueTime != null)
                          Text(
                              DateFormat('HH:mm')
                                  .format(task.dueTime!),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted
                                      .withOpacity(0.7))),
                      ],
                    ),
                  ),
                  if (task.hasNote)
                    Icon(Icons.note_alt_outlined,
                        size: 14,
                        color: AppColors.primary
                            .withOpacity(0.5)),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textMuted
                            .withOpacity(0.4)),
                    onPressed: () async {
                      final result =
                          await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                TaskDetailScreen(
                                    taskService:
                                        widget.taskService,
                                    task: task)),
                      );
                      if (result == true) setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
          childCount: tasks.length,
        ),
      ),
    );
  }
}
