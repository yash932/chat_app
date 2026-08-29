import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_chat/main.dart';

void main() {
  testWidgets('PulseChat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PulseChatApp());
    expect(find.byType(PulseChatApp), findsOneWidget);
  });
}
