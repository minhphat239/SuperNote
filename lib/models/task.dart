import 'package:flutter/material.dart';

enum TaskCategory {
  class_('Class', Colors.blue),
  exam('Exam', Colors.red),
  assignment('Assignment', Colors.orange),
  personal('Personal', Colors.green);

  const TaskCategory(this.label, this.color);
  final String label;
  final Color color;
}

enum TaskStatus {
  pending,
  done,
  snoozed,
}

class SubTask {
  String id;
  String title;
  bool isDone;

  SubTask({required this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isDone': isDone};
  factory SubTask.fromMap(Map<String, dynamic> m) => SubTask(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        isDone: m['isDone'] ?? false,
      );
}

class Task {
  final String id;
  String title;
  String description;
  String noteContent;
  List<SubTask> subtasks;
  DateTime? dueDate;
  DateTime? dueTime;
  TaskCategory category;
  String? repeatRule;
  DateTime? repeatEndDate;
  int? preReminderOffset;
  TaskStatus status;
  final DateTime createdAt;
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.noteContent = '',
    List<SubTask>? subtasks,
    this.dueDate,
    this.dueTime,
    this.category = TaskCategory.personal,
    this.repeatRule,
    this.repeatEndDate,
    this.preReminderOffset,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        subtasks = subtasks ?? [];

  bool get hasNote => noteContent.trim().isNotEmpty;

  DateTime? get deadline {
    if (dueDate != null && dueTime != null) {
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day,
          dueTime!.hour, dueTime!.minute);
    }
    return dueDate;
  }

  bool get isDone => status == TaskStatus.done;
  bool get isOverdue {
    if (deadline == null || isDone) return false;
    return DateTime.now().isAfter(deadline!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'noteContent': noteContent,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime?.toIso8601String(),
      'category': category.name,
      'repeatRule': repeatRule,
      'repeatEndDate': repeatEndDate?.toIso8601String(),
      'preReminderOffset': preReminderOffset,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      noteContent: map['noteContent'] ?? '',
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => SubTask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      dueTime: map['dueTime'] != null ? DateTime.parse(map['dueTime']) : null,
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.personal,
      ),
      repeatRule: map['repeatRule'],
      repeatEndDate: map['repeatEndDate'] != null
          ? DateTime.parse(map['repeatEndDate'])
          : null,
      preReminderOffset: map['preReminderOffset'],
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Task copyWith({
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
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      noteContent: noteContent ?? this.noteContent,
      subtasks: subtasks ?? this.subtasks,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatEndDate: repeatEndDate ?? this.repeatEndDate,
      preReminderOffset: preReminderOffset ?? this.preReminderOffset,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
