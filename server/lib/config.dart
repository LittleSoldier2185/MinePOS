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
  });

  final int port;
  final String jwtSecret;
  final String dataDir;
  final String adminUser;
  final String adminPass;
  final String shopName;

  static Future<ServerConfig> load() async {
    final port = int.tryParse(Platform.environment['MINEPOS_PORT'] ?? '') ?? 8080;
    final dataDir = Platform.environment['MINEPOS_DATA_DIR'] ?? 'data';
    final shopName = Platform.environment['MINEPOS_SHOP_NAME'] ?? 'MinePOS';
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

    if (adminPass.isEmpty) {
      print(
        'ℹ  MINEPOS_ADMIN_PASS not set. '
        'If no users exist, admin will be created with a random password — '
        'check the startup log for it.',
      );
    }

    return ServerConfig._(
      port: port,
      jwtSecret: jwtSecret,
      dataDir: dataDir,
      adminUser: adminUser,
      adminPass: adminPass.isEmpty ? _randomString(12) : adminPass,
      shopName: shopName,
    );
  }

  static String _randomString(int len) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
