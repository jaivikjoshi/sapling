import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leko/app.dart';
import 'package:leko/core/providers/auth_providers.dart';

void main() {
  testWidgets('App launches without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: const LekoApp(),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
