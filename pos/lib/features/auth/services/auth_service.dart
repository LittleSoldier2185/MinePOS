import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';

class AuthResult {
  const AuthResult({required this.success, this.role, this.username, this.id});
  final bool success;
  final String? role;
  final String? username;
  final int? id;
}

class AuthService {
  Future<AuthResult> login(String username, String password, String deviceName) async {
    final client = ServerClient.instance;
    if (!client.isConnected) {
      return const AuthResult(success: false);
    }

    try {
      final res = await http
          .post(
            client.uri('/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
              'deviceName': deviceName.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        client.token = data['token'] as String;
        client.deviceName = deviceName.trim();
        return AuthResult(
          success: true,
          role: data['role'] as String?,
          username: data['username'] as String?,
          id: data['id'] as int?,
        );
      }
      return const AuthResult(success: false);
    } catch (_) {
      return const AuthResult(success: false);
    }
  }

  /// Validates whatever token is already on [ServerClient.instance] (set
  /// from a remembered session) and refreshes role/username/id — used for
  /// silent auto-login at startup instead of re-sending a password. Fails if
  /// the token expired or the account was deactivated/removed since.
  Future<AuthResult> me() async {
    final client = ServerClient.instance;
    if (!client.isConnected || client.token == null) {
      return const AuthResult(success: false);
    }
    try {
      final res = await http
          .get(client.uri('/auth/me'), headers: client.headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return AuthResult(
          success: true,
          role: data['role'] as String?,
          username: data['username'] as String?,
          id: data['id'] as int?,
        );
      }
      return const AuthResult(success: false);
    } catch (_) {
      return const AuthResult(success: false);
    }
  }
}
