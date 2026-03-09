import 'package:flutter/material.dart';
import '../../core/theme/sapling_colors.dart';

class LeafScreen extends StatelessWidget {
  const LeafScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      appBar: AppBar(
        title: const Text('Leaf'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.energy_savings_leaf_rounded, size: 64, color: SaplingColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Leaf Area',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2E33)),
            ),
            const SizedBox(height: 8),
            const Text(
              'A new placeholder screen.',
              style: TextStyle(color: Color(0xFF7F8E96)),
            ),
          ],
        ),
      ),
    );
  }
}
