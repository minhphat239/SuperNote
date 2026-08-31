import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/update_info.dart';

class UpdateService {
  static const String _repoOwner = 'minhphat239';
  static const String _repoName = 'SuperNote';
  static const String _lastVersionKey = 'last_installed_version';

  static String get _apiUrl =>
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = UpdateInfo.fromJson(json);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(updateInfo.version, currentVersion)) {
        return updateInfo;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static bool _isNewerVersion(String remote, String local) {
    final remoteParts = remote.split('.');
    final localParts = local.split('.');

    for (var i = 0; i < 3; i++) {
      final r = int.tryParse(remoteParts[i]) ?? 0;
      final l = int.tryParse(localParts[i]) ?? 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  static Future<bool> downloadUpdate(
    String downloadUrl,
    String fileName,
    Function(double) onProgress,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {'Accept': 'application/octet-stream'},
      );

      if (response.statusCode != 200) return false;

      final contentLength = response.contentLength ?? response.bodyBytes.length;
      final bytes = response.bodyBytes;
      final received = bytes.length;

      if (contentLength > 0) {
        onProgress(received / contentLength);
      }

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await _saveCurrentVersion();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _saveCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastVersionKey, packageInfo.version);
  }

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static String getReleaseUrl() =>
      'https://github.com/$_repoOwner/$_repoName/releases';
}
