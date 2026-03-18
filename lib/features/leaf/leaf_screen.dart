import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/leko_colors.dart';
import 'widgets/plant_simulation_view.dart';

class LeafScreen extends ConsumerWidget {
  const LeafScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // We add 56px to sit almost flush against the custom floating Glass Navigation Bar (leaving ~8px of breathing room)
    final double safeBottomPadding = bottomPadding + 16.0;

    return Scaffold(
      backgroundColor: LekoColors.background, // Matches #F7F6F3 off-white
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── Hero Center Area ──
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'What can I do for you?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily:
                              'Georgia', // Editorial serif to match inspiration
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: LekoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Suggestion Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: LekoColors.textSecondary.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore financial insights',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: LekoColors.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: LekoColors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(
                        height: 380,
                        width: double.infinity,
                        child: PlantSimulationView(),
                      ),
                      const SizedBox(height: 60), // Space before floating box
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating Input Prompt ──
            Positioned(
              left: 20,
              right: 20,
              bottom:
                  safeBottomPadding, // Anchored safely above the custom Nav Bar
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 40,
                      offset: const Offset(0, -5), // Subliminal top shadow
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Assign a task or ask anything',
                        style: TextStyle(
                          fontSize: 15,
                          color: LekoColors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          // (+) Plus Button
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: LekoColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: LekoColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // "M + 2" style contextual pill
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: LekoColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: LekoColors.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  color: LekoColors.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Budget',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: LekoColors.textPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Microphone
                          Icon(
                            Icons.mic_none_rounded,
                            color: LekoColors.textPrimary.withValues(
                              alpha: 0.8,
                            ),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          // Up Arrow Action
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: LekoColors.background.withValues(
                                alpha: 0.8,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: LekoColors.textSecondary.withValues(
                                alpha: 0.4,
                              ),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
