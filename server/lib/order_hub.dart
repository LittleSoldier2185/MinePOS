import 'package:web_socket_channel/web_socket_channel.dart';

import 'broadcast_hub.dart';
import 'database.dart';

/// Fans out newly-created orders to every connected client. Order History
/// and the cashier dashboard otherwise only learn about orders placed on
/// other devices at their next login.
class OrderHub extends BroadcastHub {
  OrderHub._();
  static final instance = OrderHub._();

  void add(WebSocketChannel channel, AppDb db) => connect(channel, {
        'type': 'snapshot',
        'orders': db.getOrders().map((o) => o.toJson()).toList(),
      });

  void broadcastOrderCreated(DbOrder order) => broadcast({'type': 'order_created', 'order': order.toJson()});

  void broadcastOrderStatus(DbOrder order) => broadcast({
        'type': 'order_status',
        'orderId': order.id,
        'status': order.status,
        'cancelReason': order.cancelReason,
      });
}
