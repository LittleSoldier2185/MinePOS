import '../models/order.dart';
import '../models/order_item.dart';

class OrderService {
  OrderService._();
  static final instance = OrderService._();

  int _nextNumber = 1;

  int get nextOrderNumber => _nextNumber;
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());

  List<Order> get todaysOrders {
    final today = DateTime.now();
    return _orders.where((o) {
      final d = o.createdAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
  }

  double get todaysRevenue =>
      todaysOrders.fold(0.0, (s, o) => s + o.total);

  Order complete({
    required List<OrderItem> items,
    required PaymentMethod paymentMethod,
    double? amountPaid,
  }) {
    final order = Order(
      orderNumber: _nextNumber++,
      items: items.map((i) => i.copy()).toList(),
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
    );
    _orders.add(order);
    return order;
  }
}
