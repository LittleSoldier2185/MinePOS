import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';
import '../models/menu_item.dart';

class MenuService {
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
      }
    } catch (_) {}
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  MenuItem addItem({
    required String name,
    required String category,
    required double price,
    bool available = true,
    String? imageBase64,
    bool hasSweetness = false,
    String? nameTh,
  }) {
    final item = MenuItem(
      id: 'u${_nextId++}',
      name: name.trim(),
      category: category.trim(),
      price: price,
      available: available,
      imageBase64: imageBase64,
      hasSweetness: hasSweetness,
      nameTh: nameTh,
    );
    _items.add(item);
    _serverCreate(item);
    return item;
  }

  void updateItem(MenuItem updated) {
    final i = _items.indexWhere((m) => m.id == updated.id);
    if (i >= 0) _items[i] = updated;
    _serverUpdate(updated);
  }

  void deleteItem(String id) {
    _items.removeWhere((m) => m.id == id);
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
    _serverToggle(id);
  }

  // ── Server fire-and-forget helpers ────────────────────────────────────────

  Future<void> _serverCreate(MenuItem item) async {
    final client = ServerClient.instance;
    if (!client.isConnected) return;
    try {
      await http
          .post(client.uri('/menu'),
              headers: client.headers, body: jsonEncode(item.toJson()))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
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
