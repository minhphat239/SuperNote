import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'nlp_service.dart';
import 'notification_service.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  List<Task> _tasks = [];
  final NotificationService _notificationService = NotificationService();

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.done).toList();
  List<Task> get snoozedTasks =>
      _tasks.where((t) => t.status == TaskStatus.snoozed).toList();

  Future<void> init() async {
    await _loadTasks();
    await _notificationService.init();
    _setupNotificationHandlers();
    await _rescheduleAllNotifications();
  }

  void _setupNotificationHandlers() {
    _notificationService.onNotificationTapped = (taskId) {};
    _notificationService.onNotificationAction = (taskId, action) async {
      if (action == 'done') {
        await toggleTask(taskId);
      } else if (action == 'snooze') {
        await snoozeTask(taskId, const Duration(minutes: 30));
      }
    };
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tasksKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _tasks = list.map((e) => Task.fromMap(e)).toList();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _tasks.map((e) => e.toMap()).toList();
    await prefs.setString(_tasksKey, jsonEncode(data));
  }

  NlpPreview getNlpPreview(String input) {
    return NlpService.parse(input);
  }

  Future<Task> addTaskFromNlp(String input) async {
    final preview = NlpService.parse(input);

    TaskCategory category = preview.category ?? TaskCategory.personal;
    for (final tag in preview.tags) {
      final lower = tag.toLowerCase();
      if (lower == 'class' || lower == 'hoc' || lower == 'lop') {
        category = TaskCategory.class_;
        break;
      }
      if (lower == 'exam' || lower == 'thi' || lower == 'kythi') {
        category = TaskCategory.exam;
        break;
      }
      if (lower == 'assignment' ||
          lower == 'baitap' ||
          lower == 'homework' ||
          lower == 'bt') {
        category = TaskCategory.assignment;
        break;
      }
      if (lower == 'personal' || lower == 'canhan' || lower == 'rieng') {
        category = TaskCategory.personal;
        break;
      }
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: preview.title,
      dueDate: preview.dueDate,
      dueTime: preview.dueTime,
      category: category,
      repeatRule: preview.repeatRule,
      repeatEndDate: preview.repeatEndDate,
      preReminderOffset: preview.preReminderOffset,
      status: TaskStatus.pending,
    );

    _tasks.insert(0, task);
    await _saveTasks();
    await _notificationService.scheduleTaskNotification(task);
    return task;
  }

  Future<Task> addTask({
    required String title,
    String description = '',
    String noteContent = '',
    List<SubTask>? subtasks,
    DateTime? dueDate,
    DateTime? dueTime,
    TaskCategory? category,
    String? repeatRule,
    DateTime? repeatEndDate,
    int? preReminderOffset,
  }) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      noteContent: noteContent,
      subtasks: subtasks,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category ?? TaskCategory.personal,
      repeatRule: repeatRule,
      repeatEndDate: repeatEndDate,
      preReminderOffset: preReminderOffset,
      status: TaskStatus.pending,
    );

    _tasks.insert(0, task);
    await _saveTasks();
    await _notificationService.scheduleTaskNotification(task);
    return task;
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final current = _tasks[index];
      final newStatus =
          current.isDone ? TaskStatus.pending : TaskStatus.done;
      _tasks[index] = current.copyWith(status: newStatus);
      await _saveTasks();

      if (newStatus == TaskStatus.done) {
        await _notificationService.cancelTaskNotifications(current);
        if (current.repeatRule != null && current.repeatRule!.isNotEmpty) {
          await _createNextOccurrence(current);
        }
      } else {
        await _notificationService.scheduleTaskNotification(current);
      }
    }
  }

  Future<void> _createNextOccurrence(Task task) async {
    final nextDueDate = _calculateNextDueDate(task);
    if (nextDueDate == null) return;

    if (task.repeatEndDate != null &&
        nextDueDate.isAfter(task.repeatEndDate!)) {
      return;
    }

    final nextTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: task.title,
      description: task.description,
      noteContent: task.noteContent,
      subtasks: task.subtasks
          .map((s) => SubTask(
              id: s.id, title: s.title, isDone: false))
          .toList(),
      dueDate: nextDueDate,
      dueTime: task.dueTime,
      category: task.category,
      repeatRule: task.repeatRule,
      repeatEndDate: task.repeatEndDate,
      preReminderOffset: task.preReminderOffset,
      status: TaskStatus.pending,
    );

    _tasks.insert(0, nextTask);
    await _saveTasks();
    await _notificationService.scheduleTaskNotification(nextTask);
  }

  DateTime? _calculateNextDueDate(Task task) {
    if (task.dueDate == null) return null;
    final rule = task.repeatRule!;
    final current = task.dueDate!;

    switch (rule) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      default:
        if (rule.startsWith('weekly:')) {
          final daysStr = rule.substring(7);
          final days = daysStr.split(',').map(int.parse).toList()..sort();
          final currentWeekday = current.weekday;
          for (final day in days) {
            if (day > currentWeekday) {
              return current.add(Duration(days: day - currentWeekday));
            }
          }
          return current
              .add(Duration(days: 7 - currentWeekday + days.first));
        }
        if (rule.startsWith('every_') && rule.endsWith('_days')) {
          final days = int.parse(rule.substring(6, rule.length - 5));
          return current.add(Duration(days: days));
        }
        if (rule.startsWith('every_') && rule.endsWith('_weeks')) {
          final weeks = int.parse(rule.substring(6, rule.length - 6));
          return current.add(Duration(days: weeks * 7));
        }
        return null;
    }
  }

  Future<void> snoozeTask(String taskId, Duration duration) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final current = _tasks[index];
      final newDueDate = current.dueDate != null
          ? current.dueDate!.add(duration)
          : DateTime.now().add(duration);
      _tasks[index] = current.copyWith(
        dueDate: newDueDate,
        status: TaskStatus.snoozed,
      );
      await _saveTasks();
      await _notificationService.cancelTaskNotifications(current);
      await _notificationService.scheduleTaskNotification(_tasks[index]);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => Task(id: '', title: ''),
    );
    if (task.id.isNotEmpty) {
      await _notificationService.cancelTaskNotifications(task);
    }
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? noteContent,
    List<SubTask>? subtasks,
    DateTime? dueDate,
    DateTime? dueTime,
    TaskCategory? category,
    String? repeatRule,
    DateTime? repeatEndDate,
    int? preReminderOffset,
    TaskStatus? status,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final current = _tasks[index];
      final updated = current.copyWith(
        title: title,
        description: description,
        noteContent: noteContent,
        subtasks: subtasks,
        dueDate: dueDate,
        dueTime: dueTime,
        category: category,
        repeatRule: repeatRule,
        repeatEndDate: repeatEndDate,
        preReminderOffset: preReminderOffset,
        status: status,
      );
      _tasks[index] = updated;
      await _saveTasks();
      await _notificationService.cancelTaskNotifications(current);
      if (updated.status == TaskStatus.pending) {
        await _notificationService.scheduleTaskNotification(updated);
      }
    }
  }

  Future<void> _rescheduleAllNotifications() async {
    await _notificationService.rescheduleAllTasks(_tasks
        .where((t) => t.status == TaskStatus.pending)
        .toList());
  }

  List<Task> getTasksForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return _tasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      if (t.dueDate == null) return false;
      final taskDate = DateTime(
          t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return taskDate.isAtSameMomentAs(target);
    }).toList();
  }

  Map<String, List<Task>> getTasksGroupedByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeekEnd = today.add(Duration(days: 7 - now.weekday));

    final groups = <String, List<Task>>{
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Later': [],
      'No Date': [],
      'Overdue': [],
    };

    for (final task in _tasks) {
      if (task.status == TaskStatus.done) continue;

      final deadline = task.deadline;
      if (deadline == null) {
        groups['No Date']!.add(task);
      } else if (deadline.isBefore(today)) {
        groups['Overdue']!.add(task);
      } else if (deadline.isBefore(tomorrow)) {
        groups['Today']!.add(task);
      } else if (deadline.isBefore(tomorrow.add(const Duration(days: 1)))) {
        groups['Tomorrow']!.add(task);
      } else if (deadline.isBefore(thisWeekEnd)) {
        groups['This Week']!.add(task);
      } else {
        groups['Later']!.add(task);
      }
    }

    for (final list in groups.values) {
      list.sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });
    }

    return groups;
  }
}
