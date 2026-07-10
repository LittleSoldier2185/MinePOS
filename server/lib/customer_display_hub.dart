import 'package:web_socket_channel/web_socket_channel.dart';

/// Relays live cart state from a cashier device to any connected
/// customer-facing display device(s). Unlike [KitchenHub] the server holds
/// no state of its own here — it just forwards whatever JSON message one
/// connected client sends to every *other* connected client.
class CustomerDisplayHub {
  CustomerDisplayHub._();
  static final instance = CustomerDisplayHub._();

  final Set<WebSocketChannel> _channels = {};

  void add(WebSocketChannel channel) {
    _channels.add(channel);
    channel.stream.listen(
      (message) => _relay(from: channel, message: message),
      onDone: () => _channels.remove(channel),
      onError: (_) => _channels.remove(channel),
      cancelOnError: true,
    );
  }

  void _relay({required WebSocketChannel from, required dynamic message}) {
    for (final channel in _channels) {
      if (identical(channel, from)) continue;
      try {
        channel.sink.add(message);
      } catch (_) {}
    }
  }
}
