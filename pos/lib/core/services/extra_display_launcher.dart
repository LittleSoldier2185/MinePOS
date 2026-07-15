import 'dart:io';

import 'server_client.dart';

enum ExtraDisplayMode { customer, kitchen }

/// Spawns a second, independent OS process running this same app pinned
/// straight to either the Customer Display or Kitchen Display screen — so a
/// cashier can drag it onto a second monitor while the main window keeps
/// working normally. The new process inherits this session's server address
/// and auth token (this is the same device/login, just another window), so
/// it never has to go through Connect/Login again. See main.dart's
/// `--extra-display=` arg handling for the other end of this.
class ExtraDisplayLauncher {
  ExtraDisplayLauncher._();

  static Future<bool> open(ExtraDisplayMode mode) async {
    if (!Platform.isWindows) return false;
    final client = ServerClient.instance;
    final address = client.baseUrl;
    final token = client.token;
    if (address == null || token == null) return false;

    try {
      await Process.start(
        Platform.resolvedExecutable,
        [
          '--extra-display=${mode.name}',
          '--address=$address',
          '--token=$token',
        ],
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
