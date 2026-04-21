import 'package:flutter_test/flutter_test.dart';
import 'package:leko/domain/models/enums.dart';
import 'package:leko/features/leaf/leaf_assistant_responses.dart';
import 'package:leko/features/leaf/leaf_context.dart';

void main() {
  const ctx = LeafContext(
    greetingName: 'Jaivik',
    allowanceMode: AllowanceMode.paycheck,
  );

  test('greet-like messages do not fall back to overview', () {
    final response = responseForFreeText(ctx, 'yo');

    expect(response, contains('Hey Jaivik'));
    expect(response, isNot(contains('Paycheck mode')));
  });

  test('unknown messages ask user to clarify instead of returning overview', () {
    final response = responseForFreeText(ctx, 'banana spaceship');

    expect(response, contains('I didn’t quite catch that'));
    expect(response, contains('spending today'));
  });
}
