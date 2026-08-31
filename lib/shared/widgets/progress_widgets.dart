import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ===== DAILY PROGRESS WIDGET =====
class DailyProgressWidget extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;

  const DailyProgressWidget(
      {super.key, required this.totalTasks, required this.completedTasks});

  @override
  Widget build(BuildContext context) {
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final percentage = (progress * 100).round();
    final quote = _getMotivationalQuote(percentage);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Daily Progress',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted.withOpacity(0.8))),
              const Spacer(),
              Text('$percentage%',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.3
                    ? AppColors.error
                    : (progress < 0.7 ? AppColors.orange : AppColors.success),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(quote,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted.withOpacity(0.6),
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  String _getMotivationalQuote(int percentage) {
    if (percentage == 0) {
      return "Let's get started! Every journey begins with a single step.";
    }
    if (percentage < 30) return "Good start! Keep the momentum going.";
    if (percentage < 50) return "You're making progress. Stay focused!";
    if (percentage < 70) return "More than halfway there. You got this!";
    if (percentage < 100) return "Almost done! Finish strong!";
    return "All tasks completed! You're a superstar!";
  }
}

// ===== WEEKLY CALENDAR STRIP =====
class WeeklyCalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<int, int> taskCounts;

  const WeeklyCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.taskCounts = const {},
  });

  @override
  State<WeeklyCalendarStrip> createState() => _WeeklyCalendarStripState();
}

class _WeeklyCalendarStripState extends State<WeeklyCalendarStrip> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _weekDays = _getWeekDays(_selectedDate);
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(
        7, (i) => DateTime(start.year, start.month, start.day + i));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: List.generate(7, (i) {
          final day = _weekDays[i];
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final taskCount = widget.taskCounts[day.day] ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDate = day);
                widget.onDateSelected(day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : isToday
                          ? Colors.white.withOpacity(0.06)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday
                            ? AppColors.primary.withOpacity(0.3)
                            : Colors.white.withOpacity(0.06)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: -2)
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNames[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : (isToday
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (taskCount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          taskCount.clamp(0, 3),
                          (j) => Container(
                            width: 4,
                            height: 4,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
