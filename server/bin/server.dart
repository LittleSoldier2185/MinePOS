import 'dart:io';

import 'package:path/path.dart' as p;

import '../lib/app_server.dart';
import '../lib/config.dart';
import '../lib/server_log.dart';

Future<void> main() async {
  final config = await ServerConfig.load();
  RunningServer? current;

  // Restart in place rather than exiting the process: this entrypoint has no
  // supervisor watching it (run_server.bat just runs it once; a bundled exe
  // launched detached by LocalServerLauncher only gets relaunched by that
  // Windows-desktop-specific flow), so an exit(0) here — the old behavior —
  // just killed the server for good with nothing to bring it back.
  var restarting = false;

  // requestRestart and requestRestore each pass the other to
  // startMinePosServer (so a subsequent restart/restore keeps working after
  // the first one reopens the server) — declared as mutable variables
  // rather than local functions since Dart won't let two local functions
  // forward-reference each other by name.
  void Function()? requestRestart;
  void Function(List<int> bytes)? requestRestore;

  requestRestart = () {
    if (restarting) return;
    restarting = true;
    // Small delay lets the /admin/restart response finish flushing to the
    // caller before its underlying HttpServer gets torn down.
    Future.delayed(const Duration(milliseconds: 200), () async {
      ServerLog.instance.log('Restarting server…');
      await current!.close();
      current = await startMinePosServer(
        config: config,
        onRestartRequested: requestRestart,
        onRestoreRequested: requestRestore,
      );
      restarting = false;
    });
  };

  // POST /admin/restore has already validated [bytes] look like a real
  // MinePOS backup and confirmed this server has no shop of its own yet
  // (see backup_routes.dart) before ever calling this — closes the current
  // (empty) db, swaps the validated snapshot in as minepos.db, and reopens,
  // same close-then-reopen shape as requestRestart above (the db handle has
  // to be released before the file underneath it can be overwritten).
  requestRestore = (bytes) {
    if (restarting) return;
    restarting = true;
    Future.delayed(const Duration(milliseconds: 200), () async {
      ServerLog.instance.log('Restoring from an uploaded backup and restarting…');
      await current!.close();
      final dbPath = p.join(config.dataDir, 'minepos.db');
      await File(dbPath).writeAsBytes(bytes, flush: true);
      current = await startMinePosServer(
        config: config,
        onRestartRequested: requestRestart,
        onRestoreRequested: requestRestore,
      );
      restarting = false;
    });
  };

  // Double-clicking the compiled exe while another instance already holds
  // the port (most commonly: the POS app already auto-launched one
  // detached in the background — see LocalServerLauncher) throws here.
  // Left uncaught, Dart prints the exception and the process exits almost
  // instantly — Windows closes the console window the moment a
  // double-click-launched process ends, so the whole thing looks like
  // nothing happened at all instead of showing a real error. Catch it,
  // print something readable, and hold the window open if there's an
  // actual console attached to read it from (a background/detached launch
  // has no terminal, so it just exits immediately instead of hanging).
  try {
    current = await startMinePosServer(
      config: config,
      onRestartRequested: requestRestart,
      onRestoreRequested: requestRestore,
    );
  } catch (e) {
    print('MinePOS server failed to start: $e');
    print(
      'If this is "address already in use", a server is already running on '
      'port ${config.port} — most likely the POS app already started one in '
      'the background. You don\'t need to run this again.',
    );
    // hasTerminal can still say true for a redirected/non-interactive stdin
    // (e.g. piped from NUL) — readLineSync then throws its own unhandled
    // exception instead of just returning. Swallow that rather than let a
    // second uncaught exception replace the message above.
    if (stdin.hasTerminal) {
      print('Press Enter to close this window.');
      try {
        stdin.readLineSync();
      } catch (_) {
        // No real interactive terminal to wait on — fall through to exit.
      }
    }
    exit(1);
  }

  // Graceful shutdown on Ctrl-C.
  ProcessSignal.sigint.watch().first.then((_) async {
    print('\nShutting down…');
    await current?.close();
    exit(0);
  });
}
