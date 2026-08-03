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

  /// Invalidates the current password-recovery code and returns a fresh
  /// one — shown to the owner exactly once, same treatment as the code
  /// shown at shop bootstrap (`CreateShopScreen`).
  Future<String> regenerateRecoveryCode() async {
    final res = await apiSend(() => http.post(
          ServerClient.instance.uri('/admin/recovery-code/regenerate'),
          headers: ServerClient.instance.headers,
        ));
    return (jsonDecode(res.body) as Map<String, dynamic>)['recoveryCode'] as String;
  }
}
