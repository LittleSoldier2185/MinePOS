import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/services/server_client.dart';
import '../models/menu_item.dart';

class MenuService extends ChangeNotifier {
  MenuService._();
  static final instance = MenuService._();

  static const _defaultItems = <MenuItem>[
    // Coffee
    MenuItem(id: 'c1', name: 'Espresso', category: 'Coffee', price: 65),
    MenuItem(id: 'c2', name: 'Americano', category: 'Coffee', price: 75),
    MenuItem(id: 'c3', name: 'Latte', category: 'Coffee', price: 90),
    MenuItem(id: 'c4', name: 'Cappuccino', category: 'Coffee', price: 90),
    MenuItem(id: 'c5', name: 'Mocha', category: 'Coffee', price: 95),
    MenuItem(id: 'c6', name: 'Flat White', category: 'Coffee', price: 95),
    MenuItem(id: 'c7', name: 'Macchiato', category: 'Coffee', price: 85),
    MenuItem(id: 'c8', name: 'Cold Brew', category: 'Coffee', price: 100),
    // Tea
    MenuItem(id: 't1', name: 'Thai Milk Tea', category: 'Tea', price: 65),
    MenuItem(id: 't2', name: 'Green Tea Latte', category: 'Tea', price: 85),
    MenuItem(id: 't3', name: 'Matcha Latte', category: 'Tea', price: 95),
    MenuItem(id: 't4', name: 'Chamomile', category: 'Tea', price: 70),
    MenuItem(id: 't5', name: 'Earl Grey', category: 'Tea', price: 70),
    // Cold
    MenuItem(id: 'k1', name: 'Fresh Orange', category: 'Cold', price: 75),
    MenuItem(id: 'k2', name: 'Lemonade', category: 'Cold', price: 70),
    MenuItem(id: 'k3', name: 'Strawberry Smoothie', category: 'Cold', price: 95),
    MenuItem(id: 'k4', name: 'Mango Smoothie', category: 'Cold', price: 95),
    MenuItem(id: 'k5', name: 'Iced Chocolate', category: 'Cold', price: 90),
    // Food
    MenuItem(id: 'f1', name: 'Croissant', category: 'Food', price: 65),
    MenuItem(id: 'f2', name: 'Toast & Jam', category: 'Food', price: 55),
    MenuItem(id: 'f3', name: 'Club Sandwich', category: 'Food', price: 120),
    MenuItem(id: 'f4', name: 'Banana Cake', category: 'Food', price: 70),
    MenuItem(id: 'f5', name: 'Choco Muffin', category: 'Food', price: 75),
    MenuItem(id: 'f6', name: 'Waffle', category: 'Food', price: 110),
  ];

  static const _categoryOrder = ['Coffee', 'Tea', 'Cold', 'Food'];

  final List<MenuItem> _items = List.of(_defaultItems);
  int _nextId = 1000;

  // ── Read ──────────────────────────────────────────────────────────────────

  List<String> get categories {
    final present = _items.map((m) => m.category).toSet();
    return [
      ..._categoryOrder.where(present.contains),
      ...present.where((c) => !_categoryOrder.contains(c)),
    ];
  }

  List<MenuItem> itemsForCategory(String category) =>
      _items.where((m) => m.category == category && m.available).toList();

  List<MenuItem> get allAvailable =>
      _items.where((m) => m.available).toList();

  List<MenuItem> get allItems => List.unmodifiable(_items);

  List<MenuItem> allItemsForCategory(String category) =>
      _items.where((m) => m.category == category).toList();

  // ── Server sync ───────────────────────────────────────────────────────────

  /// Loads menu from server if connected; silently keeps local state on failure.
  Future<void> fetchFromServer() async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      final res = await http
          .get(client.uri('/menu'), headers: client.headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _items
          ..clear()
          ..addAll(list.map(
              (j) => MenuItem.fromJson(j as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Live sync ─────────────────────────────────────────────────────────────
  // Every device with the menu open (Menu Management, Order Taking) stays
  // connected to /ws/menu for the whole session, so an add/edit/delete/toggle
  // made on one device shows up on every other device immediately instead of
  // only on their next login/fetch.

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _wantsConnection = false;

  void connect() {
    _wantsConnection = true;
    _connect();
  }

  void _connect() {
    if (!_wantsConnection || _channel != null) return;
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      final channel = WebSocketChannel.connect(client.wsUri('/ws/menu'));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'snapshot':
        _items
          ..clear()
          ..addAll((msg['items'] as List)
              .map((j) => MenuItem.fromJson(j as Map<String, dynamic>)));
      case 'item_changed':
        final item = MenuItem.fromJson(msg['item'] as Map<String, dynamic>);
        final i = _items.indexWhere((m) => m.id == item.id);
        if (i >= 0) {
          _items[i] = item;
        } else {
          _items.add(item);
        }
      case 'item_deleted':
        _items.removeWhere((m) => m.id == msg['id']);
    }
    notifyListeners();
  }

  void _onDisconnected() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_wantsConnection) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _connect);
  }

  void disconnect() {
    _wantsConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  // ── Write ─────────────────────────────────────────────────────────────────
  // Create/update/delete/toggle all fire the request then rely on our own
  // /ws/menu connection to apply the confirmed result to `_items` — this
  // avoids the item this device just created carrying a different id locally
  // than the one the server actually assigned (which used to cause a
  // duplicate-looking row once that broadcast arrived). If the server is
  // unreachable, each falls back to a local-only mutation so the screen
  // still responds.

  Future<MenuItem> addItem({
    required String name,
    required String category,
    required double price,
    bool available = true,
    String? imageBase64,
    bool hasSweetness = false,
    String? nameTh,
  }) async {
    final draft = MenuItem(
      id: 'u${_nextId++}',
      name: name.trim(),
      category: category.trim(),
      price: price,
      available: available,
      imageBase64: imageBase64,
      hasSweetness: hasSweetness,
      nameTh: nameTh,
    );
    final created = await _serverCreate(draft);
    final item = created ?? draft;
    if (created == null) {
      _items.add(item);
      notifyListeners();
    }
    return item;
  }

  void updateItem(MenuItem updated) {
    final i = _items.indexWhere((m) => m.id == updated.id);
    if (i >= 0) _items[i] = updated;
    notifyListeners();
    _serverUpdate(updated);
  }

  void deleteItem(String id) {
    _items.removeWhere((m) => m.id == id);
    notifyListeners();
    _serverDelete(id);
  }

  void toggleAvailability(String id) {
    final i = _items.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final m = _items[i];
    _items[i] = MenuItem(
      id: m.id,
      name: m.name,
      category: m.category,
      price: m.price,
      available: !m.available,
      imageBase64: m.imageBase64,
      hasSweetness: m.hasSweetness,
      nameTh: m.nameTh,
    );
    notifyListeners();
    _serverToggle(id);
  }

  // ── Server helpers ────────────────────────────────────────────────────────

  /// Returns the server-assigned item (with its real id) on success, or
  /// `null` if unreachable/disconnected.
  Future<MenuItem?> _serverCreate(MenuItem item) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return null;
    try {
      final res = await http
          .post(client.uri('/menu'),
              headers: client.headers, body: jsonEncode(item.toJson()))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 201) {
        return MenuItem.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _serverUpdate(MenuItem item) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      await http
          .put(client.uri('/menu/${item.id}'),
              headers: client.headers, body: jsonEncode(item.toJson()))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _serverDelete(String id) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      await http
          .delete(client.uri('/menu/$id'), headers: client.headers)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _serverToggle(String id) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      await http
          .patch(client.uri('/menu/$id/toggle'), headers: client.headers)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
