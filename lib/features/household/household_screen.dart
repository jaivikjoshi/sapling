import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/integrations/product_foundations.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const roles = HouseholdRole.values;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF24343A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Household mode',
          style: TextStyle(
            color: Color(0xFF24343A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE9EEEB)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shared budgeting comes after the solo plan is stable.',
                    style: TextStyle(
                      color: Color(0xFF24343A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Leko is now ready for household roles, but invites, sync rules, and shared ledgers should be added behind explicit consent.',
                    style: TextStyle(
                      color: Color(0xFF7D8C94),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final role in roles) ...[
              _RoleCard(role: role),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role});

  final HouseholdRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEEB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6F2),
              shape: BoxShape.circle,
            ),
            child: Icon(_roleIcon(role), color: const Color(0xFF2E8F88)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleTitle(role),
                  style: const TextStyle(
                    color: Color(0xFF24343A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _roleDescription(role),
                  style: const TextStyle(
                    color: Color(0xFF7D8C94),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _roleIcon(HouseholdRole role) => switch (role) {
  HouseholdRole.owner => Icons.admin_panel_settings_outlined,
  HouseholdRole.partner => Icons.group_outlined,
  HouseholdRole.viewer => Icons.visibility_outlined,
};

String _roleTitle(HouseholdRole role) => switch (role) {
  HouseholdRole.owner => 'Owner',
  HouseholdRole.partner => 'Partner',
  HouseholdRole.viewer => 'Viewer',
};

String _roleDescription(HouseholdRole role) => switch (role) {
  HouseholdRole.owner => 'Manages invites, shared budgets, and rules.',
  HouseholdRole.partner => 'Adds transactions and edits shared plans.',
  HouseholdRole.viewer => 'Can review shared progress without editing.',
};
