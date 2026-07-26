import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

const _localAddress = '127.0.0.1:8080';

/// Ensures a MinePOS server is reachable at [_localAddress], launching the
/// bundled server executable as a detached background process if it isn't
/// already running.
///
/// Launched detached (not as a child process) on purpose: this Windows
/// machine may be acting as the host for other devices (kitchen display,
/// other cashier terminals) on the network, so the server must keep running
/// after this app instance closes, not die with it. See
/// `tool/build_windows_release.ps1` for how the exe gets bundled next to the
/// app; in dev (`flutter run`) that folder doesn't exist, so this is a no-op
/// that leaves the existing "run `dart run bin/server.dart` yourself" flow
/// untouched.
class LocalServerLauncher {
  LocalServerLauncher._();
  static final instance = LocalServerLauncher._();

  bool _launching = false;

  Future<bool> _isHealthy() async {
    try {
      final res = await http
          .get(Uri.parse('http://$_localAddress/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Whether *this device* is currently running a MinePOS server, checked
  /// live via loopback — independent of what address the app's own
  /// `ServerClient` is actually connected through right now. An owner who
  /// reaches their own host machine via its LAN IP (typed manually, or via
  /// "Connect to Server" instead of "Open Register") is still self-hosting
  /// in every way that matters (Settings' Server Status/Restart/Logs act on
  /// this machine's own process either way); a plain `baseUrl == 127.0.0.1`
  /// check would miss that and hide the section for no real reason.
  Future<bool> isRunningLocally() async {
    if (!Platform.isWindows) return false;
    return _isHealthy();
  }

  /// Returns true once a server answers /health at [_localAddress], either
  /// because one was already running or because this call started it.
  Future<bool> ensureRunning({Duration timeout = const Duration(seconds: 10)}) async {
    if (!Platform.isWindows) return false;
    if (await _isHealthy()) return true;

    if (!_launching) {
      final exe = _findServerExecutable();
      if (exe == null) return false;

      _launching = true;
      try {
        await Process.start(
          exe.path,
          const [],
          mode: ProcessStartMode.detached,
          workingDirectory: exe.parent.path,
        );
      } catch (_) {
        _launching = false;
        return false;
      }
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isHealthy()) {
        _launching = false;
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _launching = false;
    return false;
  }

  /// Whether this device has already been set up as a shop — checked by
  /// opening the bundled server's own database file (read-only, closed
  /// immediately) and looking for a `users` row, not just whether the file
  /// exists: Settings → Danger Zone → Remove Shop wipes every table via
  /// `AppDb.wipeShop` but leaves the file itself in place, so a bare
  /// existence check would stay true forever and permanently disable
  /// Create Shop. Never starts the server just to answer this. False (not
  /// just "unset up") is also the honest answer in dev (`flutter run`),
  /// where no bundled exe — and therefore no fixed data dir to check —
  /// exists yet, and if the file is missing, unreadable, or pre-migration.
  bool hasLocalShop() {
    final db = _dbFile();
    if (db == null || !db.existsSync()) return false;
    try {
      final conn = sqlite3.open(db.path, mode: OpenMode.readOnly);
      try {
        final rows = conn.select('SELECT COUNT(*) AS c FROM users');
        return (rows.first['c'] as int) > 0;
      } finally {
        conn.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  /// Writes [bytes] (a snapshot pulled from `GET /admin/backup`, or read
  /// straight off a picked backup file) into place as this device's own
  /// `minepos.db`, ahead of the first [ensureRunning] call — used by
  /// `RestoreShopScreen` to set this device up from another shop's data
  /// instead of the normal Create Shop wizard. Re-checks [hasLocalShop]
  /// itself rather than trusting the caller, since this overwrites whatever
  /// is at that path; throws if a shop already exists here, or if the
  /// bundled server exe (and therefore its fixed data dir) can't be found.
  Future<void> writeRestoredDatabase(List<int> bytes) async {
    if (hasLocalShop()) {
      throw StateError('This device already has a shop — cannot restore over it.');
    }
    final db = _dbFile();
    if (db == null) {
      throw StateError('Bundled server executable not found.');
    }
    await db.parent.create(recursive: true);
    await db.writeAsBytes(bytes, flush: true);
  }

  /// Where this device's `minepos.db` lives (or would live), next to the
  /// bundled server exe — null if that exe can't be found (e.g. `flutter
  /// run` in dev, same standing limitation as [hasLocalShop]).
  File? _dbFile() {
    final exe = _findServerExecutable();
    if (exe == null) return null;
    return File('${exe.parent.path}\\data\\minepos.db');
  }

  /// The compiled server executable ships in a `server/` folder next to the
  /// app's own .exe — Flutter Windows desktop apps are distributed as a
  /// folder of files (not a single-file installer), so a sibling folder is
  /// the natural place to drop it.
  File? _findServerExecutable() {
    final appDir = File(Platform.resolvedExecutable).parent;
    final bundled = File('${appDir.path}\\server\\minepos_server.exe');
    return bundled.existsSync() ? bundled : null;
  }

  /// The log file the bundled server writes to (see `ServerLog` in the
  /// server package) — same machine, so the app reads it straight off disk
  /// rather than needing a dedicated HTTP endpoint. Null if the bundled exe
  /// (and therefore its data dir) can't be found, e.g. running via
  /// `flutter run` in dev, where the manual `dart run bin/server.dart`
  /// workflow applies instead and writes its log wherever that shell's
  /// working directory happened to be.
  File? get logFile {
    final exe = _findServerExecutable();
    if (exe == null) return null;
    return File('${exe.parent.path}\\data\\server.log');
  }
}
