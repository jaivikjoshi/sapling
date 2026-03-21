import 'package:flutter/material.dart';
import '../../../core/theme/leko_colors.dart';

class SingleSelectCard extends StatelessWidget {
  const SingleSelectCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool compact = description == null && icon == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: compact ? 16 : 20,
        ),
        decoration: BoxDecoration(
          color: isSelected ? LekoColors.onboardingFill.withOpacity(0.15) : LekoColors.onboardingSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? LekoColors.onboardingFill : LekoColors.onboardingSurface,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? LekoColors.onboardingFill : LekoColors.onboardingTextSecondary,
                size: 28,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? LekoColors.onboardingTextPrimary : LekoColors.onboardingTextPrimary.withOpacity(0.9),
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: LekoColors.onboardingTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? LekoColors.onboardingFill : LekoColors.onboardingTextSecondary.withOpacity(0.4),
                  width: 2,
                ),
                color: isSelected ? LekoColors.onboardingFill : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: LekoColors.onboardingBackground)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
