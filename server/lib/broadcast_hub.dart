import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Shared plumbing for a WebSocket hub that accepts receive-only clients,
/// sends each one an initial snapshot, and fans out later events to
/// everyone still connected. [OrderHub]/[KitchenHub]/[MenuHub] each only
/// differ in what their snapshot/broadcast payloads contain.
abstract class BroadcastHub {
  final Set<WebSocketChannel> _channels = {};

  int get count => _channels.length;

  void connect(WebSocketChannel channel, Map<String, dynamic> snapshot) {
    _channels.add(channel);
    channel.sink.add(jsonEncode(snapshot));
    channel.stream.listen(
      (_) {},
      onDone: () => _channels.remove(channel),
      onError: (_) => _channels.remove(channel),
      cancelOnError: true,
    );
  }

  void broadcast(Map<String, dynamic> message) {
    final encoded = jsonEncode(message);
    for (final channel in _channels) {
      try {
        channel.sink.add(encoded);
      } catch (_) {}
    }
  }
}
