import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/closeout_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../domain/services/closeout_service.dart';

class CloseoutScreen extends ConsumerWidget {
  const CloseoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nightly Closeout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          streakAsync.when(
            data: (streak) => _StreakCard(streak: streak),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: TextStyle(color: LekoColors.error),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your streak is based on days you stayed within your daily budget (from what you logged).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LekoColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final StreakResult streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: LekoColors.labelOrange),
                const SizedBox(width: 8),
                Text(
                  '${streak.currentStreak} day streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              streak.todayWithinBudget
                  ? "Today: within budget"
                  : "Today: over budget",
              style: TextStyle(
                color: streak.todayWithinBudget
                    ? LekoColors.labelGreen
                    : LekoColors.labelRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
