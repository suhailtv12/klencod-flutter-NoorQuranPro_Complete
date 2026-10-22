import 'package:flutter_test/flutter_test.dart';
import 'package:noor_quran_pro/main.dart';

void main() {
  testWidgets('يبدأ التطبيق بواجهة نور القرآن', (WidgetTester tester) async {
    await tester.pumpWidget(const NoorQuranApp());
    await tester.pump();
    expect(find.text('نور القرآن'), findsOneWidget);
  });
}
