import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/kitchen/customer_kitchen_status_screen.dart';
import 'package:pos/l10n/app_localizations.dart';

void main() {
  testWidgets('customer status board shows the three stage columns and no item detail',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CustomerKitchenStatusScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('PREPARING'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    // No per-item text (menu item names, quantities, notes) belongs here —
    // this board only ever renders order numbers and the column headers.
    expect(find.textContaining('×'), findsNothing);
  });
}
