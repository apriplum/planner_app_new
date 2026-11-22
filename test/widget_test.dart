import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/app.dart';

void main() {
  testWidgets('Приложение запускается', (WidgetTester tester) async {
    await tester.pumpWidget(const PlannerApp());

    expect(find.text('Планировщик'), findsOneWidget);
  });
}