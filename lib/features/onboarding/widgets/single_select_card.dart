import 'package:flutter/material.dart';
import '../../../core/theme/leko_colors.dart';

class SingleSelectCard extends StatelessWidget {
  const SingleSelectCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? LekoColors.onboardingFill.withOpacity(0.15) : LekoColors.onboardingSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? LekoColors.onboardingFill : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? LekoColors.onboardingTextPrimary : LekoColors.onboardingTextPrimary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: LekoColors.onboardingTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? LekoColors.onboardingFill : LekoColors.onboardingTextSecondary.withOpacity(0.5),
                  width: 2,
                ),
                color: isSelected ? LekoColors.onboardingFill : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: LekoColors.onboardingBackground)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
