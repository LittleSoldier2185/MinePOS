import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

class ServerConfig {
  const ServerConfig._({
    required this.port,
    required this.bindAddress,
    required this.jwtSecret,
    required this.dataDir,
    required this.adminUser,
    required this.adminPass,
    required this.shopName,
    required this.autoSeedAdmin,
  });

  final int port;

  /// Null means "all interfaces" (the historic default). Only meaningful for
  /// the CLI/bundled-exe entrypoint (`bin/server.dart`) — mobile self-host
  /// always passes its own loopback-only [InternetAddress] straight to
  /// `startMinePosServer`, bypassing this field entirely, so changing it here
  /// can never widen that guarantee.
  final String? bindAddress;
  final String jwtSecret;
  final String dataDir;
  final String adminUser;
  final String adminPass;
  final String shopName;

  /// True only when both MINEPOS_ADMIN_USER and MINEPOS_ADMIN_PASS are
  /// explicitly set — an opt-in for headless/scripted deployment. Otherwise
  /// the server starts with no users at all and waits for a client to
  /// bootstrap it via POST /setup (the Create Shop wizard).
  final bool autoSeedAdmin;

  /// [port]/[dataDir]/[shopName] override the matching env var when set —
  /// used by in-process callers (e.g. mobile self-host) that can't set
  /// process env vars for themselves. CLI callers pass nothing and get the
  /// original env-var-driven behavior unchanged.
  static Future<ServerConfig> load({int? port, String? dataDir, String? shopName}) async {
    final resolvedDataDir = dataDir ?? Platform.environment['MINEPOS_DATA_DIR'] ?? 'data';
    final resolvedShopName = shopName ?? Platform.environment['MINEPOS_SHOP_NAME'] ?? 'MinePOS';
    final autoSeedAdmin = Platform.environment.containsKey('MINEPOS_ADMIN_USER') &&
        Platform.environment.containsKey('MINEPOS_ADMIN_PASS');
    final adminUser = Platform.environment['MINEPOS_ADMIN_USER'] ?? 'admin';
    final adminPass = Platform.environment['MINEPOS_ADMIN_PASS'] ?? '';

    // Persist JWT secret so tokens survive restarts.
    final secretFile = File(p.join(resolvedDataDir, 'server.json'));
    String jwtSecret = Platform.environment['MINEPOS_JWT_SECRET'] ?? '';

    Map raw = {};
    if (await secretFile.exists()) {
      raw = jsonDecode(await secretFile.readAsString()) as Map;
    }
    jwtSecret = jwtSecret.isNotEmpty ? jwtSecret : (raw['jwtSecret'] as String? ?? '');

    if (jwtSecret.isEmpty) {
      jwtSecret = _randomString(48);
      await Directory(resolvedDataDir).create(recursive: true);
      await secretFile.writeAsString(jsonEncode({...raw, 'jwtSecret': jwtSecret}));
      print('Generated new JWT secret and saved to ${secretFile.path}');
    }

    // port/bindAddress persisted via the admin dashboard's "Listen Settings"
    // (PATCH /admin/config, see admin_routes.dart) take precedence over the
    // env var once set, since that's now the deliberately-configured value —
    // the env var only matters for the very first boot, same as adminUser/Pass.
    final resolvedPort = port ??
        (raw['port'] as int?) ??
        int.tryParse(Platform.environment['MINEPOS_PORT'] ?? '') ??
        8080;
    final resolvedBindAddress =
        (raw['bindAddress'] as String?) ?? Platform.environment['MINEPOS_BIND_ADDRESS'];

    if (!autoSeedAdmin) {
      print(
        'ℹ  MINEPOS_ADMIN_USER/MINEPOS_ADMIN_PASS not set. '
        'No admin account will be auto-created — bootstrap the shop via '
        'POST /setup (the Create Shop wizard) instead.',
      );
    }

    return ServerConfig._(
      port: resolvedPort,
      bindAddress: resolvedBindAddress,
      jwtSecret: jwtSecret,
      dataDir: resolvedDataDir,
      adminUser: adminUser,
      adminPass: adminPass.isEmpty ? _randomString(12) : adminPass,
      shopName: resolvedShopName,
      autoSeedAdmin: autoSeedAdmin,
    );
  }

  /// Writes a new port/bindAddress into `server.json` (preserving the
  /// existing jwtSecret) so the next [load] call — triggered by a restart —
  /// picks it up. Called by `PATCH /admin/config`. [bindAddress] of `null`
  /// means "all interfaces".
  static Future<void> persistListenConfig(
    String dataDir, {
    required int port,
    required String? bindAddress,
  }) async {
    final file = File(p.join(dataDir, 'server.json'));
    Map raw = {};
    if (await file.exists()) {
      raw = jsonDecode(await file.readAsString()) as Map;
    }
    await file.writeAsString(jsonEncode({...raw, 'port': port, 'bindAddress': bindAddress}));
  }

  static String _randomString(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
