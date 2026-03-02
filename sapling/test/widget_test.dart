import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sapling/app.dart';

void main() {
  testWidgets('App launches without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SaplingApp()),
    );
    expect(find.text('Sapling'), findsOneWidget);
  });
}
