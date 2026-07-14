import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'database.dart';

/// Fans out live menu changes to every connected client. Menu Management and
/// Order Taking screens on other devices otherwise have no way to learn that
/// an item was added/edited/deleted/toggled until their next full fetch.
class MenuHub {
  MenuHub._();
  static final instance = MenuHub._();

  final Set<WebSocketChannel> _channels = {};

  int get count => _channels.length;

  void add(WebSocketChannel channel, AppDb db) {
    _channels.add(channel);
    channel.sink.add(jsonEncode({
      'type': 'snapshot',
      'items': db.getMenuItems().map((i) => i.toJson()).toList(),
    }));
    channel.stream.listen(
      (_) {}, // menu clients are receive-only
      onDone: () => _channels.remove(channel),
      onError: (_) => _channels.remove(channel),
      cancelOnError: true,
    );
  }

  void broadcastItemChanged(DbMenuItem item) {
    _broadcast({'type': 'item_changed', 'item': item.toJson()});
  }

  void broadcastItemDeleted(String id) {
    _broadcast({'type': 'item_deleted', 'id': id});
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
