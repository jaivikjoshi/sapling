import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/sapling_colors.dart';
import '../../../domain/models/plant_state.dart';

/// A beautiful, CustomPainter-based plant widget driven by [PlantState].
/// Renders an organic plant with smooth curves, natural canopy, gradients,
/// and health-driven visual effects.
class PlantWidget extends StatelessWidget {
  const PlantWidget({super.key, required this.state, this.height = 240});

  final PlantState state;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PlantPainter(state),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _StageLabel(state: state),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Custom Painter — the heart of the visual
// ══════════════════════════════════════════════════════════════════════════════

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.state);
  final PlantState state;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height - 28; // above the label

    // ── 1. Background glow ──
    if (state.hasGlow && state.healthStage >= 3) {
      _paintGlow(canvas, cx, bottom - 60, size);
    }

    // ── 2. Pot ──
    _paintPot(canvas, cx, bottom, size);

    // ── 3. Soil ──
    _paintSoil(canvas, cx, bottom, size);

    // ── 4. Trunk ──
    if (state.growthStage >= 1) {
      _paintTrunk(canvas, cx, bottom, size);
    } else {
      // Seed: just a small mound
      _paintSeed(canvas, cx, bottom, size);
    }

    // ── 5. Canopy (branches + leaves) ──
    if (state.growthStage >= 2) {
      _paintCanopy(canvas, cx, bottom, size);
    } else if (state.growthStage == 1) {
      // Sprout: small leaves at top
      _paintSproutLeaves(canvas, cx, bottom, size);
    }

    // ── 6. Flowers ──
    if (state.hasFlowerBud) {
      _paintFlowers(canvas, cx, bottom, size);
    }

    // ── 7. Fruit ──
    if (state.hasFruit && state.healthStage >= 3) {
      _paintFruit(canvas, cx, bottom, size);
    }

    // ── 8. Falling leaves (low health) ──
    if (state.healthStage <= 2 && state.growthStage >= 2) {
      _paintFallingLeaves(canvas, cx, bottom, size);
    }
  }

  // ── Glow ──
  void _paintGlow(Canvas canvas, double cx, double cy, Size size) {
    final opacity = (state.healthNormalized * 0.25).clamp(0.05, 0.25);
    final radius = 60.0 + state.growthStage * 12.0;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [
          const Color(0xFF3B9797).withValues(alpha: opacity),
          const Color(0xFF3B9797).withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  // ── Pot ──
  void _paintPot(Canvas canvas, double cx, double bottom, Size size) {
    final potWidth = 60.0;
    final potHeight = 44.0;
    final rimHeight = 8.0;

    // Pot body (tapered trapezoid)
    final potPath = Path()
      ..moveTo(cx - potWidth / 2, bottom - potHeight)
      ..lineTo(cx - potWidth / 2 + 6, bottom)
      ..quadraticBezierTo(cx, bottom + 3, cx + potWidth / 2 - 6, bottom)
      ..lineTo(cx + potWidth / 2, bottom - potHeight)
      ..close();

    final potGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - potWidth / 2, bottom - potHeight),
        Offset(cx + potWidth / 2, bottom),
        [const Color(0xFFD4A574), const Color(0xFFC08B5C)],
      );
    canvas.drawPath(potPath, potGradient);

    // Pot rim
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - potWidth / 2 - 3, bottom - potHeight - rimHeight / 2,
          potWidth + 6, rimHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      rimRect,
      Paint()..color = const Color(0xFFD4A574),
    );

    // Subtle inner shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - potWidth / 2 - 3, bottom - potHeight - rimHeight / 2,
            potWidth + 6, 3),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFBB8A55),
    );
  }

  // ── Soil ──
  void _paintSoil(Canvas canvas, double cx, double bottom, Size size) {
    final soilWidth = 50.0;
    final soilTop = bottom - 44.0;

    // Soil color depends on health
    final healthyColor = const Color(0xFF6B4226);
    final dryColor = const Color(0xFFB0967A);
    final soilColor = Color.lerp(dryColor, healthyColor, state.healthNormalized)!;

    final soilPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, soilTop + 2),
        width: soilWidth,
        height: 8,
      ));
    canvas.drawPath(soilPath, Paint()..color = soilColor);

    // Cracks when health is low
    if (state.healthStage <= 2) {
      final crackPaint = Paint()
        ..color = const Color(0xFFA08060).withValues(alpha: 0.6)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(cx - 12, soilTop + 2), Offset(cx - 6, soilTop + 5), crackPaint);
      canvas.drawLine(
          Offset(cx + 8, soilTop + 1), Offset(cx + 14, soilTop + 4), crackPaint);
    }
  }

  // ── Seed (stage 0) ──
  void _paintSeed(Canvas canvas, double cx, double bottom, Size size) {
    final seedY = bottom - 48.0;
    final paint = Paint()..color = const Color(0xFF8B6B4A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, seedY), width: 10, height: 7),
      paint,
    );
    // Tiny sprout hint
    final sproutPaint = Paint()
      ..color = const Color(0xFF7CB342).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, seedY - 2), Offset(cx + 2, seedY - 6), sproutPaint);
  }

  // ── Trunk ──
  void _paintTrunk(Canvas canvas, double cx, double bottom, Size size) {
    final stage = state.growthStage;
    final potTop = bottom - 44.0;

    // Trunk dimensions scale with growth
    final trunkHeight = 30.0 + stage * 18.0;
    final trunkBase = 3.0 + stage * 1.2;
    final trunkTop = 2.0 + stage * 0.6;

    final trunkPath = Path()
      ..moveTo(cx - trunkBase, potTop)
      ..quadraticBezierTo(
        cx - trunkTop * 1.2,
        potTop - trunkHeight * 0.6,
        cx - trunkTop * 0.5,
        potTop - trunkHeight,
      )
      ..lineTo(cx + trunkTop * 0.5, potTop - trunkHeight)
      ..quadraticBezierTo(
        cx + trunkTop * 1.2,
        potTop - trunkHeight * 0.6,
        cx + trunkBase,
        potTop,
      )
      ..close();

    // Gradient from dark base to lighter tip
    final trunkGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, potTop),
        Offset(cx, potTop - trunkHeight),
        [
          const Color(0xFF5D4037),
          Color.lerp(const Color(0xFF5D4037), const Color(0xFF7CB342),
              stage >= 3 ? 0.0 : 0.3)!,
        ],
      );
    canvas.drawPath(trunkPath, trunkGradient);

    // Trunk texture lines
    if (stage >= 3) {
      final texturePaint = Paint()
        ..color = const Color(0xFF4E342E).withValues(alpha: 0.3)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      for (int i = 1; i <= math.min(stage, 4); i++) {
        final y = potTop - trunkHeight * (i / (stage + 1));
        canvas.drawLine(
          Offset(cx - trunkBase * 0.5, y),
          Offset(cx + trunkBase * 0.3, y + 2),
          texturePaint,
        );
      }
    }
  }

  // ── Sprout leaves (stage 1) ──
  void _paintSproutLeaves(Canvas canvas, double cx, double bottom, Size size) {
    final potTop = bottom - 44.0;
    final trunkHeight = 48.0;
    final tipY = potTop - trunkHeight;

    final leafColor = _healthAdjustedGreen();

    // Two small leaves
    _drawLeaf(canvas, cx, tipY, -0.6, 14, 8, leafColor);
    _drawLeaf(canvas, cx, tipY + 4, 0.5, 12, 7, leafColor);
  }

  // ── Canopy ──
  void _paintCanopy(Canvas canvas, double cx, double bottom, Size size) {
    final stage = state.growthStage;
    final potTop = bottom - 44.0;
    final trunkHeight = 30.0 + stage * 18.0;
    final canopyCenter = potTop - trunkHeight + 5;

    // Canopy size scales with growth
    final canopyW = 40.0 + stage * 20.0;
    final canopyH = 30.0 + stage * 16.0;

    final leafColor = _healthAdjustedGreen();
    final shadowColor = _healthAdjustedGreen(darker: true);

    // Draw layered elliptical canopy clusters
    final clusters = _canopyClusters(cx, canopyCenter, canopyW, canopyH, stage);
    for (final cluster in clusters) {
      // Shadow layer
      canvas.drawOval(
        cluster.inflate(2),
        Paint()..color = shadowColor.withValues(alpha: 0.15),
      );
      // Main shape
      final clusterPaint = Paint()
        ..shader = ui.Gradient.radial(
          cluster.center - const Offset(3, 3),
          cluster.shortestSide,
          [
            leafColor.withValues(alpha: 0.95),
            shadowColor.withValues(alpha: 0.85),
          ],
        );
      canvas.drawOval(cluster, clusterPaint);
    }

    // Individual highlight leaves on top
    final leafCount = 4 + stage * 3;
    final rng = math.Random(42);
    for (int i = 0; i < leafCount; i++) {
      if (state.healthStage <= 1 && i % 2 == 0) continue; // leaf loss
      if (state.healthStage == 0 && i % 3 != 0) continue;

      final angle = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * canopyW * 0.42;
      final lx = cx + math.cos(angle) * dist;
      final ly = canopyCenter + math.sin(angle) * dist * (canopyH / canopyW);
      final leafSize = 6.0 + rng.nextDouble() * 5.0;
      final tint = Color.lerp(leafColor, const Color(0xFF81C784), rng.nextDouble() * 0.4)!;

      _drawLeaf(canvas, lx, ly, angle, leafSize, leafSize * 0.55, tint);
    }
  }

  List<Rect> _canopyClusters(
      double cx, double cy, double w, double h, int stage) {
    final clusters = <Rect>[];

    // Central mass
    clusters.add(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.7, height: h * 0.7));

    if (stage >= 3) {
      // Side clusters
      clusters.add(Rect.fromCenter(
          center: Offset(cx - w * 0.3, cy + 5), width: w * 0.5, height: h * 0.55));
      clusters.add(Rect.fromCenter(
          center: Offset(cx + w * 0.3, cy + 5), width: w * 0.5, height: h * 0.55));
    }
    if (stage >= 4) {
      // Top cluster
      clusters.add(Rect.fromCenter(
          center: Offset(cx, cy - h * 0.3), width: w * 0.45, height: h * 0.4));
    }
    if (stage >= 5) {
      // Extra side width
      clusters.add(Rect.fromCenter(
          center: Offset(cx - w * 0.4, cy - 3), width: w * 0.4, height: h * 0.45));
      clusters.add(Rect.fromCenter(
          center: Offset(cx + w * 0.4, cy - 3), width: w * 0.4, height: h * 0.45));
    }

    // Droop effect at low health: shift clusters down
    if (state.healthStage <= 2) {
      final droop = (3 - state.healthStage) * 4.0;
      return clusters
          .map((r) => r.translate(0, droop))
          .toList();
    }

    return clusters;
  }

  // ── Flowers ──
  void _paintFlowers(Canvas canvas, double cx, double bottom, Size size) {
    final stage = state.growthStage;
    final potTop = bottom - 44.0;
    final trunkHeight = 30.0 + stage * 18.0;
    final canopyCenter = potTop - trunkHeight + 5;

    final count = state.hasFlowers ? 5 : 2;
    final rng = math.Random(99);
    final canopyW = 40.0 + stage * 20.0;
    final canopyH = 30.0 + stage * 16.0;

    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * canopyW * 0.3;
      final fx = cx + math.cos(angle) * dist;
      final fy = canopyCenter + math.sin(angle) * dist * (canopyH / canopyW);

      // Flower petals
      final petalColor = state.healthStage >= 4
          ? const Color(0xFFE28B78) // coral
          : const Color(0xFFD4A08A).withValues(alpha: 0.6);

      for (int p = 0; p < 5; p++) {
        final pa = p * math.pi * 2 / 5;
        final px = fx + math.cos(pa) * 4;
        final py = fy + math.sin(pa) * 4;
        canvas.drawCircle(
            Offset(px, py), 2.5, Paint()..color = petalColor);
      }
      // Center
      canvas.drawCircle(
          Offset(fx, fy), 2, Paint()..color = const Color(0xFFFFF8E1));
    }
  }

  // ── Fruit ──
  void _paintFruit(Canvas canvas, double cx, double bottom, Size size) {
    final stage = state.growthStage;
    final potTop = bottom - 44.0;
    final trunkHeight = 30.0 + stage * 18.0;
    final canopyCenter = potTop - trunkHeight + 5;
    final canopyH = 30.0 + stage * 16.0;

    final rng = math.Random(77);
    for (int i = 0; i < 3; i++) {
      final angle = rng.nextDouble() * math.pi * 0.8 + math.pi * 0.1;
      final fx = cx + math.cos(angle) * 20 * (i.isEven ? 1 : -1);
      final fy = canopyCenter + canopyH * 0.25 + rng.nextDouble() * 10;

      // Fruit body
      canvas.drawCircle(
        Offset(fx, fy),
        4.5,
        Paint()..color = const Color(0xFFFF7043),
      );
      // Highlight
      canvas.drawCircle(
        Offset(fx - 1.5, fy - 1.5),
        1.5,
        Paint()..color = const Color(0xFFFFAB91).withValues(alpha: 0.6),
      );
    }
  }

  // ── Falling leaves (health effect) ──
  void _paintFallingLeaves(Canvas canvas, double cx, double bottom, Size size) {
    final rng = math.Random(123);
    final count = state.healthStage <= 1 ? 6 : 3;
    final leafColor = const Color(0xFFA5845A); // dried leaf color

    for (int i = 0; i < count; i++) {
      final x = cx + (rng.nextDouble() - 0.5) * 80;
      final y = bottom - 50 + rng.nextDouble() * 30;
      final angle = rng.nextDouble() * math.pi;
      _drawLeaf(canvas, x, y, angle, 5, 3, leafColor.withValues(alpha: 0.5));
    }
  }

  // ── Helpers ──

  Color _healthAdjustedGreen({bool darker = false}) {
    final baseGreen = darker ? const Color(0xFF388E3C) : const Color(0xFF66BB6A);
    final wilted = darker ? const Color(0xFF8D8D6D) : const Color(0xFFB0BEA5);
    return Color.lerp(wilted, baseGreen, state.healthNormalized)!;
  }

  void _drawLeaf(Canvas canvas, double x, double y, double angle,
      double length, double width, Color color) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.3, -width, length, 0)
      ..quadraticBezierTo(length * 0.3, width, 0, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    // Leaf vein
    canvas.drawLine(
      Offset.zero,
      Offset(length * 0.8, 0),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) =>
      old.state.growthPoints != state.growthPoints ||
      old.state.healthScore != state.healthScore ||
      old.state.longestStreak != state.longestStreak;
}

// ══════════════════════════════════════════════════════════════════════════════
//  Status Label
// ══════════════════════════════════════════════════════════════════════════════

class _StageLabel extends StatelessWidget {
  const _StageLabel({required this.state});
  final PlantState state;

  static const _growthNames = [
    'Seed',
    'Sprout',
    'Small Sapling',
    'Growing Sapling',
    'Young Tree',
    'Mature Tree',
    'Flourishing',
  ];

  static const _healthNames = [
    'Dead',
    'Dried Out',
    'Losing Leaves',
    'Wilted',
    'Slightly Wilted',
    'Healthy',
  ];

  @override
  Widget build(BuildContext context) {
    final gName = _growthNames[state.growthStage.clamp(0, _growthNames.length - 1)];
    final hName = _healthNames[state.healthStage.clamp(0, _healthNames.length - 1)];

    return Text(
      '$gName · $hName',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: SaplingColors.textSecondary.withValues(alpha: 0.7),
        letterSpacing: 0.3,
      ),
    );
  }
}
