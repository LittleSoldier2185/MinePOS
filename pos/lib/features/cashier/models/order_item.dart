import 'menu_item.dart';

class OrderItem {
  OrderItem({required this.menuItem, this.quantity = 1});

  final MenuItem menuItem;
  int quantity;

  double get subtotal => menuItem.price * quantity;

  OrderItem copy() => OrderItem(menuItem: menuItem, quantity: quantity);
}
