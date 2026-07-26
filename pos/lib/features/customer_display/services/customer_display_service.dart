import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/services/server_client.dart';
import '../../cashier/models/order_item.dart';

enum CustomerDisplayConnectionState { disconnected, connecting, connected, error }

enum CustomerDisplayState { idle, cart, promptpay, thankYou }

/// One slide in the idle-time advertising slideshow (see `AdService` for the
/// owner-facing upload/management side). Shop-wide — not per-station, same
/// as [CustomerDisplayService.stations] isn't either.
class AdSlide {
  AdSlide({required this.id, required this.type, required this.url, this.durationSeconds});

  final String id;

  /// 'image' or 'video' — a GIF is served as 'image'.
  final String type;

  /// Relative path from the server (e.g. `/ads/<id>/file`) — build the full
  /// address by prefixing `http://${ServerClient.instance.baseUrl}`.
  final String url;

  /// Only meaningful for image/gif; null for video (plays to its own end).
  final int? durationSeconds;

  factory AdSlide.fromJson(Map<String, dynamic> json) => AdSlide(
        id: json['id'] as String,
        type: json['type'] as String,
        url: json['url'] as String,
        durationSeconds: json['durationSeconds'] as int?,
      );
}

/// Two-way bridge to the server's `/ws/customer-display` relay. A cashier
/// device calls [publishCart]/[publishPromptPay]/[publishThankYou] to
/// broadcast what's on the register; a passive customer-facing display just
/// reads [state] / [items] / [total] / [orderNumber] / [promptPayPayload] as
/// they change. The same service and connection serve both roles —
/// whichever side isn't publishing simply never calls the publish methods.
class CustomerDisplayService extends ChangeNotifier {
  CustomerDisplayService._();
  static final instance = CustomerDisplayService._();

  CustomerDisplayConnectionState connectionState =
      CustomerDisplayConnectionState.disconnected;
  CustomerDisplayState state = CustomerDisplayState.idle;

  List<OrderItem> items = const [];
  double total = 0;
  String orderNumber = '';
  String promptPayPayload = '';
  String promptPayLabel = '';
  double thankYouTotal = 0;
  double thankYouChange = 0;

  /// Sum of whatever promotions applied to the mirrored cart, and their
  /// names — only meaningful once the cashier reaches checkout (see
  /// `payment_screen.dart`'s `publishCart` call); the order-taking
  /// screen's own `publishCart` never evaluates promotions, so this stays
  /// zero/empty while a customer's items are just being built up.
  double discountTotal = 0;
  List<String> promotionNames = const [];

  /// Station names currently publishing carts (only meaningful for a
  /// passive display connection — a publisher never receives this).
  List<String> stations = const [];

  /// The idle-time advertising slideshow content, shop-wide — pushed by the
  /// server on connect and whenever Settings → Advertising changes it (see
  /// `CustomerDisplayHub.broadcastAdSlides` server-side). Only meaningful
  /// for a passive display connection, same as [stations].
  List<AdSlide> adSlides = const [];

  /// Which station this display is currently mirroring; null means "not
  /// picked yet" (or picked, then that station went offline).
  String? selectedStation;

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
      // A logged-in station (has a deviceName) connects as a publisher under
      // that name; a passive customer-facing display (no login, no
      // deviceName) connects with no station and picks one after seeing the
      // live list (see `selectStation`).
      final station = client.deviceName;
      final channel = WebSocketChannel.connect(client.wsUri(
        '/ws/customer-display',
        query: station != null ? {'station': station} : null,
      ));
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
      case 'stations':
        stations = (msg['stations'] as List).cast<String>();
        // The station this display was mirroring went offline (cashier
        // logged out/closed the app) — fall back to the picker rather than
        // leave a stale cart on screen forever.
        if (selectedStation != null && !stations.contains(selectedStation)) {
          selectedStation = null;
          items = const [];
          state = CustomerDisplayState.idle;
        }
      case 'ads':
        adSlides = (msg['slides'] as List)
            .map((j) => AdSlide.fromJson(j as Map<String, dynamic>))
            .toList();
      case 'cart':
        final incomingItems = (msg['items'] as List)
            .map((j) => OrderItem.fromJson(j as Map<String, dynamic>))
            .toList();
        orderNumber = msg['orderNumber'] as String? ?? '';
        total = (msg['total'] as num?)?.toDouble() ?? 0;
        items = incomingItems;
        discountTotal = (msg['discountTotal'] as num?)?.toDouble() ?? 0;
        promotionNames = (msg['promotionNames'] as List?)?.cast<String>() ?? const [];
        state = incomingItems.isEmpty
            ? CustomerDisplayState.idle
            : CustomerDisplayState.cart;
        _thankYouTimer?.cancel();
      case 'promptpay':
        promptPayPayload = msg['payload'] as String? ?? '';
        promptPayLabel = msg['label'] as String? ?? '';
        orderNumber = msg['orderNumber'] as String? ?? '';
        total = (msg['total'] as num?)?.toDouble() ?? 0;
        state = CustomerDisplayState.promptpay;
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
    double discountTotal = 0,
    List<String> promotionNames = const [],
  }) {
    _send({
      'type': 'cart',
      'orderNumber': orderNumber,
      'total': total,
      'items': items.map((i) => i.toJson()).toList(),
      'discountTotal': discountTotal,
      'promotionNames': promotionNames,
    });
  }

  void publishPromptPay({
    required String payload,
    required double total,
    required String orderNumber,
    String label = '',
  }) {
    _send({
      'type': 'promptpay',
      'payload': payload,
      'total': total,
      'orderNumber': orderNumber,
      'label': label,
    });
  }

  void publishThankYou({required double total, required double change}) {
    _send({'type': 'thank_you', 'total': total, 'change': change});
  }

  /// Called by a passive display to start (or stop, with null) mirroring a
  /// station's cart. Only meaningful for a subscriber connection — a
  /// publisher (a cashier register) never calls this.
  void selectStation(String? station) {
    selectedStation = station;
    if (station == null) {
      items = const [];
      promptPayPayload = '';
      promptPayLabel = '';
      state = CustomerDisplayState.idle;
    }
    _send({'type': 'select_station', 'station': station});
    notifyListeners();
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
    promptPayPayload = '';
    promptPayLabel = '';
    discountTotal = 0;
    promotionNames = const [];
    state = CustomerDisplayState.idle;
    stations = const [];
    adSlides = const [];
    selectedStation = null;
    connectionState = CustomerDisplayConnectionState.disconnected;
    notifyListeners();
  }
}
