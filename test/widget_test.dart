import 'package:flutter_test/flutter_test.dart';
import 'package:resto/main.dart';

void main() {
  testWidgets('App can start', (WidgetTester tester) async {
    await tester.pumpWidget(const RestoApp());
    expect(find.byType(RestoApp), findsOneWidget);
  });
}
