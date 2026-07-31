import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/order_taking_screen.dart';
import 'package:pos/l10n/app_localizations.dart';

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets(
      'cart survives navigating away and is restored on the next order screen',
      (tester) async {
    // Default test surface is narrower than this screen's wide-layout
    // breakpoint expects, causing unrelated RenderFlex overflow warnings.
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderTakingScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    // Open the order screen and add one Espresso to the cart.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Espresso'));
    await tester.pump();
    expect(find.text('1'), findsWidgets); // qty badge

    // Back out without checking out — this disposes the screen mid-order.
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Reopen a fresh order screen: the held cart should reappear.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Espresso'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Resumed your held order'), findsOneWidget);

    // Clean up so this held cart doesn't leak into the next test — the held
    // cart is process-static, surviving beyond this test's own widget tree.
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
  });

  testWidgets('kitchen note is held and resumed along with the cart',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderTakingScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Espresso'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).last, 'no milk');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('no milk'), findsOneWidget);
  });
}
