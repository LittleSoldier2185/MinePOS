import 'dart:io';

import '../lib/app_server.dart';
import '../lib/config.dart';

Future<void> main() async {
  final config = await ServerConfig.load();
  final running = await startMinePosServer(config: config);

  // Graceful shutdown on Ctrl-C.
  ProcessSignal.sigint.watch().first.then((_) async {
    print('\nShutting down…');
    await running.close();
    exit(0);
  });
}
