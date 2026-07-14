import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/services/server_client.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderService extends ChangeNotifier {
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
  /// Returns the order — if server sync succeeds the returned order carries
  /// the server-assigned id/order number.
  Future<Order> complete({
    required List<OrderItem> items,
    required PaymentMethod paymentMethod,
    double? amountPaid,
  }) async {
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
          final serverOrder = Order.fromJson(data);
          _nextNumber = serverOrder.orderNumber + 1;
          // The server broadcasts this same order over /ws/orders at
          // essentially the same moment it answers this POST, so our own
          // connection below (if up) will echo it back into `_orders` —
          // possibly *before* this response even finishes parsing. Only
          // insert it here directly when that connection is down, so we
          // never end up with two entries for the same order id.
          if (_channel == null) {
            _orders.add(serverOrder);
          }
          notifyListeners();
          return serverOrder;
        }
      } catch (_) {}
    }

    // Offline/unreachable fallback — keep a client-only copy (no server id)
    // so the receipt and dashboard still work.
    final order = Order(
      orderNumber: _nextNumber++,
      items: items.map((i) => i.copy()).toList(),
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
    );
    _orders.add(order);
    notifyListeners();
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
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Live sync ─────────────────────────────────────────────────────────────
  // Stays connected to /ws/orders for the whole session so an order placed
  // on one device shows up in every other device's history/dashboard stats
  // immediately, instead of only at their next login.

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _wantsConnection = false;

  void connect() {
    _wantsConnection = true;
    _connect();
  }

  void _connect() {
    if (!_wantsConnection || _channel != null) return;
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      final channel = WebSocketChannel.connect(client.wsUri('/ws/orders'));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'snapshot':
        _orders
          ..clear()
          ..addAll((msg['orders'] as List)
              .map((j) => Order.fromJson(j as Map<String, dynamic>)));
        final todaysNumbers = todaysOrders.map((o) => o.orderNumber);
        _nextNumber = todaysNumbers.isEmpty
            ? 1
            : todaysNumbers.reduce((a, b) => a > b ? a : b) + 1;
      case 'order_created':
        final incoming = Order.fromJson(msg['order'] as Map<String, dynamic>);
        final i = _orders.indexWhere((o) => o.id == incoming.id);
        if (i >= 0) {
          _orders[i] = incoming;
        } else {
          _orders.add(incoming);
        }
        if (incoming.orderNumber >= _nextNumber) {
          _nextNumber = incoming.orderNumber + 1;
        }
    }
    notifyListeners();
  }

  void _onDisconnected() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_wantsConnection) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connect);
  }

  void disconnect() {
    _wantsConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }
}
