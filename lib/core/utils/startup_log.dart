import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Startup profiler: writes timestamped traces to a file in app documents.
/// After an ANR/freeze, read the file to see which step blocked startup.
class StartupLog {
  static final StartupLog _instance = StartupLog._();
  factory StartupLog() => _instance;
  StartupLog._();

  final List<String> _lines = [];
  File? _file;
  final Stopwatch _sw = Stopwatch()..start();

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _instance._file = File('${dir.path}/startup_log.txt');
      if (await _instance._file!.exists()) {
        await _instance._file!.delete();
      }
    } catch (_) {
      _instance._file = null;
    }
  }

  static void mark(String tag) {
    final ms = _instance._sw.elapsedMilliseconds;
    final line = '+${ms}ms [$tag]';
    _instance._lines.add(line);
    debugPrint('STARTUP_LOG $line');
    _instance._file?.writeAsString(
      '${_instance._lines.join('\n')}\n',
      mode: FileMode.append,
    ).catchError((_) => _instance._file!);
  }
}