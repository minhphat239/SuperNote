import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'note_service.dart';

class SyncService extends ChangeNotifier {
  final NoteService _noteService;
  bool _isSyncing = false;
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  Timer? _periodicSync;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService(this._noteService) {
    _initConnectivity();
    _periodicSync = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && !_isSyncing) {
        sync();
      }
    });
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);

      if (!wasOnline && _isOnline) {
        sync();
      }
      notifyListeners();
    });
  }

  Future<void> sync() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _noteService.fullSync();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      // Sync failed, will retry
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _periodicSync?.cancel();
    super.dispose();
  }
}
