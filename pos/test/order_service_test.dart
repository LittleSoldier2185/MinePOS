import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/models/order.dart';
import 'package:pos/features/cashier/models/order_item.dart';
import 'package:pos/features/cashier/models/menu_item.dart';
import 'package:pos/features/cashier/services/order_service.dart';

Order _order(String kitchenStatus, double price) => Order(
      orderNumber: 1,
      items: [
        OrderItem(
          menuItem: MenuItem(id: 'i1', name: 'i1', category: 'c', price: price),
        )
      ],
      createdAt: DateTime.now(),
      paymentMethod: PaymentMethod.cash,
      kitchenStatus: kitchenStatus,
    );

void main() {
  test('excludeCancelled drops cancelled orders from sales figures', () {
    final orders = [_order('completed', 100), _order('cancelled', 50)];
    final result = OrderService.excludeCancelled(orders);
    expect(result.length, 1);
    expect(result.fold(0.0, (s, o) => s + o.total), 100);
  });
}
