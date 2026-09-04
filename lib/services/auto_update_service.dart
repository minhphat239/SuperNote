import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'feedback_service.dart';

enum UpdatePlatform { android, windows, web, unknown }

class UpdateAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  const UpdateAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });
}

class UpdateInfo {
  final String version;
  final String tagName;
  final String name;
  final String body;
  final String publishedAt;
  final String htmlUrl;
  final List<UpdateAsset> assets;
  final bool isCritical;
  final bool forceUpdate;
  final String changelog;

  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
    this.isCritical = false,
    this.forceUpdate = false,
    this.changelog = '',
  });

  bool get hasAsset => assets.isNotEmpty;

  UpdateAsset? getRecommendedAsset([List<String>? deviceAbis]) {
    // First: try to match device ABI for APK files
    if (deviceAbis != null && deviceAbis.isNotEmpty) {
      for (final asset in assets) {
        final lower = asset.name.toLowerCase();
        if (!lower.endsWith('.apk')) continue;
        for (final abi in deviceAbis) {
          if (lower.contains(abi)) return asset;
        }
      }
    }

    // Second: any APK file
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) return asset;
    }

    // Third: any other asset
    return assets.isNotEmpty ? assets.first : null;
  }

  String get downloadUrl => getRecommendedAsset()?.downloadUrl ?? htmlUrl;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final version = tagName
        .replaceAll(RegExp(r'^[vV]'), '')
        .split('+')
        .first;

    final assetsData = json['assets'] as List<dynamic>? ?? [];
    final assets = assetsData.map((a) {
      final map = a as Map<String, dynamic>;
      return UpdateAsset(
        name: map['name'] as String? ?? '',
        downloadUrl: map['browser_download_url'] as String? ?? '',
        size: map['size'] as int? ?? 0,
        contentType: map['content_type'] as String? ?? '',
      );
    }).toList();

    final rawBody = json['body'] as String? ?? '';

    // Try to parse body as JSON for structured fields
    bool forceUpdate = false;
    String changelog = rawBody;
    try {
      final bodyJson = jsonDecode(rawBody) as Map<String, dynamic>;
      forceUpdate = bodyJson['force_update'] as bool? ?? false;
      changelog = bodyJson['changelog'] as String? ?? rawBody;
    } catch (_) {
      // Body is plain text — use as-is for changelog
    }

    final isCritical = forceUpdate ||
        rawBody.toLowerCase().contains('critical') ||
        rawBody.toLowerCase().contains('quan trọng') ||
        rawBody.toLowerCase().contains('bắt buộc');

    return UpdateInfo(
      version: version,
      tagName: tagName,
      name: json['name'] as String? ?? version,
      body: rawBody,
      publishedAt: json['published_at'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      assets: assets,
      isCritical: isCritical,
      forceUpdate: forceUpdate,
      changelog: changelog,
    );
  }
}

class AutoUpdateService extends ChangeNotifier {
  static const String _repoOwner = 'minhphat239';
  static const String _repoName = 'SuperNote';
  static const String _lastCheckKey = 'last_update_check';
  static const String _downloadedFileKey = 'downloaded_update_file';

  static const Duration _checkInterval = Duration(seconds: 0);

  final FeedbackService _feedback = FeedbackService();
  final Dio _dio = Dio();

  UpdateInfo? _pendingUpdate;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _downloadComplete = false;
  String? _downloadedFilePath;
  String? _error;

  UpdateInfo? get pendingUpdate => _pendingUpdate;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  bool get downloadComplete => _downloadComplete;
  String? get downloadedFilePath => _downloadedFilePath;
  String? get error => _error;

  static UpdatePlatform get currentPlatform {
    if (kIsWeb) return UpdatePlatform.web;
    if (defaultTargetPlatform == TargetPlatform.android) return UpdatePlatform.android;
    if (defaultTargetPlatform == TargetPlatform.windows) return UpdatePlatform.windows;
    return UpdatePlatform.unknown;
  }

  Future<List<String>> _getDeviceAbis() async {
    if (kIsWeb || currentPlatform != UpdatePlatform.android) return [];
    try {
      const channel = MethodChannel('com.example.super_note/update');
      final abis = await channel.invokeMethod<List>('getSupportedAbis');
      return abis?.cast<String>() ?? [];
    } catch (e) {
      developer.log('Failed to get device ABIs: $e', name: 'AutoUpdateService');
      return [];
    }
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SuperNote/$currentVersion',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        developer.log('Update check failed: HTTP ${response.statusCode}', name: 'AutoUpdateService');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = UpdateInfo.fromJson(json);

      if (_isNewerVersion(updateInfo.version, currentVersion)) {
        _pendingUpdate = updateInfo;
        notifyListeners();
        developer.log('Update available: ${updateInfo.version} (current: $currentVersion)', name: 'AutoUpdateService');
        return updateInfo;
      }

      developer.log('App is up to date (v$currentVersion)', name: 'AutoUpdateService');
      return null;
    } catch (e) {
      developer.log('Update check error', error: e, name: 'AutoUpdateService');
      return null;
    }
  }

  Future<bool> shouldAutoCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastCheckKey);
      if (lastCheckStr == null) return true;

      final lastCheck = DateTime.parse(lastCheckStr);
      final now = DateTime.now();
      return now.difference(lastCheck) > _checkInterval;
    } catch (_) {
      return true;
    }
  }

  Future<void> markChecked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<bool> startDownload() async {
    if (_pendingUpdate == null || _isDownloading) return false;

    final deviceAbis = await _getDeviceAbis();
    final asset = _pendingUpdate!.getRecommendedAsset(deviceAbis);
    if (asset == null || asset.downloadUrl.isEmpty) {
      _error = 'Không tìm thấy file tải xuống';
      notifyListeners();
      return false;
    }

    _isDownloading = true;
    _downloadProgress = 0;
    _downloadComplete = false;
    _error = null;
    notifyListeners();

    try {
      final dir = await getTemporaryDirectory();
      final updateDir = Directory('${dir.path}/supernote_updates');
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }
      final fileName = asset.name;
      final file = File('${updateDir.path}/$fileName');

      // Resume download if file partially exists
      int startByte = 0;
      if (await file.exists()) {
        startByte = await file.length();
        // If we already have the full file, skip download
        if (asset.size > 0 && startByte >= asset.size) {
          _downloadedFilePath = file.path;
          _downloadComplete = true;
          _isDownloading = false;
          _downloadProgress = 1.0;
          notifyListeners();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_downloadedFileKey, file.path);
          _feedback.trigger(FeedbackType.complete);
          return true;
        }
      }

      final response = await _dio.download(
        asset.downloadUrl,
        file.path,
        deleteOnError: false,
        options: Options(
          headers: startByte > 0 ? {'Range': 'bytes=$startByte-'} : null,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
        onReceiveProgress: (received, total) {
          final totalSize = asset.size > 0 ? asset.size : total;
          if (totalSize > 0) {
            final base = startByte > 0 ? startByte : 0;
            _downloadProgress = (base + received) / totalSize;
            notifyListeners();
          }
        },
      );

      if (response.statusCode != 200 && response.statusCode != 206) {
        _error = 'Tải xuống thất bại (HTTP ${response.statusCode})';
        _isDownloading = false;
        notifyListeners();
        return false;
      }

      _downloadedFilePath = file.path;
      _downloadComplete = true;
      _isDownloading = false;
      _downloadProgress = 1.0;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadedFileKey, file.path);

      developer.log('Download complete: ${file.path}', name: 'AutoUpdateService');
      _feedback.trigger(FeedbackType.complete);
      return true;
    } on DioException catch (e) {
      _error = 'Lỗi tải xuống: ${e.message ?? e.toString()}';
      _isDownloading = false;
      notifyListeners();
      developer.log('Download error', error: e, name: 'AutoUpdateService');
      return false;
    } catch (e) {
      _error = 'Lỗi tải xuống: ${e.toString()}';
      _isDownloading = false;
      notifyListeners();
      developer.log('Download error', error: e, name: 'AutoUpdateService');
      return false;
    }
  }

  Future<bool> installUpdate() async {
    if (_downloadedFilePath == null) return false;

    final file = File(_downloadedFilePath!);
    if (!await file.exists()) return false;

    try {
      final platform = currentPlatform;

      if (platform == UpdatePlatform.android) {
        const channel = MethodChannel('com.example.super_note/update');
        try {
          final uri = await channel.invokeMethod<String>('getUriForFile', {
            'path': file.path,
          });
          if (uri != null) {
            final contentUri = Uri.parse(uri);
            return await launchUrl(
              contentUri,
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          developer.log('FileProvider failed, trying fallback: $e', name: 'AutoUpdateService');
        }

        return _openReleasesPage();
      }

      if (platform == UpdatePlatform.windows) {
        final uri = Uri.file(_downloadedFilePath!);
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return _openReleasesPage();
      }

      return _openReleasesPage();
    } catch (e) {
      developer.log('Install update failed', error: e, name: 'AutoUpdateService');
      return _openReleasesPage();
    }
  }

  Future<bool> _openReleasesPage() async {
    final url = Uri.parse('https://github.com/$_repoOwner/$_repoName/releases/latest');
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<void> clearPendingUpdate() async {
    _pendingUpdate = null;
    notifyListeners();
  }

  static bool _isNewerVersion(String remote, String local) {
    final r = _parseVersion(remote);
    final l = _parseVersion(local);

    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    final clean = v.split('+').first;
    final parts = clean.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }
}
