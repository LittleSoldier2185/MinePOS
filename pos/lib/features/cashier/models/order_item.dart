import 'menu_item.dart';

class OrderItem {
  OrderItem({required this.menuItem, this.quantity = 1});

  final MenuItem menuItem;
  int quantity;

  double get subtotal => menuItem.price * quantity;

  OrderItem copy() => OrderItem(menuItem: menuItem, quantity: quantity);

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItem: MenuItem(
          id: json['menuItemId'] as String,
          name: json['menuItemName'] as String,
          category: json['menuItemCategory'] as String,
          price: (json['price'] as num).toDouble(),
        ),
        quantity: json['quantity'] as int,
      );

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItem.id,
        'menuItemName': menuItem.name,
        'menuItemCategory': menuItem.category,
        'price': menuItem.price,
        'quantity': quantity,
      };
}
