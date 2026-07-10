import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/services/server_client.dart';
import '../../cashier/models/order.dart';
import '../../cashier/models/order_item.dart';

enum KitchenConnectionState { disconnected, connecting, connected, error }

/// Live-updating board of in-progress orders, fed by the server's
/// `/ws/kitchen` WebSocket. A singleton so the connection (and its
/// reconnect loop) is shared across any screen that opens the board.
class KitchenService extends ChangeNotifier {
  KitchenService._();
  static final instance = KitchenService._();

  List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);

  KitchenConnectionState state = KitchenConnectionState.disconnected;

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
    if (!client.isConnected) {
      state = KitchenConnectionState.error;
      notifyListeners();
      return;
    }

    state = KitchenConnectionState.connecting;
    notifyListeners();

    try {
      final channel = WebSocketChannel.connect(client.wsUri('/ws/kitchen'));
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
        state = KitchenConnectionState.connected;
        _orders = (msg['orders'] as List)
            .map((j) => Order.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'order_created':
        final order = Order.fromJson(msg['order'] as Map<String, dynamic>);
        _orders = [..._orders, order];
      case 'order_status':
        final orderId = msg['orderId'] as int;
        final newStatus = msg['status'] as String;
        if (newStatus == 'completed') {
          _orders = _orders.where((o) => o.id != orderId).toList();
        } else {
          _orders = _orders
              .map((o) => o.id == orderId
                  ? Order(
                      id: o.id,
                      orderNumber: o.orderNumber,
                      items: o.items,
                      createdAt: o.createdAt,
                      paymentMethod: o.paymentMethod,
                      amountPaid: o.amountPaid,
                      kitchenStatus: newStatus,
                    )
                  : o)
              .toList();
        }
      case 'item_status':
        final orderId = msg['orderId'] as int;
        final itemId = msg['itemId'] as int;
        final newItemStatus = msg['status'] as String;
        _orders = _orders.map((o) {
          if (o.id != orderId) return o;
          final newItems = o.items
              .map((i) => i.id == itemId
                  ? OrderItem(
                      menuItem: i.menuItem,
                      quantity: i.quantity,
                      id: i.id,
                      status: newItemStatus,
                    )
                  : i)
              .toList();
          return Order(
            id: o.id,
            orderNumber: o.orderNumber,
            items: newItems,
            createdAt: o.createdAt,
            paymentMethod: o.paymentMethod,
            amountPaid: o.amountPaid,
            kitchenStatus: o.kitchenStatus,
          );
        }).toList();
    }
    notifyListeners();
  }

  void _onDisconnected() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_wantsConnection) {
      state = KitchenConnectionState.disconnected;
      notifyListeners();
      return;
    }
    state = KitchenConnectionState.error;
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connect);
  }

  Future<void> updateStatus(int orderId, String status) async {
    final client = ServerClient.instance;
    await http
        .patch(
          client.uri('/orders/$orderId/status'),
          headers: client.headers,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));
    // The server echoes the change back over the socket, which updates
    // _orders — no need to optimistically mutate local state here.
  }

  Future<void> updateItemStatus(int orderId, int itemId, String status) async {
    final client = ServerClient.instance;
    await http
        .patch(
          client.uri('/orders/$orderId/items/$itemId/status'),
          headers: client.headers,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));
  }

  void disconnect() {
    _wantsConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _orders = [];
    state = KitchenConnectionState.disconnected;
    notifyListeners();
  }
}
