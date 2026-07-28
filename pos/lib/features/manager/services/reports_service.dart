import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/server_client.dart';
import '../../cashier/models/order.dart';

/// Read-only order history for the Reports screen. Deliberately independent
/// of [OrderService] — that singleton backs the live dashboard/history
/// views, and swapping its list to an arbitrary report date range would
/// corrupt "today's" figures shown elsewhere.
class ReportsService {
  ReportsService._();
  static final instance = ReportsService._();

  /// Fetches orders in [from, to) (half-open, both optional) so Reports only
  /// pulls the range it's actually displaying instead of the whole history.
  ///
  /// Deliberately sent as naive local time, not UTC: `orders.created_at` is
  /// stored server-side via plain `DateTime.now().toIso8601String()` (see
  /// `AppDb.createOrder`), i.e. the server's own local wall clock with no
  /// timezone marker — same "no real offset math, just matching text"
  /// assumption the rest of the app already makes for order timestamps
  /// (client and server are expected to share a timezone, same as any single
  /// LAN-connected shop). Sending a real UTC instant here would silently
  /// shift the range by the server's UTC offset instead of matching it.
  Future<List<Order>> fetchOrders({DateTime? from, DateTime? to}) async {
    final query = <String, String>{
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };
    final uri = ServerClient.instance.uri('/orders').replace(queryParameters: query.isEmpty ? null : query);
    final res = await apiSend(
      () => http.get(uri, headers: ServerClient.instance.headers),
      timeout: const Duration(seconds: 15),
    );
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
  }
}
