import '../../data/db/leko_database.dart';
import 'leaf_models.dart';

const List<String> lekoExpenseCategoryLabels = <String>[
  'Food',
  'Groceries',
  'Transportation',
  'Entertainment',
  'Bills',
  'Shopping',
  'Health',
  'Other',
];

List<LeafClarificationOption> standardExpenseCategoryOptions(
  List<Category> categories,
) {
  return [
    for (final label in lekoExpenseCategoryLabels)
      _categoryOption(label, categories),
  ];
}

List<LeafClarificationOption> dateClarificationOptions(
  DateTime now, {
  String field = 'date',
}) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  return [
    LeafClarificationOption(
      id: 'today',
      label: 'Today',
      patch: {field: _isoDay(today)},
    ),
    LeafClarificationOption(
      id: 'yesterday',
      label: 'Yesterday',
      patch: {field: _isoDay(yesterday)},
    ),
    LeafClarificationOption(
      id: 'custom_date',
      label: 'Custom Date',
      patch: {field: '__custom__'},
    ),
  ];
}

const List<LeafClarificationOption> accountClarificationOptions = [
  LeafClarificationOption(
    id: 'chequing',
    label: 'Chequing',
    patch: {'account': 'chequing'},
  ),
  LeafClarificationOption(
    id: 'savings',
    label: 'Savings',
    patch: {'account': 'savings'},
  ),
  LeafClarificationOption(
    id: 'credit_card',
    label: 'Credit Card',
    patch: {'account': 'credit_card'},
  ),
  LeafClarificationOption(
    id: 'other',
    label: 'Other',
    patch: {'account': 'other'},
  ),
];

const List<LeafClarificationOption> recurrenceClarificationOptions = [
  LeafClarificationOption(
    id: 'one_time',
    label: 'One-time',
    patch: {'recurrence': 'one_time'},
  ),
  LeafClarificationOption(
    id: 'weekly',
    label: 'Weekly',
    patch: {'recurrence': 'weekly'},
  ),
  LeafClarificationOption(
    id: 'biweekly',
    label: 'Biweekly',
    patch: {'recurrence': 'biweekly'},
  ),
  LeafClarificationOption(
    id: 'monthly',
    label: 'Monthly',
    patch: {'recurrence': 'monthly'},
  ),
];

LeafClarificationOption _categoryOption(
  String label,
  List<Category> categories,
) {
  final category = _findCategoryForLabel(label, categories);
  return LeafClarificationOption(
    id: category?.id ?? label.toLowerCase().replaceAll(' ', '_'),
    label: label,
    patch: {
      if (category != null) 'category_id': category.id,
      'category_name': category?.name ?? label,
    },
  );
}

Category? _findCategoryForLabel(String label, List<Category> categories) {
  final aliases = switch (label) {
    'Food' => const ['food', 'dining', 'restaurant', 'meal'],
    'Groceries' => const ['grocer'],
    'Transportation' => const ['transport', 'transit'],
    'Entertainment' => const ['entertain'],
    'Bills' => const ['bill', 'rent', 'mortgage', 'utilities', 'subscription'],
    'Shopping' => const ['shop'],
    'Health' => const ['health', 'medical'],
    'Other' => const ['other'],
    _ => <String>[label.toLowerCase()],
  };
  for (final alias in aliases) {
    for (final category in categories) {
      if (category.name.toLowerCase().contains(alias)) return category;
    }
  }
  return null;
}

String _isoDay(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.toIso8601String().split('T').first;
}
