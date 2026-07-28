import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/server_client.dart';

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
  String? promptPayId;
  String? promptPayLabel;

  /// Drops any in-memory config from a previous shop's session. Call
  /// whenever leaving a shop (logout, delete shop).
  void reset() {
    shopName = 'MinePOS';
    address = null;
    taxId = null;
    email = null;
    receiptFooter = null;
    promptPayId = null;
    promptPayLabel = null;
  }

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
        promptPayId = data['promptPayId'] as String?;
        promptPayLabel = data['promptPayLabel'] as String?;
      }
    } catch (_) {}
  }

  Future<void> update({
    required String shopName,
    String? address,
    String? taxId,
    String? email,
    String? receiptFooter,
    String? promptPayId,
    String? promptPayLabel,
  }) async {
    final res = await apiSend(() => http.patch(
          ServerClient.instance.uri('/shop'),
          headers: ServerClient.instance.headers,
          body: jsonEncode({
            'shopName': shopName.trim(),
            'address': address?.trim(),
            'taxId': taxId?.trim(),
            'email': email?.trim(),
            'receiptFooter': receiptFooter?.trim(),
            'promptPayId': promptPayId?.trim(),
            'promptPayLabel': promptPayLabel?.trim(),
          }),
        ));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    this.shopName = data['shopName'] as String? ?? this.shopName;
    this.address = data['address'] as String?;
    this.taxId = data['taxId'] as String?;
    this.email = data['email'] as String?;
    this.receiptFooter = data['receiptFooter'] as String?;
    this.promptPayId = data['promptPayId'] as String?;
    this.promptPayLabel = data['promptPayLabel'] as String?;
  }
}
