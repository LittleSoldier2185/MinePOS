import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderService {
  OrderService._();
  static final instance = OrderService._();

  int _nextNumber = 1;

  int get nextOrderNumber => _nextNumber;
  final List<Order> _orders = [];

  // Sorted explicitly by date rather than relying on _orders' internal
  // ordering: loadFromServer() stores newest-first (mirrors the server's
  // own `ORDER BY id DESC`), but complete() appends newly-placed orders to
  // the end of whatever's already there — mixing the two silently produced
  // an out-of-order list.
  List<Order> get orders {
    final sorted = List<Order>.of(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  List<Order> get todaysOrders {
    final today = DateTime.now();
    return _orders.where((o) {
      final d = o.createdAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
  }

  double get todaysRevenue => todaysOrders.fold(0.0, (s, o) => s + o.total);

  /// Completes an order locally and syncs it to the server.
  /// Returns the order — if server sync succeeds the order number
  /// is updated from the server response.
  Future<Order> complete({
    required List<OrderItem> items,
    required PaymentMethod paymentMethod,
    double? amountPaid,
  }) async {
    var order = Order(
      orderNumber: _nextNumber++,
      items: items.map((i) => i.copy()).toList(),
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
    );
    _orders.add(order);

    // Best-effort server sync.
    final client = ServerClient.instance;
    if (client.isConnected) {
      try {
        final res = await http
            .post(
              client.uri('/orders'),
              headers: client.headers,
              body: jsonEncode({
                'paymentMethod': paymentMethod == PaymentMethod.cash
                    ? 'cash'
                    : 'promptpay',
                'amountPaid': amountPaid,
                'items': items.map((i) => i.toJson()).toList(),
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 201) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          // Replace with server-assigned order number.
          final serverNumber = data['orderNumber'] as int;
          final idx = _orders.indexOf(order);
          order = Order(
            orderNumber: serverNumber,
            items: order.items,
            createdAt: order.createdAt,
            paymentMethod: order.paymentMethod,
            amountPaid: order.amountPaid,
          );
          if (idx >= 0) _orders[idx] = order;
          _nextNumber = serverNumber + 1;
        }
      } catch (_) {}
    }

    return order;
  }

  /// Loads order history from the server (replaces in-memory list).
  Future<void> loadFromServer({String? date}) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      final uri = client.uri('/orders${date != null ? '?date=$date' : ''}');
      final res = await http
          .get(uri, headers: client.headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _orders
          ..clear()
          ..addAll(list.map((j) => Order.fromJson(j as Map<String, dynamic>)));
        final todaysNumbers = todaysOrders.map((o) => o.orderNumber);
        _nextNumber = todaysNumbers.isEmpty
            ? 1
            : todaysNumbers.reduce((a, b) => a > b ? a : b) + 1;
      }
    } catch (_) {}
  }
}
