import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leko/app.dart';

void main() {
  testWidgets('App launches without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LekoApp()),
    );
    expect(find.text('Leko'), findsOneWidget);
  });
}
