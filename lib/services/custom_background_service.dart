import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomBackgroundType { none, image, video }

class CustomBackgroundService extends ChangeNotifier {
  static const String _keyPath = 'custom_bg_path';
  static const String _keyType = 'custom_bg_type';
  static const int _maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB

  CustomBackgroundType _type = CustomBackgroundType.none;
  String? _filePath;
  File? _file;

  CustomBackgroundType get type => _type;
  String? get filePath => _filePath;
  File? get file => _file;
  bool get isActive => _type != CustomBackgroundType.none && _file != null;

  final _bgStreamController = StreamController<CustomBackgroundService>.broadcast();
  Stream<CustomBackgroundService> get backgroundChanges => _bgStreamController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_keyPath);
    final savedType = prefs.getString(_keyType);

    if (savedPath != null && savedType != null) {
      final file = File(savedPath);
      if (await file.exists()) {
        _filePath = savedPath;
        _file = file;
        _type = savedType == 'video'
            ? CustomBackgroundType.video
            : CustomBackgroundType.image;
      } else {
        await _clearPrefs();
      }
    }
    notifyListeners();
  }

  Future<void> pickAndSetBackground() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    if (picked.size > _maxFileSizeBytes) {
      throw Exception('File exceeds 50 MB limit');
    }

    final ext = picked.path?.split('.').last.toLowerCase() ?? '';
    final isVideo = ['mp4', 'mov'].contains(ext);
    final type = isVideo ? CustomBackgroundType.video : CustomBackgroundType.image;

    await _copyAndSave(picked.path!, type);
  }

  Future<void> _copyAndSave(String sourcePath, CustomBackgroundType type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final customBgDir = Directory('${appDir.path}/custom_bg');
    if (!await customBgDir.exists()) {
      await customBgDir.create(recursive: true);
    }

    final ext = sourcePath.split('.').last;
    final destPath = '${customBgDir.path}/custom_bg.$ext';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);

    await _clearOldFile();
    _filePath = destPath;
    _file = File(destPath);
    _type = type;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPath, destPath);
    await prefs.setString(_keyType, type == CustomBackgroundType.video ? 'video' : 'image');

    notifyListeners();
    _bgStreamController.add(this);
  }

  Future<void> removeBackground() async {
    await _clearOldFile();
    await _clearPrefs();
    _filePath = null;
    _file = null;
    _type = CustomBackgroundType.none;

    notifyListeners();
    _bgStreamController.add(this);
  }

  Future<void> _clearOldFile() async {
    if (_filePath != null) {
      final oldFile = File(_filePath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPath);
    await prefs.remove(_keyType);
  }

  @override
  void dispose() {
    _bgStreamController.close();
    super.dispose();
  }
}
