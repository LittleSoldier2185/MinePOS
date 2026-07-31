import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/models/menu_item.dart';
import 'package:pos/features/cashier/models/order.dart';
import 'package:pos/features/cashier/models/order_item.dart';

Order _order() => Order(
      orderNumber: 1,
      items: [
        OrderItem(
          id: 1,
          menuItem: const MenuItem(id: 'i1', name: 'Latte', category: 'Coffee', price: 65),
        ),
      ],
      createdAt: DateTime.now(),
      paymentMethod: PaymentMethod.cash,
      note: 'No milk',
      kitchenStatus: 'pending',
    );

void main() {
  // KitchenService rebuilds Order objects from live WebSocket events
  // (order_status/item_status) via copyWith — a manual field-by-field
  // reconstruction here previously dropped `note` (and other fields) on
  // every such update, which is why order notes disappeared from Kitchen
  // Display/Focus Mode after the first status change.
  test('copyWith(kitchenStatus:) preserves note and other fields', () {
    final updated = _order().copyWith(kitchenStatus: 'preparing');
    expect(updated.kitchenStatus, 'preparing');
    expect(updated.note, 'No milk');
    expect(updated.items, hasLength(1));
  });

  test('copyWith(items:) preserves note and kitchenStatus', () {
    final original = _order();
    final newItems = [
      OrderItem(id: 1, status: 'preparing', menuItem: original.items.first.menuItem),
    ];
    final updated = original.copyWith(items: newItems);
    expect(updated.items.single.status, 'preparing');
    expect(updated.note, 'No milk');
    expect(updated.kitchenStatus, 'pending');
  });
}
