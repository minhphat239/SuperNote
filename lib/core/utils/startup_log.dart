import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Startup profiler + global crash catcher.
///
/// Writes timestamped traces to a file so we can see where startup hangs
/// or crashes even on release builds without adb/root.
class StartupLog {
  static final StartupLog _instance = StartupLog._();
  factory StartupLog() => _instance;
  StartupLog._();

  final List<String> _lines = [];
  File? _file;
  final Stopwatch _sw = Stopwatch()..start();

  /// Best-effort earliest capture: synchronous, no plugins needed.
  static void initSync() {
    try {
      // Android: <pkg>/files (app documents). systemTemp is available before
      // any plugin call and maps to the app cache dir on Android.
      final tmp = Directory.systemTemp;
      if (tmp.existsSync()) {
        _instance._file = File('${tmp.path}/startup_log.txt');
        if (_instance._file!.existsSync()) {
          _instance._file!.deleteSync();
        }
      }
    } catch (_) {
      _instance._file = null;
    }
  }

  /// Migrate to a more user-visible location when plugins are available.
  static Future<void> initVisible() async {
    try {
      final ext = await getExternalStorageDirectory();
      final dir = (ext != null && await ext.exists()) ? ext : null;
      if (dir == null) return; // keep the systemTemp file
      final visibleFile = File('${dir.path}/startup_log.txt');
      if (await visibleFile.exists()) {
        await visibleFile.delete();
      }
      _instance._file = visibleFile;
    } catch (_) {
      // keep systemTemp file
    }
  }

  static void mark(String tag) {
    final ms = _instance._sw.elapsedMilliseconds;
    final line = '+${ms}ms [$tag]';
    _instance._lines.add(line);
    debugPrint('STARTUP_LOG $line');
    _instance._write(line);
  }

  static void logCrash(Object error, StackTrace? stack) {
    final ms = _instance._sw.elapsedMilliseconds;
    final lines = <String>[
      '\n===== CRASH at +${ms}ms =====',
      'ERROR: $error',
      if (stack != null) 'STACK:\n$stack',
    ];
    for (final l in lines) {
      debugPrint('STARTUP_LOG $l');
    }
    _instance._lines.addAll(lines);
    _instance._file?.writeAsStringSync(
      '${lines.join('\n')}\n',
      mode: FileMode.append,
    );
  }

  void _write(String line) {
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}
  }
}

/// Installs global error handlers that surface any uncaught error:
/// - writes it to the startup log file
/// - shows a full-screen overlay with the error text so the user can
///   screenshot it (works even on release builds, no adb required).
void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    StartupLog.logCrash(details.exception, details.stack);
    _showErrorOverlay('${details.exception}\n\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    StartupLog.logCrash(error, stack);
    _showErrorOverlay('$error\n\n$stack');
    return true;
  };
}

void _showErrorOverlay(String message) {
  final context = _errorContext;
  if (context == null || !context.mounted) return;
  _showErrorOverlayFor(context, message);
}

void _showErrorOverlayFor(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: const Color(0xFFFFE0E0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ CRASH',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 12),
            SelectableText(
              message,
              style: const TextStyle(
                  color: Colors.black, fontSize: 13, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Set by the root widget once its context exists.
BuildContext? _errorContext;
set errorContext(BuildContext? value) => _errorContext = value;