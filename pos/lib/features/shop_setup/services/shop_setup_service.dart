import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/shop_setup_data.dart';

class ShopSetupException implements Exception {
  ShopSetupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Bootstraps a brand-new shop on a server that has no users yet — the
/// real counterpart to the Create Shop wizard's "Finish Setup" step.
/// Unlike other services, this doesn't go through [ServerClient] because
/// there's no session yet; [address] is whatever server the wizard is
/// pointed at (currently always this device for local hosting).
class ShopSetupService {
  /// Returns the one-time password-recovery code the server generates
  /// during bootstrap (see `setup_routes.dart`) — the caller must show it
  /// to the owner immediately, since the server only ever returns it here.
  Future<String> createShop(ShopSetupData data, String address) async {
    late final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('http://$address/setup'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'shopName': data.shopName,
              'address': data.address,
              'taxId': data.taxId,
              'email': data.email,
              'receiptFooter': data.receiptFooter,
              'adminUsername': data.adminUsername,
              'adminPassword': data.adminPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ShopSetupException(
          "Couldn't reach a server at $address. Make sure the MinePOS server is running first.");
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['recoveryCode'] as String? ?? '';
    }
    throw ShopSetupException(_errorMessage(res));
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Setup failed (${res.statusCode})';
    } catch (_) {
      return 'Setup failed (${res.statusCode})';
    }
  }
}
