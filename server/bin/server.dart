import 'dart:io';

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
  void requestRestart() {
    if (restarting) return;
    restarting = true;
    // Small delay lets the /admin/restart response finish flushing to the
    // caller before its underlying HttpServer gets torn down.
    Future.delayed(const Duration(milliseconds: 200), () async {
      ServerLog.instance.log('Restarting server…');
      await current!.close();
      current = await startMinePosServer(config: config, onRestartRequested: requestRestart);
      restarting = false;
    });
  }

  current = await startMinePosServer(config: config, onRestartRequested: requestRestart);

  // Graceful shutdown on Ctrl-C.
  ProcessSignal.sigint.watch().first.then((_) async {
    print('\nShutting down…');
    await current?.close();
    exit(0);
  });
}
