import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/services/server_client.dart';
import '../../cashier/models/order_item.dart';

enum CustomerDisplayConnectionState { disconnected, connecting, connected, error }

enum CustomerDisplayState { idle, cart, thankYou }

/// Two-way bridge to the server's `/ws/customer-display` relay. A cashier
/// device calls [publishCart]/[publishThankYou] to broadcast what's on the
/// register; a passive customer-facing display just reads [state] /
/// [items] / [total] / [orderNumber] as they change. The same service and
/// connection serve both roles — whichever side isn't publishing simply
/// never calls the publish methods.
class CustomerDisplayService extends ChangeNotifier {
  CustomerDisplayService._();
  static final instance = CustomerDisplayService._();

  CustomerDisplayConnectionState connectionState =
      CustomerDisplayConnectionState.disconnected;
  CustomerDisplayState state = CustomerDisplayState.idle;

  List<OrderItem> items = const [];
  double total = 0;
  String orderNumber = '';
  double thankYouTotal = 0;
  double thankYouChange = 0;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _thankYouTimer;
  bool _wantsConnection = false;

  void connect() {
    _wantsConnection = true;
    _connect();
  }

  void _connect() {
    if (!_wantsConnection || _channel != null) return;
    final client = ServerClient.instance;
    if (!client.isConnected) {
      connectionState = CustomerDisplayConnectionState.error;
      notifyListeners();
      return;
    }

    connectionState = CustomerDisplayConnectionState.connecting;
    notifyListeners();

    try {
      final channel =
          WebSocketChannel.connect(client.wsUri('/ws/customer-display'));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
      connectionState = CustomerDisplayConnectionState.connected;
      notifyListeners();
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'cart':
        final incomingItems = (msg['items'] as List)
            .map((j) => OrderItem.fromJson(j as Map<String, dynamic>))
            .toList();
        orderNumber = msg['orderNumber'] as String? ?? '';
        total = (msg['total'] as num?)?.toDouble() ?? 0;
        items = incomingItems;
        state = incomingItems.isEmpty
            ? CustomerDisplayState.idle
            : CustomerDisplayState.cart;
        _thankYouTimer?.cancel();
      case 'thank_you':
        thankYouTotal = (msg['total'] as num?)?.toDouble() ?? 0;
        thankYouChange = (msg['change'] as num?)?.toDouble() ?? 0;
        state = CustomerDisplayState.thankYou;
        items = const [];
        _thankYouTimer?.cancel();
        _thankYouTimer = Timer(const Duration(seconds: 8), () {
          state = CustomerDisplayState.idle;
          notifyListeners();
        });
    }
    notifyListeners();
  }

  void _onDisconnected() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_wantsConnection) {
      connectionState = CustomerDisplayConnectionState.disconnected;
      notifyListeners();
      return;
    }
    connectionState = CustomerDisplayConnectionState.error;
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connect);
  }

  void publishCart({
    required List<OrderItem> items,
    required double total,
    required String orderNumber,
  }) {
    _send({
      'type': 'cart',
      'orderNumber': orderNumber,
      'total': total,
      'items': items.map((i) => i.toJson()).toList(),
    });
  }

  void publishThankYou({required double total, required double change}) {
    _send({'type': 'thank_you', 'total': total, 'change': change});
  }

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void disconnect() {
    _wantsConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _thankYouTimer?.cancel();
    _thankYouTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    items = const [];
    state = CustomerDisplayState.idle;
    connectionState = CustomerDisplayConnectionState.disconnected;
    notifyListeners();
  }
}
