import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinras/main.dart';

void main() {
  testWidgets('SINRAS AI App smoke test - Logged Out state', (WidgetTester tester) async {
    // Build our app and trigger a frame (initialLoggedIn = false).
    await tester.pumpWidget(const SinrasAiApp(initialLoggedIn: false));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that Login Screen is presented.
    expect(find.text('SINRAS AI'), findsOneWidget);
    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
  });

  testWidgets('SINRAS AI App smoke test - Logged In state', (WidgetTester tester) async {
    // Build our app in Logged In state (initialLoggedIn = true).
    await tester.pumpWidget(const SinrasAiApp(initialLoggedIn: true));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that HomeScreen with SINRAS PRO OS is loaded.
    expect(find.text('SINRAS PRO OS'), findsOneWidget);
  });
}
