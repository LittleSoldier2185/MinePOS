import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'database.dart';

/// Relays live cart state from a cashier station to whichever
/// customer-facing display(s) have chosen to mirror it. Two kinds of
/// connection share this one hub:
///  - a *publisher* (a cashier register) connects with a station name and
///    sends `cart`/`thank_you` messages;
///  - a *subscriber* (a customer-facing display) connects with no station
///    name, receives the live list of publisher station names, and sends
///    `select_station` once the person running it picks which register to
///    mirror.
/// This exists because a shop can run multiple registers at once — without
/// a station name, a display has no way to tell which register's cart it's
/// looking at, and two registers' updates would interleave on-screen.
class CustomerDisplayHub {
  CustomerDisplayHub._();
  static final instance = CustomerDisplayHub._();

  final Map<WebSocketChannel, String> _publishers = {};
  final Map<WebSocketChannel, String?> _subscribers = {};

  /// Cached so a freshly-connecting subscriber can be sent the current list
  /// immediately (see [addSubscriber]) without needing a DB handle passed
  /// in just for that — set once via [broadcastAdSlides] whenever
  /// `ad_routes.dart` changes the list.
  List<Map<String, dynamic>> _adSlidesJson = const [];

  /// Real customer-facing display connections — what `/admin/presence`
  /// reports, distinct from cashier registers that merely publish here.
  int get count => _subscribers.length;

  void addPublisher(WebSocketChannel channel, String station) {
    _publishers[channel] = station;
    channel.stream.listen(
      (message) => _relay(from: channel, message: message),
      onDone: () => _removePublisher(channel),
      onError: (_) => _removePublisher(channel),
      cancelOnError: true,
    );
    _broadcastStations();
  }

  void addSubscriber(WebSocketChannel channel) {
    _subscribers[channel] = null;
    channel.sink.add(_stationsMessage());
    channel.sink.add(_adSlidesMessage());
    channel.stream.listen(
      (message) => _handleSubscriberMessage(channel, message),
      onDone: () => _subscribers.remove(channel),
      onError: (_) => _subscribers.remove(channel),
      cancelOnError: true,
    );
  }

  void _removePublisher(WebSocketChannel channel) {
    _publishers.remove(channel);
    _broadcastStations();
  }

  void _handleSubscriberMessage(WebSocketChannel channel, dynamic raw) {
    if (!_subscribers.containsKey(channel)) return;
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      if (msg['type'] == 'select_station') {
        _subscribers[channel] = msg['station'] as String?;
      }
    } catch (_) {}
  }

  String _stationsMessage() =>
      jsonEncode({'type': 'stations', 'stations': _publishers.values.toSet().toList()..sort()});

  void _broadcastStations() {
    final encoded = _stationsMessage();
    for (final channel in _subscribers.keys) {
      try {
        channel.sink.add(encoded);
      } catch (_) {}
    }
  }

  String _adSlidesMessage() => jsonEncode({'type': 'ads', 'slides': _adSlidesJson});

  /// Called once at server startup (to seed [_adSlidesJson] from the DB
  /// before any display connects) and again by `ad_routes.dart` whenever the
  /// list changes — pushes shop-wide to every connected display, the same
  /// as [_broadcastStations]; ads aren't per-station.
  void broadcastAdSlides(List<DbAdSlide> slides) {
    _adSlidesJson = slides.map((s) => s.toJson()).toList();
    final encoded = _adSlidesMessage();
    for (final channel in _subscribers.keys) {
      try {
        channel.sink.add(encoded);
      } catch (_) {}
    }
  }

  void _relay({required WebSocketChannel from, required dynamic message}) {
    final station = _publishers[from];
    if (station == null) return;
    for (final entry in _subscribers.entries) {
      if (entry.value == station) {
        try {
          entry.key.sink.add(message);
        } catch (_) {}
      }
    }
  }
}
