import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';

class ShopConfigServiceException implements Exception {
  ShopConfigServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Caches the shop's own display details (name, address, tax ID, receipt
/// footer) fetched once at login — read synchronously wherever a
/// BuildContext isn't available (the printer builds a ticket with no
/// widget tree behind it), same reasoning as [AppSettingsService].
class ShopConfigService {
  ShopConfigService._();
  static final instance = ShopConfigService._();

  String shopName = 'MinePOS';
  String? address;
  String? taxId;
  String? email;
  String? receiptFooter;

  Future<void> fetch() async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      final res = await http
          .get(client.uri('/shop'), headers: client.headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        shopName = data['shopName'] as String? ?? shopName;
        address = data['address'] as String?;
        taxId = data['taxId'] as String?;
        email = data['email'] as String?;
        receiptFooter = data['receiptFooter'] as String?;
      }
    } catch (_) {}
  }

  Future<void> update({
    required String shopName,
    String? address,
    String? taxId,
    String? email,
    String? receiptFooter,
  }) async {
    final client = ServerClient.instance;
    if (!client.isConnected) {
      throw ShopConfigServiceException('Not connected to a server');
    }

    late final http.Response res;
    try {
      res = await http
          .patch(
            client.uri('/shop'),
            headers: client.headers,
            body: jsonEncode({
              'shopName': shopName.trim(),
              'address': address?.trim(),
              'taxId': taxId?.trim(),
              'email': email?.trim(),
              'receiptFooter': receiptFooter?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ShopConfigServiceException('Could not reach the server');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      this.shopName = data['shopName'] as String? ?? this.shopName;
      this.address = data['address'] as String?;
      this.taxId = data['taxId'] as String?;
      this.email = data['email'] as String?;
      this.receiptFooter = data['receiptFooter'] as String?;
      return;
    }
    throw ShopConfigServiceException(_errorMessage(res));
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
