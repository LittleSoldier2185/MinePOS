import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/order_taking_screen.dart';
import 'package:pos/l10n/app_localizations.dart';

void main() {
  testWidgets('typing in the menu search box filters items across categories',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const OrderTakingScreen(),
    ));
    await tester.pumpAndSettle();

    // Espresso (Coffee) is visible on the default category; Croissant (Food)
    // is not, since it's a different category tab.
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('Croissant'), findsNothing);

    await tester.enterText(find.byType(TextField), 'crois');
    await tester.pump();

    // Search should surface Croissant regardless of category, and hide
    // non-matching items (Espresso) along with the category chip row.
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pump();
    expect(find.text('No matching items'), findsOneWidget);
  });
}
