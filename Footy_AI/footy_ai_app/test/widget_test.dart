import 'package:flutter_test/flutter_test.dart';

import 'package:footy_ai_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FootyAIApp());
    await tester.pump();
  });
}