import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Always write to temp dir (no permission needed)
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
    // Also try to write to Documents dir directly (may fail without permission)
    try {
      final publicDir = Directory('/storage/emulated/0/Documents/SuperNote');
      if (!publicDir.existsSync()) {
        publicDir.createSync(recursive: true);
      }
      final pubFile = File('${publicDir.path}/startup_log.txt');
      if (pubFile.existsSync()) pubFile.deleteSync();
      // Write initial marker
      pubFile.writeAsStringSync('=== SuperNote Startup Log ===\n');
    } catch (_) {}
  }

  /// Migrate to a user-visible location (Documents/SuperNote/) so the log
  /// can be found in any file manager without adb/root.
  static Future<void> initVisible() async {
    try {
      // Non-blocking permission request on Android 11+
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        const channel = MethodChannel('com.example.super_note/storage');
        channel.invokeMethod<bool>('isManageStorageGranted').then((granted) {
          if (granted != true) {
            debugPrint('STARTUP_LOG: requesting MANAGE_EXTERNAL_STORAGE...');
            channel.invokeMethod('requestManageStorage');
          }
        }).catchError((e) {
          debugPrint('STARTUP_LOG: permission check failed: $e');
        });
      }

      // Write to public Documents dir
      final publicDir = Directory('/storage/emulated/0/Documents/SuperNote');
      if (!await publicDir.exists()) {
        await publicDir.create(recursive: true);
      }
      final visibleFile = File('${publicDir.path}/startup_log.txt');
      if (await visibleFile.exists()) {
        await visibleFile.delete();
      }
      _instance._file = visibleFile;
      debugPrint('STARTUP_LOG file: ${visibleFile.path}');
    } catch (e) {
      debugPrint('STARTUP_LOG initVisible failed: $e');
      // Fallback
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null && await ext.exists()) {
          final visibleFile = File('${ext.path}/startup_log.txt');
          if (await visibleFile.exists()) await visibleFile.delete();
          _instance._file = visibleFile;
        }
      } catch (_) {}
    }
  }

  static void mark(String tag) {
    final ms = _instance._sw.elapsedMilliseconds;
    final line = '+${ms}ms [$tag]';
    _instance._lines.add(line);
    debugPrint('STARTUP_LOG $line');
    _instance._write(line);
    // Also write to Documents dir directly
    try {
      final pubFile = File('/storage/emulated/0/Documents/SuperNote/startup_log.txt');
      pubFile.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}
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
    // Write to current file
    _instance._file?.writeAsStringSync(
      '${lines.join('\n')}\n',
      mode: FileMode.append,
    );
    // Also try to write to Documents dir directly (in case visible file not set yet)
    try {
      final publicDir = Directory('/storage/emulated/0/Documents/SuperNote');
      if (publicDir.existsSync()) {
        final crashFile = File('${publicDir.path}/startup_log.txt');
        crashFile.writeAsStringSync(
          '${lines.join('\n')}\n',
          mode: FileMode.append,
        );
      }
    } catch (_) {}
    // Also write to temp dir (always works, no permission needed)
    try {
      final tmpFile = File('${Directory.systemTemp.path}/startup_log.txt');
      tmpFile.writeAsStringSync(
        '${lines.join('\n')}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  void _write(String line) {
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}
  }
}

/// Installs global error handlers that surface any uncaught error:
/// - writes it to the startup log file
/// - records it in [crashMessage] so the root widget can render it on
///   screen (safe during build phase — no Navigator/Overlay needed).
final ValueNotifier<String?> crashMessage = ValueNotifier<String?>(null);

void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    final msg = '${details.exception}\n\n${details.stack}';
    StartupLog.logCrash(details.exception, details.stack);
    if (crashMessage.value == null) {
      // Defer: setting it during build phase would trigger
      // "markNeedsBuild called during build" and hide the real error.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        crashMessage.value = msg;
      });
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = '$error\n\n$stack';
    StartupLog.logCrash(error, stack);
    if (crashMessage.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        crashMessage.value = msg;
      });
    }
    return true;
  };
}

/// Renders the captured crash message (if any). Safe to use at any time.
class CrashOverlay extends StatelessWidget {
  const CrashOverlay({super.key});

  String _logPath() {
    try {
      // Return the external storage path if available
      return StartupLog._instance._file?.path ?? 'N/A';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: crashMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        final logPath = _logPath();
        return Material(
          color: const Color(0xE61E1B1B),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CRASH',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Log: $logPath',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        message,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          final text = 'Log: $logPath\n\n$message';
                          Clipboard.setData(ClipboardData(text: text));
                        },
                        child: const Text('Copy log',
                            style: TextStyle(color: Colors.orange)),
                      ),
                      TextButton(
                        onPressed: () => crashMessage.value = null,
                        child: const Text('Close',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}