import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/models/menu_item.dart';
import 'package:pos/features/cashier/models/order.dart';
import 'package:pos/features/cashier/models/order_item.dart';
import 'package:pos/features/kitchen/order_focus_screen.dart';
import 'package:pos/l10n/app_localizations.dart';

OrderItem _item(String status) => OrderItem(
      id: 1,
      status: status,
      menuItem: const MenuItem(id: 'c1', name: 'Espresso', category: 'Coffee', price: 65),
    );

Order _order(List<OrderItem> items) => Order(
      orderNumber: 7,
      items: items,
      createdAt: DateTime.now(),
      paymentMethod: PaymentMethod.cash,
    );

void main() {
  testWidgets('Focus Mode surfaces the right action per item status',
      (tester) async {
    var tapped = false;
    var completed = false;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OrderFocusScreen(
        order: _order([_item('pending'), _item('preparing'), _item('ready')]),
        onItemTap: (_) => tapped = true,
        completeLabel: 'Complete',
        onComplete: () => completed = true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Start Preparing'), findsOneWidget);
    expect(find.text('Ready to Serve'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);

    await tester.tap(find.text('Start Preparing'));
    expect(tapped, isTrue);

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
