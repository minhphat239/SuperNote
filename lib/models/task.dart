import 'package:flutter/material.dart';

class _Sentinel {
  const _Sentinel();
}
const _sentinel = _Sentinel();

enum TaskCategory {
  class_('Class'),
  exam('Exam'),
  assignment('Assignment'),
  personal('Personal');

  const TaskCategory(this.label);
  final String label;

  Color get color {
    switch (this) {
      case TaskCategory.class_:
        return const Color(0xFF00F5FF);
      case TaskCategory.exam:
        return const Color(0xFFFF007F);
      case TaskCategory.assignment:
        return const Color(0xFFFF8C42);
      case TaskCategory.personal:
        return const Color(0xFF00FF66);
    }
  }
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
  List<String> attachments;
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
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        subtasks = subtasks ?? [],
        attachments = attachments ?? [];

  bool get hasNote => noteContent.trim().isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;

  DateTime? get deadline {
    if (dueDate == null) return null;
    if (dueTime != null) {
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day,
          dueTime!.hour, dueTime!.minute);
    }
    // No specific time → Default Smart Time: 09:00 AM (start of work day)
    return DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 9, 0, 0);
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
      'attachments': attachments,
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
      attachments: (map['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Task copyWith({
    String? title,
    Object? description = _sentinel,
    Object? noteContent = _sentinel,
    List<SubTask>? subtasks,
    Object? dueDate = _sentinel,
    Object? dueTime = _sentinel,
    TaskCategory? category,
    Object? repeatRule = _sentinel,
    Object? repeatEndDate = _sentinel,
    Object? preReminderOffset = _sentinel,
    TaskStatus? status,
    List<String>? attachments,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: identical(description, _sentinel) ? this.description : (description as String? ?? this.description),
      noteContent: identical(noteContent, _sentinel) ? this.noteContent : (noteContent as String? ?? this.noteContent),
      subtasks: subtasks ?? this.subtasks,
      dueDate: identical(dueDate, _sentinel) ? this.dueDate : dueDate as DateTime?,
      dueTime: identical(dueTime, _sentinel) ? this.dueTime : dueTime as DateTime?,
      category: category ?? this.category,
      repeatRule: identical(repeatRule, _sentinel) ? this.repeatRule : (repeatRule as String? ?? this.repeatRule),
      repeatEndDate: identical(repeatEndDate, _sentinel) ? this.repeatEndDate : (repeatEndDate as DateTime? ?? this.repeatEndDate),
      preReminderOffset: identical(preReminderOffset, _sentinel) ? this.preReminderOffset : (preReminderOffset as int? ?? this.preReminderOffset),
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
