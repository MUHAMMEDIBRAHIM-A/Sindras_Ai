import 'package:flutter_test/flutter_test.dart';
import 'package:sinras/main.dart';

void main() {
  testWidgets('SINRAS AI App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SinrasAiApp());
    // Advance time past the splash timer (1600ms)
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app widget mounts cleanly.
    expect(find.byType(SinrasAiApp), findsOneWidget);
  });
}
