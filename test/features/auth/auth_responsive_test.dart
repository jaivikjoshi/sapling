import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leko/features/auth/signup_screen.dart';
import 'package:leko/features/auth/welcome_screen.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Widget child, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: child)));
    await tester.pump(const Duration(milliseconds: 1400));
  }

  testWidgets('welcome screen fits on compact phones', (tester) async {
    await pumpAtSize(tester, const WelcomeScreen(), const Size(320, 568));

    expect(tester.takeException(), isNull);
  });

  testWidgets('signup screen fits on compact phones', (tester) async {
    await pumpAtSize(tester, const SignupScreen(), const Size(320, 568));

    expect(tester.takeException(), isNull);
  });
}
