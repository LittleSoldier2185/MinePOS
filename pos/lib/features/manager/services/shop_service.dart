import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/server_client.dart';

/// Permanently deletes the whole shop server-side — owner-only, no offline
/// fallback, mirrors [StaffService]'s pattern for security-sensitive ops.
class ShopService {
  ShopService._();
  static final instance = ShopService._();

  Future<void> deleteShop({
    required String email,
    required String username,
    required String password,
  }) =>
      apiSend(() => http.delete(
            ServerClient.instance.uri('/shop'),
            headers: ServerClient.instance.headers,
            body: jsonEncode({
              'email': email.trim(),
              'username': username.trim(),
              'password': password,
            }),
          ));
}
