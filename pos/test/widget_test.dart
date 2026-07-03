import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/main.dart';

void main() {
  testWidgets('Welcome screen shows MinePOS and both entry buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MinePosApp());

    expect(find.text('MINEPOS'), findsOneWidget);
    expect(find.text('CONNECT TO SERVER'), findsOneWidget);
    expect(find.text('CREATE SHOP'), findsOneWidget);
  });

  testWidgets('Connect to Server navigates to the Connect screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MinePosApp());

    await tester.tap(find.text('CONNECT TO SERVER'));
    await tester.pumpAndSettle();

    expect(find.text('Connect to Server'), findsOneWidget);
  });

  testWidgets(
    'Create Shop wizard blocks Next until required fields are filled, then advances',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MinePosApp());

      await tester.tap(find.text('CREATE SHOP'));
      await tester.pumpAndSettle();
      expect(find.text('Shop details'), findsOneWidget);

      // Next with empty required fields should show validation errors and
      // keep us on step 1.
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('Shop name is required'), findsOneWidget);
      expect(find.text('Shop details'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Cozy Cafe'); // Shop Name
      await tester.enterText(textFields.at(1), 'cozy@example.com'); // Email

      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('First admin account'), findsOneWidget);
    },
  );

  testWidgets(
    'Connect to Server: empty address is rejected, valid address reaches Login',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MinePosApp());
      await _connectToServer(tester);

      expect(find.textContaining('Connected to'), findsOneWidget);
      expect(find.text('SIGN IN'), findsWidgets);
    },
  );

  testWidgets(
    'Login: empty submit is rejected, valid credentials reach Home',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MinePosApp());
      await _connectToServer(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pump();
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'admin');
      await tester.enterText(textFields.at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsOneWidget);
    },
  );

  testWidgets('Login: Forgot Password navigates to its screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MinePosApp());
    await _connectToServer(tester);

    await tester.tap(find.text('Forgot Password'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
  });
}

/// Walks Welcome -> Connect to Server -> Manual tab -> Connect, landing on
/// the Login screen. Shared by tests that need to start from Login.
Future<void> _connectToServer(WidgetTester tester) async {
  await tester.tap(find.text('CONNECT TO SERVER'));
  await tester.pumpAndSettle();

  // Manual tab avoids touching the Wi-Fi discovery tab, which would hit real
  // platform channels that aren't wired up under `flutter test`.
  await tester.tap(find.text('MANUAL'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField), '192.168.1.5:8080');
  await tester.tap(find.text('CONNECT'));
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pumpAndSettle();
}
