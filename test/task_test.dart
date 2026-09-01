import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

void main() {
  test('task round-trips through local storage format', () {
    final task = Task(
      id: 'task-1',
      title: 'Study',
      dueDate: DateTime(2026, 8, 31),
      category: TaskCategory.class_,
    );

    final restored = Task.fromMap(task.toMap());

    expect(restored.id, task.id);
    expect(restored.title, task.title);
    expect(restored.category, TaskCategory.class_);
    expect(restored.dueDate, task.dueDate);
  });
}
