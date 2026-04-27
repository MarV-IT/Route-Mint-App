import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteMintApp());
    expect(find.byType(RouteMintApp), findsOneWidget);
  });
}
