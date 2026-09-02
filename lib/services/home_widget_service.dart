import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'dart:developer' as developer;

class HomeWidgetService {
  static const String _androidWidgetName = 'com.example.super_note.WidgetProvider';
  static const String _androidQuickTaskWidgetName = 'com.example.super_note.QuickTaskWidgetProvider';
  static const String _androidProgressWidgetName = 'com.example.super_note.ProgressWidgetProvider';

  static const String _keyTodayTasks = 'today_tasks';
  static const String _keyTodayCount = 'today_count';
  static const String _keyDoneCount = 'today_done_count';
  static const String _keyProgressPercent = 'today_progress_percent';
  static const String _keyClockTime = 'clock_time';
  static const String _keyClockDate = 'clock_date';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId('group.com.example.super_note');
    } catch (e) {
      developer.log('HomeWidget init failed', error: e, name: 'HomeWidgetService');
    }
  }

  Future<void> updateWidgets(List<Task> allTasks) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayTasks = allTasks.where((t) {
        if (t.dueDate == null) return false;
        final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return taskDate.isAtSameMomentAs(today);
      }).toList()
        ..sort((a, b) {
          if (a.dueTime == null && b.dueTime == null) return 0;
          if (a.dueTime == null) return 1;
          if (b.dueTime == null) return -1;
          return a.dueTime!.compareTo(b.dueTime!);
        });

      final doneCount = todayTasks.where((t) => t.isDone).length;
      final totalCount = todayTasks.length;
      final progress = totalCount > 0 ? (doneCount / totalCount * 100).round() : 0;

      // Limit to 5 tasks for widget display
      final displayTasks = todayTasks.take(5).toList();
      final tasksJson = displayTasks.map((t) => jsonEncode({
        'id': t.id,
        'title': t.title,
        'isDone': t.isDone,
        'category': t.category.name,
        'categoryLabel': t.category.label,
        'categoryColor': t.category.color.toARGB32().toRadixString(16).padLeft(8, '0'),
        'dueTime': t.dueTime != null ? DateFormat('HH:mm').format(t.dueTime!) : '',
        'isOverdue': t.isOverdue,
      })).toList();

      // Save data for all widget types
      await Future.wait([
        HomeWidget.saveWidgetData<String>(_keyTodayTasks, jsonEncode(tasksJson)),
        HomeWidget.saveWidgetData<String>(_keyTodayCount, '$totalCount'),
        HomeWidget.saveWidgetData<String>(_keyDoneCount, '$doneCount'),
        HomeWidget.saveWidgetData<String>(_keyProgressPercent, '$progress'),
        HomeWidget.saveWidgetData<String>(_keyClockTime, DateFormat('HH:mm').format(now)),
        HomeWidget.saveWidgetData<String>(_keyClockDate, DateFormat('dd/MM/yyyy').format(now)),
      ]);

      // Update all widget types
      await Future.wait([
        HomeWidget.updateWidget(
          qualifiedAndroidName: _androidWidgetName,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: _androidQuickTaskWidgetName,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: _androidProgressWidgetName,
        ),
      ]);

      developer.log('Widgets updated: $totalCount tasks, $doneCount done, $progress%', name: 'HomeWidgetService');
    } catch (e) {
      developer.log('Widget update failed', error: e, name: 'HomeWidgetService');
    }
  }

  static void onQuickAddTap() {
    developer.log('Quick add tapped from widget', name: 'HomeWidgetService');
  }

  static void onTaskToggle(String taskId) {
    developer.log('Task toggle from widget: $taskId', name: 'HomeWidgetService');
  }
}
