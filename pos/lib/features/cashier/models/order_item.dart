import 'menu_item.dart';

class OrderItem {
  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.id,
    this.status = 'pending',
  });

  final MenuItem menuItem;
  int quantity;

  /// Server-assigned row id — null for cart items that haven't been sent to
  /// the server yet (only meaningful once an order exists, for the Kitchen
  /// Display's per-item status route).
  final int? id;

  /// Kitchen prep state: "pending" | "preparing" | "ready". Only meaningful
  /// on items pulled from the Kitchen Display's live orders — cart items
  /// never set or read this.
  final String status;

  double get subtotal => menuItem.price * quantity;

  OrderItem copy() => OrderItem(menuItem: menuItem, quantity: quantity);

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int?,
        menuItem: MenuItem(
          id: json['menuItemId'] as String,
          name: json['menuItemName'] as String,
          category: json['menuItemCategory'] as String,
          price: (json['price'] as num).toDouble(),
        ),
        quantity: json['quantity'] as int,
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItem.id,
        'menuItemName': menuItem.name,
        'menuItemCategory': menuItem.category,
        'price': menuItem.price,
        'quantity': quantity,
        'status': status,
      };
}
