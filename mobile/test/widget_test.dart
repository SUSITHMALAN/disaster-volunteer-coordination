import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_temp/main.dart';

void main() {
  testWidgets('DvcApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DvcApp());
    expect(find.byType(DvcApp), findsOneWidget);
  });
}
