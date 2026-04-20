import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_manager/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FleetManagerApp());
    expect(find.byType(FleetManagerApp), findsOneWidget);
  });
}
