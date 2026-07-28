import 'package:web_socket_channel/web_socket_channel.dart';

import 'broadcast_hub.dart';
import 'database.dart';

/// Fans out live order events to every connected Kitchen Display client.
/// Each new connection is sent a snapshot of the current active orders, then
/// receives `order_created` / `order_status` events as they happen.
class KitchenHub extends BroadcastHub {
  KitchenHub._();
  static final instance = KitchenHub._();

  void add(WebSocketChannel channel, AppDb db) => connect(channel, {
        'type': 'snapshot',
        'orders': db.getActiveOrders().map((o) => o.toJson()).toList(),
      });

  void broadcastOrderCreated(DbOrder order) => broadcast({'type': 'order_created', 'order': order.toJson()});

  void broadcastOrderStatus(DbOrder order) => broadcast({
        'type': 'order_status',
        'orderId': order.id,
        'status': order.status,
        'cancelReason': order.cancelReason,
      });

  void broadcastItemStatus(DbOrder order, int itemId) {
    final item = order.items.firstWhere((i) => i.id == itemId);
    broadcast({
      'type': 'item_status',
      'orderId': order.id,
      'itemId': itemId,
      'status': item.status,
    });
  }
}
