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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: crashMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        return Material(
          color: const Color(0xE61E1B1B),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ CRASH',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 12),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => crashMessage.value = null,
                      child: const Text('Close',
                          style: TextStyle(color: Colors.red)),
                    ),
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