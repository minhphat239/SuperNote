import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

// ===== WEEKLY CALENDAR STRIP (72px) =====
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

  @override
  void didUpdateWidget(WeeklyCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
      _weekDays = _getWeekDays(_selectedDate);
    }
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(
        7, (i) => DateTime(start.year, start.month, start.day + i));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final dayNames = [l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu, l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun];

    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
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
          final isWeekend = i >= 5; // T7 (index 5) and CN (index 6)

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
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNames[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : isWeekend
                                ? const Color(0xFFFF8A8A).withValues(alpha: 0.7)
                                : AppColors.textMuted.withValues(alpha: 0.6),
                        letterSpacing: (Localizations.localeOf(context).languageCode == 'vi' && i == 6) ? 0.5 : 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : (isToday
                                ? AppColors.primary
                                : isWeekend
                                    ? const Color(0xFFFF8A8A)
                                    : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (taskCount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          taskCount.clamp(0, 3),
                          (j) => Container(
                            width: 3,
                            height: 3,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.8)
                                  : AppColors.primary.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 3),
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
