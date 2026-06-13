import 'package:flutter_test/flutter_test.dart';
import 'package:sum_sprint/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SumSprintApp());
    await tester.pump();

    // Verify that the app title is rendered
    expect(find.text('Sum Sprint'), findsOneWidget);
    expect(find.text('Warm Up'), findsOneWidget);
    expect(find.text('Competitions'), findsOneWidget);
  });
}
