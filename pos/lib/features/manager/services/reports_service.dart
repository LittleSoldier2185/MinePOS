import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';
import '../../cashier/models/order.dart';

class ReportsServiceException implements Exception {
  ReportsServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Read-only order history for the Reports screen. Deliberately independent
/// of [OrderService] — that singleton backs the live dashboard/history
/// views, and swapping its list to an arbitrary report date range would
/// corrupt "today's" figures shown elsewhere.
class ReportsService {
  ReportsService._();
  static final instance = ReportsService._();

  /// Fetches every stored order once; callers filter by date range locally.
  Future<List<Order>> fetchAllOrders() async {
    final client = ServerClient.instance;
    if (!client.isConnected) {
      throw ReportsServiceException('Not connected to a server');
    }
    late final http.Response res;
    try {
      res = await http
          .get(client.uri('/orders'), headers: client.headers)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ReportsServiceException('Could not reach the server');
    }
    if (res.statusCode != 200) {
      throw ReportsServiceException('Request failed (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List;
    return list
        .map((j) => Order.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
