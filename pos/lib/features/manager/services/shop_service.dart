import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';

class ShopServiceException implements Exception {
  ShopServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Permanently deletes the whole shop server-side — owner-only, no offline
/// fallback, mirrors [StaffService]'s pattern for security-sensitive ops.
class ShopService {
  ShopService._();
  static final instance = ShopService._();

  Future<void> deleteShop({
    required String email,
    required String username,
    required String password,
  }) async {
    final client = ServerClient.instance;
    if (!client.isConnected) {
      throw ShopServiceException('Not connected to a server');
    }

    late final http.Response res;
    try {
      res = await http
          .delete(
            client.uri('/shop'),
            headers: client.headers,
            body: jsonEncode({
              'email': email.trim(),
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ShopServiceException('Could not reach the server');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ShopServiceException(_errorMessage(res));
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Request failed (${res.statusCode})';
    } catch (_) {
      return 'Request failed (${res.statusCode})';
    }
  }
}
