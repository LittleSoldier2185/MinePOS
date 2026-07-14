import 'dart:io';

import 'package:http/http.dart' as http;

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

  /// Whether this device has already been set up as a shop (the bundled
  /// server's data dir has a database file) — checked directly off disk
  /// rather than by starting the server and asking it, so viewing the
  /// welcome screen never has the side effect of spinning up a background
  /// server process just to answer this. False (not just "unset up") is
  /// also the honest answer in dev (`flutter run`), where no bundled exe —
  /// and therefore no fixed data dir to check — exists yet.
  bool hasLocalShop() {
    final exe = _findServerExecutable();
    if (exe == null) return false;
    return File('${exe.parent.path}\\data\\minepos.db').existsSync();
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
