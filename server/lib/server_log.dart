import 'dart:io';

import 'package:path/path.dart' as p;

/// Persists server activity to a rotating log file alongside the DB, read by
/// the owner-only in-app log viewer. Anything passed to [log] is assumed
/// already safe to persist on disk — callers must redact secrets (passwords,
/// OTPs, auth tokens) before calling in; this class does not inspect content.
class ServerLog {
  ServerLog._(this._file);
  static ServerLog? _instance;
  static ServerLog get instance => _instance!;

  final File _file;

  // ponytail: single-file rotation (one backup, no external log library),
  // upgrade to a real rotating logger if request volume ever demands more history.
  static const _maxBytes = 5 * 1024 * 1024;

  static ServerLog open(String dataDir) {
    final file = File(p.join(dataDir, 'server.log'));
    file.parent.createSync(recursive: true);
    return _instance = ServerLog._(file);
  }

  void log(String message) {
    print(message);
    _rotateIfNeeded();
    _file.writeAsStringSync(
      '${DateTime.now().toIso8601String()} $message\n',
      mode: FileMode.append,
    );
  }

  void _rotateIfNeeded() {
    if (_file.existsSync() && _file.lengthSync() > _maxBytes) {
      final rotated = File('${_file.path}.1');
      if (rotated.existsSync()) rotated.deleteSync();
      _file.renameSync(rotated.path);
    }
  }
}

/// Strips auth tokens from a request-log line before it's persisted. The
/// Kitchen Display WebSocket passes its JWT as a `?token=` query param
/// (browsers can't set custom headers on a WS handshake), so the default
/// Shelf request logger would otherwise write live credentials to disk.
String redactTokens(String message) =>
    message.replaceAll(RegExp(r'token=[^&\s]+'), 'token=***');
