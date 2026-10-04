import 'package:flutter_test/flutter_test.dart';
import 'package:ecoruta/main.dart';

void main() {
  testWidgets('EcoRuta inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoRutaApp());

    expect(find.text('EcoRuta'), findsOneWidget);
  });
}