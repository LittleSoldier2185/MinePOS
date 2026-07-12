import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'database.dart';

/// Fans out live order events to every connected Kitchen Display client.
/// Each new connection is sent a snapshot of the current active orders, then
/// receives `order_created` / `order_status` events as they happen.
class KitchenHub {
  KitchenHub._();
  static final instance = KitchenHub._();

  final Set<WebSocketChannel> _channels = {};

  int get count => _channels.length;

  void add(WebSocketChannel channel, AppDb db) {
    _channels.add(channel);
    channel.sink.add(jsonEncode({
      'type': 'snapshot',
      'orders': db.getActiveOrders().map((o) => o.toJson()).toList(),
    }));
    channel.stream.listen(
      (_) {}, // kitchen clients are receive-only
      onDone: () => _channels.remove(channel),
      onError: (_) => _channels.remove(channel),
      cancelOnError: true,
    );
  }

  void broadcastOrderCreated(DbOrder order) {
    _broadcast({'type': 'order_created', 'order': order.toJson()});
  }

  void broadcastOrderStatus(DbOrder order) {
    _broadcast({
      'type': 'order_status',
      'orderId': order.id,
      'status': order.status,
    });
  }

  void broadcastItemStatus(DbOrder order, int itemId) {
    final item = order.items.firstWhere((i) => i.id == itemId);
    _broadcast({
      'type': 'item_status',
      'orderId': order.id,
      'itemId': itemId,
      'status': item.status,
    });
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
