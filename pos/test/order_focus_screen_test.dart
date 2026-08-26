import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/models/menu_item.dart';
import 'package:pos/features/cashier/models/order.dart';
import 'package:pos/features/cashier/models/order_item.dart';
import 'package:pos/features/kitchen/order_focus_screen.dart';
import 'package:pos/features/kitchen/services/kitchen_service.dart';
import 'package:pos/l10n/app_localizations.dart';

OrderItem _item(int id, String status) => OrderItem(
      id: id,
      status: status,
      menuItem: MenuItem(id: 'c$id', name: 'Espresso', category: 'Coffee', price: 65),
    );

Order _order(List<OrderItem> items) => Order(
      id: 42,
      orderNumber: 7,
      items: items,
      createdAt: DateTime.now(),
      paymentMethod: PaymentMethod.cash,
    );

Widget _host({required void Function(Order, OrderItem) onItemTap, required Future<void> Function(Order) onComplete}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OrderFocusScreen(
        initialOrderId: 42,
        onItemTap: onItemTap,
        onComplete: onComplete,
      ),
    );

void main() {
  tearDown(() => KitchenService.instance.debugSetOrders([]));

  testWidgets('shows a stage badge and the next action per item status',
      (tester) async {
    KitchenService.instance.debugSetOrders([
      _order([_item(1, 'pending'), _item(2, 'preparing'), _item(3, 'ready')]),
    ]);
    var tapped = false;

    await tester.pumpWidget(_host(
      onItemTap: (_, _) => tapped = true,
      onComplete: (_) async {},
    ));
    await tester.pumpAndSettle();

    // Stage badges (upper-cased) for all three states.
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('PREPARING'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);

    // Per-item action button reflects the *next* step.
    expect(find.text('Start Preparing'), findsOneWidget);
    expect(find.text('Ready to Serve'), findsOneWidget);

    await tester.tap(find.text('Start Preparing'));
    expect(tapped, isTrue);

    // Not every item is ready yet → no Complete button.
    expect(find.text('Complete'), findsNothing);
  });

  testWidgets('Complete button appears only once every item is ready',
      (tester) async {
    KitchenService.instance.debugSetOrders([
      _order([_item(1, 'ready'), _item(2, 'ready')]),
    ]);
    var completed = false;

    await tester.pumpWidget(_host(
      onItemTap: (_, _) {},
      onComplete: (_) async => completed = true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Complete'), findsOneWidget);

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
