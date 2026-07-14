import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:minepos_server/app_server.dart';
import 'package:minepos_server/config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _mobileAddress = '127.0.0.1:8080';
const _mobilePort = 8080;

/// Ensures a MinePOS server is reachable at [_mobileAddress] by running one
/// in-process, on a dedicated background Isolate — never the UI isolate,
/// since sqlite3's FFI calls are synchronous/blocking and would otherwise
/// risk frame jank (e.g. Reports pulling a large order history).
///
/// This is the mobile (Android/iOS) counterpart to [LocalServerLauncher],
/// but structurally different on purpose: mobile OSes don't allow spawning
/// separate background processes, so there's no detached exe here — and the
/// server it starts is bound to loopback only with mDNS disabled (see
/// `_isolateEntryPoint`), so this device can run its own standalone shop but
/// can NEVER be a host other devices connect to. That capability stays
/// PC-only (`LocalServerLauncher`) — deliberately, not a temporary gap.
class MobileServerLauncher {
  MobileServerLauncher._();
  static final instance = MobileServerLauncher._();

  Isolate? _isolate;
  bool _starting = false;

  /// Whether this device has already been set up as a shop — checked
  /// directly off disk, same reasoning as [LocalServerLauncher.hasLocalShop]:
  /// answering this should never have the side effect of spawning the
  /// background isolate.
  Future<bool> hasLocalShop() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbFile = File(p.join(supportDir.path, 'minepos', 'minepos.db'));
    return dbFile.existsSync();
  }

  Future<bool> _isHealthy() async {
    try {
      final res = await http
          .get(Uri.parse('http://$_mobileAddress/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Returns true once a server answers /health at [_mobileAddress], either
  /// because this session already started one or because this call did.
  /// Never respawns once an isolate is already up this session — just
  /// health-checks it, mirroring [LocalServerLauncher]'s re-entrant shape.
  Future<bool> ensureRunning({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isolate != null) return _isHealthy();
    if (await _isHealthy()) return true; // e.g. a stray `dart run` left over from dev
    if (_starting) return false;

    _starting = true;
    try {
      // path_provider needs the Flutter-attached UI isolate's plugin
      // channel — must resolve this *before* spawning, since a bare
      // Isolate.spawn'd isolate has no plugin access at all.
      final supportDir = await getApplicationSupportDirectory();
      final dataDir = p.join(supportDir.path, 'minepos');

      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _IsolateStartMessage(sendPort: receivePort.sendPort, dataDir: dataDir, port: _mobilePort),
      );

      final completer = Completer<bool>();
      final sub = receivePort.listen((message) {
        if (message is _IsolateReady && !completer.isCompleted) {
          completer.complete(true);
        } else if (message is _IsolateFailed && !completer.isCompleted) {
          completer.complete(false);
        }
      });

      final ok = await completer.future.timeout(timeout, onTimeout: () => false);
      await sub.cancel();
      receivePort.close();

      if (!ok) {
        isolate.kill(priority: Isolate.immediate);
        _starting = false;
        return false;
      }

      _isolate = isolate;
      _starting = false;
      return true;
    } catch (_) {
      _starting = false;
      return false;
    }
  }
}

class _IsolateStartMessage {
  const _IsolateStartMessage({required this.sendPort, required this.dataDir, required this.port});
  final SendPort sendPort;
  final String dataDir;
  final int port;
}

class _IsolateReady {
  const _IsolateReady();
}

class _IsolateFailed {
  const _IsolateFailed(this.error);
  final String error;
}

// Top-level (isolate entry points must be static or top-level functions).
void _isolateEntryPoint(_IsolateStartMessage msg) async {
  try {
    final config = await ServerConfig.load(port: msg.port, dataDir: msg.dataDir);
    // Loopback-only, mDNS disabled — hardcoded and intentionally NOT
    // parameterized. This is the entire guarantee behind "a phone can
    // self-host but can never be a host for other devices": any future
    // change threading a parameter through to override either of these
    // needs explicit product sign-off, not a routine refactor.
    await startMinePosServer(
      config: config,
      bindAddress: InternetAddress.loopbackIPv4,
      enableMdns: false,
    );
    msg.sendPort.send(const _IsolateReady());
  } catch (e) {
    msg.sendPort.send(_IsolateFailed(e.toString()));
  }
}
