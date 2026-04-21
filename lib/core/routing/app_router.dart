import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/bills/bills_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/leaf/leaf_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
// import '../../features/auth/confirm_email_screen.dart'; // Disabled: no email verification
import '../../features/auth/welcome_screen.dart';
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
import '../providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final hasSession = user != null;
      final isWelcomeFlow = loc == '/welcome' || loc.startsWith('/welcome/');
      // final isConfirmEmail = loc.startsWith('/welcome/confirm-email'); // Disabled: no email verification
      // if (hasSession && isConfirmEmail) return '/onboarding'; // Disabled
      if (hasSession && isWelcomeFlow) return '/';
      if (!hasSession && !isWelcomeFlow && loc != '/') return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignupScreen(),
          ),
          // Disabled: no email verification
          // GoRoute(
          //   path: 'confirm-email',
          //   builder: (context, state) {
          //     final email = state.uri.queryParameters['email'];
          //     return ConfirmEmailScreen(email: email);
          //   },
          // ),
        ],
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
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaf',
                builder: (context, state) => const LeafScreen(),
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
      // Appending bills implicitly, but removing it from nav stack.
      // Navigating directly could still be possible though.
      GoRoute(path: '/bills', builder: (context, state) => const BillsScreen()),
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
    final isLightStyle =
        currentIndex == 0 || currentIndex == 1 || currentIndex == 3 || currentIndex == 4;
    final shadowColor = isLightStyle
        ? const Color(0x160E1830)
        : Colors.black.withValues(alpha: 0.28);
    final glowColor = isLightStyle
        ? Colors.transparent
        : const Color(0xFF1D6A66).withValues(alpha: 0.10);
    final backgroundColor = isLightStyle
        ? const Color(0xFFFCFCFD)
        : const Color(0xFF0C1719).withValues(alpha: 0.88);
    final borderColor = isLightStyle
        ? const Color(0xFFE9EDF4)
        : const Color(0xFF24514E).withValues(alpha: 0.65);

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
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isLightStyle ? 18 : 28,
              offset: Offset(0, isLightStyle ? 10 : 14),
            ),
            BoxShadow(
              color: glowColor,
              blurRadius: 30,
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: borderColor,
                  width: 0.8,
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
                    isLightStyle: isLightStyle,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.flag_rounded,
                    inactiveIcon: Icons.flag_outlined,
                    label: 'Goals',
                    isSelected: currentIndex == 1,
                    isLightStyle: isLightStyle,
                    onTap: () => onTap(1),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.energy_savings_leaf_rounded,
                    inactiveIcon: Icons.energy_savings_leaf_outlined,
                    label: 'Leaf',
                    isSelected: currentIndex == 2,
                    isLightStyle: isLightStyle,
                    isIconOnly: true, // Specific treatment for the center tab
                    onTap: () => onTap(2),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.bar_chart_rounded,
                    inactiveIcon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    isSelected: currentIndex == 3,
                    isLightStyle: isLightStyle,
                    onTap: () => onTap(3),
                  ),
                  _NavBarItem(
                    activeIcon: Icons.settings_rounded,
                    inactiveIcon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: currentIndex == 4,
                    isLightStyle: isLightStyle,
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
    required this.isLightStyle,
    required this.onTap,
    this.isIconOnly = false,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final bool isLightStyle;
  final VoidCallback onTap;
  final bool isIconOnly;

  @override
  Widget build(BuildContext context) {
    final activePillColor =
        isLightStyle ? const Color(0xFFF1F4F8) : const Color(0xFF17353A);
    final activeColor =
        isLightStyle ? const Color(0xFF11182C) : const Color(0xFFF5F1E8);
    final inactiveColor =
        isLightStyle ? const Color(0xFF8B96A8) : const Color(0xFF79918F);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        width: isIconOnly ? 52 : 56,
        decoration: BoxDecoration(
          color: isSelected ? activePillColor : Colors.transparent,
          borderRadius: isIconOnly ? null : BorderRadius.circular(20),
          shape: isIconOnly ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: Center(
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected ? activeColor : inactiveColor,
            size: isIconOnly ? 26 : 22,
          ),
        ),
      ),
    );
  }
}
