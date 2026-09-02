import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/task_service.dart';

enum StatLevel { day, week, month }

class StatsScreen extends StatefulWidget {
  final TaskService taskService;
  const StatsScreen({super.key, required this.taskService});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatLevel _level = StatLevel.week;
  List<Task> _tasks = [];
  StreamSubscription<List<Task>>? _sub;

  @override
  void initState() {
    super.initState();
    _tasks = widget.taskService.tasks;
    _sub = widget.taskService.taskStream.listen((tasks) {
      if (mounted) setState(() => _tasks = tasks);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(AppLocalizations.of(context)!.statsTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.md),
                _buildLeverSegment(),
                const SizedBox(height: AppSpacing.lg),
                _buildChartCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildSummaryRow(),
                const SizedBox(height: AppSpacing.lg),
                _buildCategoryBreakdown(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeverSegment() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: StatLevel.values.map((level) {
              final isSelected = _level == level;
              final l10n = AppLocalizations.of(context)!;
              final label = level == StatLevel.day
                  ? l10n.statsDay
                  : level == StatLevel.week
                      ? l10n.statsWeek
                      : l10n.statsMonth;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _level = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final spots = _generateSpotsFromTasks();
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _level == StatLevel.day
                        ? l10n.statsToday
                        : _level == StatLevel.week
                            ? l10n.statsThisWeek
                            : l10n.statsThisMonth,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: spots.isEmpty
                    ? Center(
                        child: Text(l10n.noTask, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white.withValues(alpha: 0.05),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final labels = _getLabels();
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= labels.length) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(labels[idx],
                                        style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.6))),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(),
                                      style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.6)));
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.background,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.3),
                                    AppColors.primary.withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final completed = _tasks.where((t) => t.isDone).length;
    final pending = _tasks.where((t) => !t.isDone).length;
    final rate = _tasks.isNotEmpty ? (completed / _tasks.length * 100).round() : 0;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _buildSummaryItem(Icons.check_circle_rounded, '$completed', l10n.statsCompleted, AppColors.success),
        const SizedBox(width: 8),
        _buildSummaryItem(Icons.pending_rounded, '$pending', l10n.statsRemaining, AppColors.warning),
        const SizedBox(width: 8),
        _buildSummaryItem(Icons.percent_rounded, '$rate%', l10n.statsRate, AppColors.primary),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final l10n = AppLocalizations.of(context)!;
    final categories = [
      (l10n.filterClass, AppColors.blue, _tasks.where((t) => t.category.name == 'class_').length),
      (l10n.filterExam, AppColors.red, _tasks.where((t) => t.category.name == 'exam').length),
      (l10n.filterAssignment, AppColors.orange, _tasks.where((t) => t.category.name == 'assignment').length),
      (l10n.filterPersonal, AppColors.green, _tasks.where((t) => t.category.name == 'personal').length),
    ];
    final total = _tasks.isEmpty ? 1 : _tasks.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(l10n.statsCategory, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              ...categories.map((c) {
                final pct = (c.$3 / total * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c.$1, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.$2)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.$3 / total,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(c.$2),
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
    );
  }

  List<FlSpot> _generateSpotsFromTasks() {
    final now = DateTime.now();

    switch (_level) {
      case StatLevel.day:
        final counts = List.filled(24, 0);
        for (final t in _tasks) {
          if (t.dueDate != null &&
              t.dueDate!.year == now.year &&
              t.dueDate!.month == now.month &&
              t.dueDate!.day == now.day) {
            counts[t.dueDate!.hour]++;
          }
          if (t.dueTime != null &&
              t.dueTime!.year == now.year &&
              t.dueTime!.month == now.month &&
              t.dueTime!.day == now.day) {
            counts[t.dueTime!.hour]++;
          }
        }
        final spots = <FlSpot>[];
        for (var i = 0; i < 24; i++) {
          spots.add(FlSpot(i.toDouble(), counts[i].toDouble()));
        }
        return spots;

      case StatLevel.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final counts = List.filled(7, 0);
        for (final t in _tasks) {
          final dd = t.deadline;
          if (dd != null && dd.isAfter(startOfWeek.subtract(const Duration(days: 1))) && dd.isBefore(endOfWeek)) {
            final dayIdx = dd.weekday - 1;
            if (dayIdx >= 0 && dayIdx < 7) counts[dayIdx]++;
          }
        }
        return List.generate(7, (i) => FlSpot(i.toDouble(), counts[i].toDouble()));

      case StatLevel.month:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final counts = List.filled(daysInMonth, 0);
        for (final t in _tasks) {
          final dd = t.deadline;
          if (dd != null && dd.isAfter(startOfMonth.subtract(const Duration(days: 1))) && dd.isBefore(DateTime(now.year, now.month + 1))) {
            final dayIdx = dd.day - 1;
            if (dayIdx >= 0 && dayIdx < daysInMonth) counts[dayIdx]++;
          }
        }
        return List.generate(daysInMonth, (i) => FlSpot(i.toDouble(), counts[i].toDouble()));
    }
  }

  List<String> _getLabels() {
    switch (_level) {
      case StatLevel.day:
        return ['0h', '4h', '8h', '12h', '16h', '20h', '24h'];
      case StatLevel.week:
        final l10n = AppLocalizations.of(context)!;
        return [l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];
      case StatLevel.month:
        return List.generate(30, (i) => '${i + 1}');
    }
  }
}
