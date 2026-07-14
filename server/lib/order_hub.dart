import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'database.dart';

/// Fans out newly-created orders to every connected client. Order History
/// and the cashier dashboard otherwise only learn about orders placed on
/// other devices at their next login.
class OrderHub {
  OrderHub._();
  static final instance = OrderHub._();

  final Set<WebSocketChannel> _channels = {};

  int get count => _channels.length;

  void add(WebSocketChannel channel, AppDb db) {
    _channels.add(channel);
    channel.sink.add(jsonEncode({
      'type': 'snapshot',
      'orders': db.getOrders().map((o) => o.toJson()).toList(),
    }));
    channel.stream.listen(
      (_) {}, // clients are receive-only
      onDone: () => _channels.remove(channel),
      onError: (_) => _channels.remove(channel),
      cancelOnError: true,
    );
  }

  void broadcastOrderCreated(DbOrder order) {
    _broadcast({'type': 'order_created', 'order': order.toJson()});
  }

  void _broadcast(Map<String, dynamic> message) {
    final encoded = jsonEncode(message);
    for (final channel in _channels) {
      try {
        channel.sink.add(encoded);
      } catch (_) {}
    }
  }
}
