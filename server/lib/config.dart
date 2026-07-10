import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

class ServerConfig {
  const ServerConfig._({
    required this.port,
    required this.jwtSecret,
    required this.dataDir,
    required this.adminUser,
    required this.adminPass,
    required this.shopName,
    required this.autoSeedAdmin,
  });

  final int port;
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

  static Future<ServerConfig> load() async {
    final port = int.tryParse(Platform.environment['MINEPOS_PORT'] ?? '') ?? 8080;
    final dataDir = Platform.environment['MINEPOS_DATA_DIR'] ?? 'data';
    final shopName = Platform.environment['MINEPOS_SHOP_NAME'] ?? 'MinePOS';
    final autoSeedAdmin = Platform.environment.containsKey('MINEPOS_ADMIN_USER') &&
        Platform.environment.containsKey('MINEPOS_ADMIN_PASS');
    final adminUser = Platform.environment['MINEPOS_ADMIN_USER'] ?? 'admin';
    final adminPass = Platform.environment['MINEPOS_ADMIN_PASS'] ?? '';

    // Persist JWT secret so tokens survive restarts.
    final secretFile = File(p.join(dataDir, 'server.json'));
    String jwtSecret = Platform.environment['MINEPOS_JWT_SECRET'] ?? '';

    if (jwtSecret.isEmpty) {
      if (await secretFile.exists()) {
        final raw = jsonDecode(await secretFile.readAsString()) as Map;
        jwtSecret = (raw['jwtSecret'] as String?) ?? '';
      }
      if (jwtSecret.isEmpty) {
        jwtSecret = _randomString(48);
        await Directory(dataDir).create(recursive: true);
        await secretFile.writeAsString(jsonEncode({'jwtSecret': jwtSecret}));
        print('Generated new JWT secret and saved to ${secretFile.path}');
      }
    }

    if (!autoSeedAdmin) {
      print(
        'ℹ  MINEPOS_ADMIN_USER/MINEPOS_ADMIN_PASS not set. '
        'No admin account will be auto-created — bootstrap the shop via '
        'POST /setup (the Create Shop wizard) instead.',
      );
    }

    return ServerConfig._(
      port: port,
      jwtSecret: jwtSecret,
      dataDir: dataDir,
      adminUser: adminUser,
      adminPass: adminPass.isEmpty ? _randomString(12) : adminPass,
      shopName: shopName,
      autoSeedAdmin: autoSeedAdmin,
    );
  }

  static String _randomString(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
