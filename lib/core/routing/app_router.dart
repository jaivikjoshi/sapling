import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/bills/bills_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/transactions/add_expense_screen.dart';
import '../../features/transactions/add_income_screen.dart';
import '../../features/transactions/edit_expense_screen.dart';
import '../../features/transactions/transaction_list_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/recurring_income/recurring_income_screen.dart';
import '../../features/splits/splits_screen.dart';
import '../../features/splits/person_detail_screen.dart';
import '../../features/splits/split_detail_screen.dart';
import '../../features/closeout/closeout_screen.dart';
import '../../features/recovery/recovery_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bills',
                builder: (context, state) => const BillsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/edit-expense/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditExpenseScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/add-income',
        builder: (context, state) => const AddIncomeScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/recurring-income',
        builder: (context, state) => const RecurringIncomeScreen(),
      ),
      GoRoute(
        path: '/splits',
        builder: (context, state) => const SplitsScreen(),
        routes: [
          GoRoute(
            path: 'person/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PersonDetailScreen(personId: id);
            },
          ),
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SplitDetailScreen(splitEntryId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/closeout',
        builder: (context, state) => const CloseoutScreen(),
      ),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
    ],
  );
});

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        // Tight anchor near home indicator
        bottom:
            bottomPadding > 0
                ? (bottomPadding - 14).clamp(6.0, double.infinity)
                : 10.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            // Primary lift shadow
            BoxShadow(
              color: const Color(0xFF16272E).withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            // Soft ambient shadow
            BoxShadow(
              color: const Color(0xFF16272E).withValues(alpha: 0.06),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // Frosted teal glass — smoky blue-teal, ~78% opacity
                color: const Color(0xFF49616B).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(30),
                // Subtle cool border
                border: Border.all(
                  color: const Color(0xFFD2E1E6).withValues(alpha: 0.14),
                  width: 0.5,
                ),
                // Inner top highlight gradient
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF5B717A).withValues(alpha: 0.85),
                    const Color(0xFF415760).withValues(alpha: 0.78),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.receipt_long_rounded,
                    inactiveIcon: Icons.receipt_long_outlined,
                    label: 'Bills',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.flag_rounded,
                    inactiveIcon: Icons.flag_outlined,
                    label: 'Goals',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.bar_chart_rounded,
                    inactiveIcon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.settings_rounded,
                    inactiveIcon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  // Exact color specs from design brief
  static const _activeIconColor = Color(0xFFE6B29D); // warm dusty peach
  static const _activeLabelColor = Color(
    0xFFD79883,
  ); // slightly deeper for text
  static const _activePillColor = Color(0xFFA88D84); // dusty blush pill tint
  static const _inactiveIconColor = Color(0xFFB9C3C8); // muted cool gray
  static const _inactiveLabelColor = Color(0xFFAAB4BA); // slightly dimmer

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 12,
                vertical: isSelected ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? _activePillColor.withValues(alpha: 0.22)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                // Subtle inner highlight on active pill
                border:
                    isSelected
                        ? Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        )
                        : null,
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? _activeIconColor : _inactiveIconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _activeLabelColor : _inactiveLabelColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}
