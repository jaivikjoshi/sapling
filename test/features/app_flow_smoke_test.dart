import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leko/core/providers/auth_providers.dart';
import 'package:leko/core/providers/db_provider.dart';
import 'package:leko/data/db/leko_database.dart';
import 'package:leko/features/bills/bills_screen.dart';
import 'package:leko/features/categories/categories_screen.dart';
import 'package:leko/features/closeout/closeout_screen.dart';
import 'package:leko/features/goals/goals_screen.dart';
import 'package:leko/features/home/home_screen.dart';
import 'package:leko/features/household/household_screen.dart';
import 'package:leko/features/imports/import_review_screen.dart';
import 'package:leko/features/leaf/leaf_screen.dart';
import 'package:leko/features/monetization/paywall_screen.dart';
import 'package:leko/features/recovery/recovery_screen.dart';
import 'package:leko/features/recurring_income/recurring_income_screen.dart';
import 'package:leko/features/reports/reports_screen.dart';
import 'package:leko/features/settings/settings_screen.dart';
import 'package:leko/features/splits/splits_screen.dart';
import 'package:leko/features/transactions/add_expense_screen.dart';
import 'package:leko/features/transactions/add_income_screen.dart';
import 'package:leko/features/transactions/transaction_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('production flow smoke tests', () {
    late LekoDatabase db;

    setUp(() {
      db = LekoDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'home quick actions navigate to expense income and goals flows',
      (tester) async {
        final router = _router(initialLocation: '/home');
        await _pumpRouter(tester, db: db, router: router);

        await tester.pumpAndSettle();
        expect(find.text('Today\'s money'), findsOneWidget);

        await tester.tap(find.text('Add Expense'));
        await tester.pumpAndSettle();
        expect(find.text('Add Expense'), findsOneWidget);

        router.go('/home');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Income'));
        await tester.pumpAndSettle();
        expect(find.text('Add Income'), findsOneWidget);

        router.go('/home');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Goal'));
        await tester.pumpAndSettle();
        expect(find.text('New Goal'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _disposeApp(tester);
      },
    );

    testWidgets(
      'primary tabs and utility screens render empty production state',
      (tester) async {
        final routes = <String, String>{
          '/goals': 'Goals',
          '/leaf': 'Leaf',
          '/reports': 'Reports',
          '/settings': 'Settings',
          '/bills': 'Bills',
          '/transactions': 'Transactions',
          '/categories': 'Categories',
          '/recurring-income': 'Recurring Income',
          '/imports': 'Transaction review',
          '/premium': 'Leko Premium',
          '/household': 'Household mode',
          '/splits': 'Friends & Split',
          '/closeout': 'Nightly Closeout',
          '/recovery': 'Recovery Plan',
        };

        for (final entry in routes.entries) {
          final router = _router(initialLocation: entry.key);
          await _pumpRouter(tester, db: db, router: router);
          await tester.pumpAndSettle();
          expect(
            find.text(entry.value),
            findsWidgets,
            reason: '${entry.key} should render ${entry.value}',
          );
          expect(tester.takeException(), isNull, reason: entry.key);
          await _disposeApp(tester);
        }
      },
    );

    testWidgets('add expense requires amount and category before saving', (
      tester,
    ) async {
      await _pumpStandalone(tester, db: db, child: const AddExpenseScreen());
      await tester.pumpAndSettle();

      final save = find.text('Save Expense');
      expect(save, findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(await db.select(db.transactions).get(), isEmpty);

      await tester.enterText(find.byType(TextField).first, '12.50');
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(tester.takeException(), isNull);
      await _disposeApp(tester);
    });

    testWidgets('add income can save a valid one-time income', (tester) async {
      final router = _router(initialLocation: '/add-income');
      await _pumpRouter(tester, db: db, router: router);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '1250');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Income'));
      await tester.pumpAndSettle();

      final txns = await db.select(db.transactions).get();
      expect(txns, hasLength(1));
      expect(txns.single.type, 'income');
      expect(txns.single.amount, 1250);
      expect(tester.takeException(), isNull);
      await _disposeApp(tester);
    });
  });
}

GoRouter _router({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
      GoRoute(path: '/leaf', builder: (_, __) => const LeafScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/bills', builder: (_, __) => const BillsScreen()),
      GoRoute(
        path: '/add-expense',
        builder: (_, __) => const AddExpenseScreen(),
      ),
      GoRoute(path: '/add-income', builder: (_, __) => const AddIncomeScreen()),
      GoRoute(
        path: '/transactions',
        builder: (_, __) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/recurring-income',
        builder: (_, __) => const RecurringIncomeScreen(),
      ),
      GoRoute(path: '/imports', builder: (_, __) => const ImportReviewScreen()),
      GoRoute(path: '/premium', builder: (_, __) => const PaywallScreen()),
      GoRoute(path: '/household', builder: (_, __) => const HouseholdScreen()),
      GoRoute(path: '/splits', builder: (_, __) => const SplitsScreen()),
      GoRoute(path: '/closeout', builder: (_, __) => const CloseoutScreen()),
      GoRoute(path: '/recovery', builder: (_, __) => const RecoveryScreen()),
    ],
  );
}

Future<void> _pumpRouter(
  WidgetTester tester, {
  required LekoDatabase db,
  required GoRouter router,
}) async {
  await tester.binding.setSurfaceSize(const Size(393, 852));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

Future<void> _pumpStandalone(
  WidgetTester tester, {
  required LekoDatabase db,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(const Size(393, 852));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(home: child),
    ),
  );
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}
