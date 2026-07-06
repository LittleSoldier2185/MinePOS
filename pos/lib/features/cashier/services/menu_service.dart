import '../models/menu_item.dart';

class MenuService {
  static const _items = <MenuItem>[
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

  static const List<String> categories = [
    'Coffee',
    'Tea',
    'Cold',
    'Food',
  ];

  List<MenuItem> itemsForCategory(String category) =>
      _items.where((m) => m.category == category && m.available).toList();

  List<MenuItem> get allAvailable =>
      _items.where((m) => m.available).toList();
}
