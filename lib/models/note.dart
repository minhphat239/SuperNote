import 'dart:convert';

class Note {
  final String noteId;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  String? syncId;
  int syncVersion;
  bool isSynced;

  Note({
    required this.noteId,
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncId,
    this.syncVersion = 0,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'syncId': syncId,
      'syncVersion': syncVersion,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      noteId: map['noteId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isDeleted: map['isDeleted'] ?? false,
      syncId: map['syncId'],
      syncVersion: map['syncVersion'] ?? 0,
      isSynced: true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(jsonDecode(source));
}
