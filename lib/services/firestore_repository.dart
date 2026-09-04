import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import '../models/task.dart';
import '../models/note.dart';

class FirestoreRepository {
  static final FirestoreRepository _instance = FirestoreRepository._internal();
  factory FirestoreRepository() => _instance;
  FirestoreRepository._internal();

  FirebaseFirestore? _db;
  bool _initialized = false;
  bool _isOnline = true;

  bool get isInitialized => _initialized;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _db = FirebaseFirestore.instance;

      _db!.snapshotsInSync().listen(
        (_) => _isOnline = true,
        onError: (_) => _isOnline = false,
      );

      _initialized = true;
      developer.log('Firestore initialized with offline persistence', name: 'FirestoreRepository');
    } catch (e) {
      developer.log('Firestore init failed', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  bool get _isAuthenticated => _userId != null;

  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    if (!_isAuthenticated) {
      throw Exception('User not authenticated');
    }
    return _db!.collection('users').doc(_userId).collection('tasks');
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    if (!_isAuthenticated) {
      throw Exception('User not authenticated');
    }
    return _db!.collection('users').doc(_userId);
  }

  // ===== USER PROFILE =====

  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    if (_db == null) return;
    try {
      await _db!.collection('users').doc(uid).set({
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': {
          'theme': 'city',
          'notificationsEnabled': true,
          'quietHoursStart': 22,
          'quietHoursEnd': 7,
        },
      }, SetOptions(merge: true));
      developer.log('User profile created for $uid', name: 'FirestoreRepository');
    } catch (e) {
      developer.log('Failed to create user profile', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!_isAuthenticated) return null;
    try {
      final doc = await _userDoc.get();
      return doc.data();
    } catch (e) {
      developer.log('Failed to get user profile', error: e, name: 'FirestoreRepository');
      return null;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (!_isAuthenticated) return;
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _userDoc.update(data);
    } catch (e) {
      developer.log('Failed to update user profile', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  // ===== TASKS =====

  Future<void> createTask(Task task) async {
    if (!_isAuthenticated) return;
    try {
      await _tasksCollection.doc(task.id).set(_taskToMap(task));
      developer.log('Task created: ${task.id}', name: 'FirestoreRepository');
    } catch (e) {
      developer.log('Failed to create task', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    if (!_isAuthenticated) return;
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _tasksCollection.doc(taskId).update(data);
    } catch (e) {
      developer.log('Failed to update task $taskId', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (!_isAuthenticated) return;
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      developer.log('Failed to delete task $taskId', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  Future<List<Task>> getAllTasks() async {
    if (!_isAuthenticated) return [];
    try {
      final snapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs
          .map((doc) => _mapToTask(doc.id, doc.data()))
          .toList();
    } catch (e) {
      developer.log('Failed to get tasks', error: e, name: 'FirestoreRepository');
      return [];
    }
  }

  Stream<List<Task>> watchTasks() {
    if (!_isAuthenticated) {
      return Stream.value([]);
    }
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapToTask(doc.id, doc.data()))
            .toList());
  }

  Future<List<Task>> getTasksByCategory(TaskCategory category) async {
    if (!_isAuthenticated) return [];
    try {
      final snapshot = await _tasksCollection
          .where('category', isEqualTo: category.name)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs
          .map((doc) => _mapToTask(doc.id, doc.data()))
          .toList();
    } catch (e) {
      developer.log('Failed to get tasks by category', error: e, name: 'FirestoreRepository');
      return [];
    }
  }

  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    if (!_isAuthenticated) return [];
    try {
      final snapshot = await _tasksCollection
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('dueDate')
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs
          .map((doc) => _mapToTask(doc.id, doc.data()))
          .toList();
    } catch (e) {
      developer.log('Failed to get tasks by date range', error: e, name: 'FirestoreRepository');
      return [];
    }
  }

  Future<List<Task>> getPendingTasks() async {
    if (!_isAuthenticated) return [];
    try {
      final snapshot = await _tasksCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('dueDate', descending: false)
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs
          .map((doc) => _mapToTask(doc.id, doc.data()))
          .toList();
    } catch (e) {
      developer.log('Failed to get pending tasks', error: e, name: 'FirestoreRepository');
      return [];
    }
  }

  // ===== SYNC HELPERS =====

  Future<void> syncLocalToCloud(List<Task> localTasks) async {
    if (!_isAuthenticated || _db == null) return;
    try {
      final batch = _db!.batch();
      for (final task in localTasks) {
        final ref = _tasksCollection.doc(task.id);
        batch.set(ref, _taskToMap(task), SetOptions(merge: true));
      }
      await batch.commit();
      developer.log('Synced ${localTasks.length} tasks to cloud', name: 'FirestoreRepository');
    } catch (e) {
      developer.log('Failed to sync local to cloud', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  Future<List<Task>> syncCloudToLocal(List<Task> localTasks) async {
    if (!_isAuthenticated || _db == null) return localTasks;
    try {
      final cloudTasks = await getAllTasks();
      if (cloudTasks.isEmpty) {
        // Cloud is empty but local has data → push local to cloud
        if (localTasks.isNotEmpty) {
          await syncLocalToCloud(localTasks);
        }
        return localTasks;
      }

      // Merge: cloud tasks + local tasks, last-write-wins by updatedAt
      final mergedMap = <String, Task>{};

      // Add all local tasks first
      for (final task in localTasks) {
        mergedMap[task.id] = task;
      }

      // Merge cloud tasks: if cloud version is newer, it wins
      for (final cloudTask in cloudTasks) {
        final localTask = mergedMap[cloudTask.id];
        if (localTask == null) {
          // New task from cloud → add it
          mergedMap[cloudTask.id] = cloudTask;
        } else if (cloudTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Cloud is newer → use cloud version
          mergedMap[cloudTask.id] = cloudTask;
        }
        // else local is newer → keep local (already in map)
      }

      final merged = mergedMap.values.toList();

      // Push merged result back to cloud to ensure consistency
      await syncLocalToCloud(merged);

      developer.log('Merged ${localTasks.length} local + ${cloudTasks.length} cloud = ${merged.length} total', name: 'FirestoreRepository');
      return merged;
    } catch (e) {
      developer.log('Failed to sync cloud to local, using local data', error: e, name: 'FirestoreRepository');
      return localTasks;
    }
  }

  Future<void> deleteAllTasks() async {
    if (!_isAuthenticated || _db == null) return;
    try {
      final snapshot = await _tasksCollection.get();
      final batch = _db!.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      developer.log('Failed to delete all tasks', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  // ===== NOTES =====

  CollectionReference<Map<String, dynamic>> get _notesCollection {
    if (!_isAuthenticated) {
      throw Exception('User not authenticated');
    }
    return _db!.collection('users').doc(_userId).collection('notes');
  }

  Map<String, dynamic> _noteToCloudMap(Note note) {
    return {
      'noteId': note.noteId,
      'title': note.title,
      'content': note.content,
      'createdAt': Timestamp.fromDate(note.createdAt),
      'updatedAt': Timestamp.fromDate(note.updatedAt),
      'isDeleted': note.isDeleted,
      'syncVersion': note.syncVersion,
    };
  }

  Note _cloudMapToNote(String id, Map<String, dynamic> data) {
    try {
      return Note(
        noteId: data['noteId'] is String ? data['noteId'] as String : id,
        title: data['title'] is String ? data['title'] as String : '',
        content: data['content'] is String ? data['content'] as String : '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isDeleted: data['isDeleted'] is bool ? data['isDeleted'] as bool : false,
        syncVersion: data['syncVersion'] is int ? data['syncVersion'] as int : 0,
        isSynced: true,
      );
    } catch (e, st) {
      developer.log('Failed to map cloud note (id=$id)', error: e, stackTrace: st, name: 'FirestoreRepository');
      return Note(noteId: id, title: '(Lỗi dữ liệu)');
    }
  }

  Future<List<Note>> getAllNotes() async {
    if (!_isAuthenticated) return [];
    try {
      final snapshot = await _notesCollection
          .orderBy('updatedAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));
      return snapshot.docs
          .map((doc) => _cloudMapToNote(doc.id, doc.data()))
          .toList();
    } catch (e) {
      developer.log('Failed to get notes from cloud', error: e, name: 'FirestoreRepository');
      return [];
    }
  }

  Future<void> syncNotesLocalToCloud(List<Note> localNotes) async {
    if (!_isAuthenticated || _db == null) return;
    try {
      final batch = _db!.batch();
      for (final note in localNotes) {
        final ref = _notesCollection.doc(note.noteId);
        batch.set(ref, _noteToCloudMap(note), SetOptions(merge: true));
      }
      await batch.commit();
      developer.log('Synced ${localNotes.length} notes to cloud', name: 'FirestoreRepository');
    } catch (e) {
      developer.log('Failed to sync notes to cloud', error: e, name: 'FirestoreRepository');
      rethrow;
    }
  }

  Future<List<Note>> syncNotesCloudToLocal(List<Note> localNotes) async {
    if (!_isAuthenticated || _db == null) return localNotes;
    try {
      final cloudNotes = await getAllNotes();
      if (cloudNotes.isEmpty && localNotes.isNotEmpty) {
        await syncNotesLocalToCloud(localNotes);
        return localNotes;
      }

      final mergedMap = <String, Note>{};
      for (final note in localNotes) {
        mergedMap[note.noteId] = note;
      }
      for (final cloudNote in cloudNotes) {
        final localNote = mergedMap[cloudNote.noteId];
        if (localNote == null) {
          mergedMap[cloudNote.noteId] = cloudNote;
        } else if (cloudNote.updatedAt.isAfter(localNote.updatedAt)) {
          mergedMap[cloudNote.noteId] = cloudNote;
        }
      }

      final merged = mergedMap.values.where((n) => !n.isDeleted).toList();
      await syncNotesLocalToCloud(merged);
      developer.log('Merged ${localNotes.length} local + ${cloudNotes.length} cloud = ${merged.length} notes', name: 'FirestoreRepository');
      return merged;
    } catch (e) {
      developer.log('Failed to sync notes cloud-to-local', error: e, name: 'FirestoreRepository');
      return localNotes;
    }
  }

  // ===== MAPPING =====

  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'noteContent': task.noteContent,
      'subtasks': task.subtasks.map((s) => {
        'id': s.id,
        'title': s.title,
        'isDone': s.isDone,
      }).toList(),
      'dueDate': task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
      'dueTime': task.dueTime != null ? Timestamp.fromDate(task.dueTime!) : null,
      'category': task.category.name,
      'repeatRule': task.repeatRule,
      'repeatEndDate': task.repeatEndDate != null ? Timestamp.fromDate(task.repeatEndDate!) : null,
      'preReminderOffset': task.preReminderOffset,
      'status': task.status.name,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'updatedAt': Timestamp.fromDate(task.updatedAt),
    };
  }

  Task _mapToTask(String id, Map<String, dynamic> data) {
    try {
      final subtasksData = data['subtasks'] as List<dynamic>?;
      final subtasks = subtasksData?.map((s) {
        if (s is! Map) {
          return SubTask(id: '', title: '');
        }
        final map = s;
        return SubTask(
          id: map['id'] is String ? map['id'] as String : '',
          title: map['title'] is String ? map['title'] as String : '',
          isDone: map['isDone'] is bool ? map['isDone'] as bool : false,
        );
      }).toList() ?? [];

      final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
      final dueTime = (data['dueTime'] as Timestamp?)?.toDate();
      final repeatEndDate = (data['repeatEndDate'] as Timestamp?)?.toDate();

      TaskCategory category;
      try {
        final catRaw = data['category'];
        category = catRaw is String
            ? TaskCategory.values.byName(catRaw)
            : TaskCategory.personal;
      } catch (_) {
        category = TaskCategory.personal;
      }

      TaskStatus status;
      try {
        final statusRaw = data['status'];
        status = statusRaw is String
            ? TaskStatus.values.byName(statusRaw)
            : TaskStatus.pending;
      } catch (_) {
        status = TaskStatus.pending;
      }

      final preReminderRaw = data['preReminderOffset'];
      final preReminder = preReminderRaw is int
          ? preReminderRaw
          : (preReminderRaw is num ? preReminderRaw.toInt() : null);

      return Task(
        id: id,
        title: data['title'] is String ? data['title'] as String : '',
        description: data['description'] is String ? data['description'] as String : '',
        noteContent: data['noteContent'] is String ? data['noteContent'] as String : '',
        subtasks: subtasks,
        dueDate: dueDate,
        dueTime: dueTime,
        category: category,
        repeatRule: data['repeatRule'] is String ? data['repeatRule'] as String : null,
        repeatEndDate: repeatEndDate,
        preReminderOffset: preReminder,
        status: status,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e, st) {
      developer.log('Failed to map Firestore task (id=$id)', error: e, stackTrace: st, name: 'FirestoreRepository');
      // Return minimal valid task so app doesn't crash on corrupted data
      return Task(
        id: id,
        title: data['title'] is String ? data['title'] as String : '(Lỗi dữ liệu)',
      );
    }
  }
}
