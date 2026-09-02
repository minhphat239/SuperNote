import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../models/task.dart';
import 'auth_service.dart';
import 'nlp_service.dart';
import 'notification_service.dart';
import 'feedback_service.dart';
import 'firestore_repository.dart';
import 'ai_parser_service.dart';
import 'home_widget_service.dart';

class TaskService {
  static const String _prefix = 'tasks_';
  final AuthService? _authService;
  List<Task> _tasks = [];
  final _taskStreamController = StreamController<List<Task>>.broadcast();

  Stream<List<Task>> get taskStream => _taskStreamController.stream;
  final NotificationService _notificationService = NotificationService();
  final FeedbackService _feedback = FeedbackService();
  final FirestoreRepository _firestore = FirestoreRepository();
  final AiParserService _aiParser = AiParserService();
  final HomeWidgetService _homeWidgetService = HomeWidgetService();
  String? _currentUserId;

  TaskService({AuthService? authService}) : _authService = authService;

  String get _tasksKey => '$_prefix${_currentUserId ?? "guest"}';

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.done).toList();
  List<Task> get snoozedTasks =>
      _tasks.where((t) => t.status == TaskStatus.snoozed).toList();

  Future<void> init() async {
    _currentUserId = _authService?.userId;
    try {
      await _loadTasks();
    } catch (e) {
      developer.log('Failed to load tasks', error: e, name: 'TaskService');
      _tasks = [];
    }
    try {
      await _notificationService.init();
    } catch (e) {
      developer.log('Notification init failed', error: e, name: 'TaskService');
    }
    _setupNotificationHandlers();
    try {
      await _rescheduleAllNotifications();
    } catch (e) {
      developer.log('Reschedule notifications failed', error: e, name: 'TaskService');
    }
    try {
      await _feedback.init();
    } catch (e) {
      developer.log('Feedback init failed', error: e, name: 'TaskService');
    }
    try {
      await _aiParser.init();
    } catch (e) {
      developer.log('AI Parser init failed', error: e, name: 'TaskService');
    }
    try {
      await _homeWidgetService.init();
      await _homeWidgetService.updateWidgets(_tasks);
    } catch (e) {
      developer.log('HomeWidget init failed', error: e, name: 'TaskService');
    }
  }

  Future<void> reloadForUser(String? userId) async {
    _currentUserId = userId;
    _tasks = [];
    try {
      await _loadTasks();
    } catch (e) {
      developer.log('Reload tasks failed', error: e, name: 'TaskService');
      _tasks = [];
    }
    try {
      await _rescheduleAllNotifications();
    } catch (e) {
      developer.log('Reschedule notifications failed', error: e, name: 'TaskService');
    }
  }

  void _setupNotificationHandlers() {
    _notificationService.onNotificationTapped = (taskId) {};
    _notificationService.onNotificationAction = (taskId, action) async {
      try {
        if (action == 'done') {
          await toggleTask(taskId);
        } else if (action == 'snooze') {
          await snoozeTask(taskId, const Duration(minutes: 30));
        }
      } catch (e) {
        developer.log('Notification action failed', error: e, name: 'TaskService');
      }
    };
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tasksKey);
    if (data != null) {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        _tasks = decoded
            .whereType<Map>()
            .map((e) => Task.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _tasks.map((e) => e.toMap()).toList();
    await prefs.setString(_tasksKey, jsonEncode(data));

    // Broadcast to all listeners
    _taskStreamController.add(List.unmodifiable(_tasks));

    // Sync to cloud if authenticated
    try {
      if (_firestore.isInitialized && _authService?.isLoggedIn == true) {
        await _firestore.syncLocalToCloud(_tasks);
      }
    } catch (e) {
      developer.log('Cloud sync failed', error: e, name: 'TaskService');
    }

    // Update home screen widgets
    try {
      await _homeWidgetService.updateWidgets(_tasks);
    } catch (e) {
      developer.log('Widget sync failed', error: e, name: 'TaskService');
    }
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
    try {
      await _notificationService.scheduleTaskNotification(task);
    } catch (e) {
      developer.log('Schedule notification failed', error: e, name: 'TaskService');
    }
    return task;
  }

  Future<AiParsedTask> addTaskFromAi(String input) async {
    final parsed = await _aiParser.parseTaskInput(input);
    final task = parsed.toTask();

    _tasks.insert(0, task);
    await _saveTasks();
    try {
      await _notificationService.scheduleTaskNotification(task);
    } catch (e) {
      developer.log('Schedule notification failed', error: e, name: 'TaskService');
    }
    _feedback.trigger(FeedbackType.aiSuccess);
    return parsed;
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
    try {
      await _notificationService.scheduleTaskNotification(task);
    } catch (e) {
      developer.log('Schedule notification failed', error: e, name: 'TaskService');
    }
    return task;
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final current = _tasks[index];
      final newStatus = current.isDone ? TaskStatus.pending : TaskStatus.done;
      _tasks[index] = current.copyWith(status: newStatus);
      await _saveTasks();

      if (newStatus == TaskStatus.done) {
        _feedback.trigger(FeedbackType.complete);
        try {
          await _notificationService.cancelTaskNotifications(current);
        } catch (e) {
          developer.log('Cancel notifications failed', error: e, name: 'TaskService');
        }
        if (current.repeatRule != null && current.repeatRule!.isNotEmpty) {
          await _createNextOccurrence(current);
        }
      } else {
        try {
          await _notificationService.scheduleTaskNotification(current);
        } catch (e) {
          developer.log('Schedule notification failed', error: e, name: 'TaskService');
        }
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
          .map((s) => SubTask(id: s.id, title: s.title, isDone: false))
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
    try {
      await _notificationService.scheduleTaskNotification(nextTask);
    } catch (e) {
      developer.log('Schedule notification failed', error: e, name: 'TaskService');
    }
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
      try {
        await _notificationService.cancelTaskNotifications(current);
        await _notificationService.scheduleTaskNotification(_tasks[index]);
      } catch (e) {
        developer.log('Snooze notification failed', error: e, name: 'TaskService');
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => Task(id: '', title: ''),
    );
    if (task.id.isNotEmpty) {
      try {
        await _notificationService.cancelTaskNotifications(task);
      } catch (e) {
        developer.log('Cancel notifications failed', error: e, name: 'TaskService');
      }
    }
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();

    // Delete from cloud
    try {
      if (_firestore.isInitialized && _authService?.isLoggedIn == true) {
        await _firestore.deleteTask(taskId);
      }
    } catch (e) {
      developer.log('Cloud delete failed', error: e, name: 'TaskService');
    }
    _feedback.trigger(FeedbackType.delete);
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
    List<String>? attachments,
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
        attachments: attachments,
      );
      _tasks[index] = updated;
      await _saveTasks();
      try {
        await _notificationService.cancelTaskNotifications(current);
        if (updated.status == TaskStatus.pending) {
          await _notificationService.scheduleTaskNotification(updated);
        }
      } catch (e) {
        developer.log('Notification update failed', error: e, name: 'TaskService');
      }

      // Update in cloud
      try {
        if (_firestore.isInitialized && _authService?.isLoggedIn == true) {
          await _firestore.updateTask(taskId, updated.toMap());
        }
      } catch (e) {
        developer.log('Cloud update failed', error: e, name: 'TaskService');
      }
    }
  }

  Future<void> _rescheduleAllNotifications() async {
    await _notificationService.rescheduleAllTasks(
        pendingTasks);
  }

  List<Task> getTasksForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return _tasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      if (t.dueDate == null) return false;
      final taskDate =
          DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
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
