import 'package:web_socket_channel/web_socket_channel.dart';

import 'broadcast_hub.dart';
import 'database.dart';

/// Fans out live menu changes to every connected client. Menu Management and
/// Order Taking screens on other devices otherwise have no way to learn that
/// an item was added/edited/deleted/toggled until their next full fetch.
class MenuHub extends BroadcastHub {
  MenuHub._();
  static final instance = MenuHub._();

  void add(WebSocketChannel channel, AppDb db) => connect(channel, {
        'type': 'snapshot',
        'items': db.getMenuItems().map((i) => i.toJson()).toList(),
      });

  void broadcastItemChanged(DbMenuItem item) => broadcast({'type': 'item_changed', 'item': item.toJson()});

  void broadcastItemDeleted(String id) => broadcast({'type': 'item_deleted', 'id': id});
}
