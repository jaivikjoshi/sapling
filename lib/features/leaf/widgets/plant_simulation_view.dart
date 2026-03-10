import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PlantSimulationView extends StatefulWidget {
  const PlantSimulationView({super.key});

  @override
  State<PlantSimulationView> createState() => _PlantSimulationViewState();
}

class _PlantSimulationViewState extends State<PlantSimulationView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late PlantSimulation _sim;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _sim = PlantSimulation();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) {
      return;
    }

    final dt = (elapsed - previous).inMicroseconds / 1e6;
    _sim.update(dt.clamp(0.0, 1 / 30));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: PlantPainter(simulation: _sim),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class PlantSimulation {
  PlantSimulation()
    : leaves = [
        LeafState(
          index: 0,
          side: -1,
          anchorT: 0.18,
          lengthScale: 1.18,
          widthScale: 1.24,
          angleBiasDeg: 30,
          stemOffset: 2,
        ),
        LeafState(
          index: 1,
          side: 1,
          anchorT: 0.30,
          lengthScale: 0.92,
          widthScale: 0.94,
          angleBiasDeg: 60,
          stemOffset: 1,
        ),
        LeafState(
          index: 2,
          side: -1,
          anchorT: 0.42,
          lengthScale: 1.08,
          widthScale: 1.10,
          angleBiasDeg: 45,
          stemOffset: 2,
        ),
        LeafState(
          index: 3,
          side: 1,
          anchorT: 0.56,
          lengthScale: 0.88,
          widthScale: 0.90,
          angleBiasDeg: 45,
          stemOffset: 1,
        ),
        LeafState(
          index: 4,
          side: -1,
          anchorT: 0.69,
          lengthScale: 0.96,
          widthScale: 1.00,
          angleBiasDeg: 60,
          stemOffset: 1,
        ),
        LeafState(
          index: 5,
          side: 1,
          anchorT: 0.82,
          lengthScale: 0.80,
          widthScale: 0.84,
          angleBiasDeg: 30,
          stemOffset: 1,
        ),
      ];

  static const double maxStemLength = 315;
  static const double growDuration = 10.5;
  static const double stemCurve = 56;
  static const double windBase = 0.35;
  static const double windFreq = 0.85;
  static const double stemStiffness = 28;
  static const double stemDamping = 8.5;

  final List<LeafState> leaves;

  final math.Random _random = math.Random();

  double time = 0;
  double growth = 0;
  double gust = 0;
  double stemAngle = 0;
  double stemVelocity = 0;
  double lastWind = 0;

  double get currentStemLength => maxStemLength * growth;

  int get openLeaves =>
      leaves.where((leaf) => leaf.visible && leaf.open > 0.8).length;

  String get windLabel {
    final w = lastWind.abs();
    if (w < 0.18) return 'Calm';
    if (w < 0.42) return 'Breezy';
    return 'Windy';
  }

  void addRandomGust() {
    final sign = _random.nextBool() ? 1.0 : -1.0;
    gust += sign * (_random.nextDouble() * 0.9 + 0.5);
  }

  void update(double dt) {
    time += dt;
    growth = (time / growDuration).clamp(0.0, 1.0);

    final wind = math.sin(time * windFreq) * windBase + gust;
    lastWind = wind;

    final targetStemAngle = wind * 0.18 + math.sin(time * 0.4) * 0.02;
    final stemAccel =
        (targetStemAngle - stemAngle) * stemStiffness -
        stemVelocity * stemDamping;
    stemVelocity += stemAccel * dt;
    stemAngle += stemVelocity * dt;

    for (final leaf in leaves) {
      final targetOpen =
          growth > leaf.anchorT
              ? smoothstep(leaf.anchorT, leaf.anchorT + 0.14, growth)
              : 0.0;
      final openAccel = (targetOpen - leaf.open) * 34 - leaf.openVelocity * 8;
      leaf.openVelocity += openAccel * dt;
      leaf.open += leaf.openVelocity * dt;
      leaf.open = leaf.open.clamp(0.0, 1.15);

      final swayTarget =
          wind * 0.9 + math.sin(time * 1.8 + leaf.index * 0.65) * 0.08;
      final swayAccel = (swayTarget - leaf.sway) * 20 - leaf.swayVelocity * 7;
      leaf.swayVelocity += swayAccel * dt;
      leaf.sway += leaf.swayVelocity * dt;

      final appear = smoothstep(
        leaf.anchorT - 0.08,
        leaf.anchorT + 0.02,
        growth,
      );
      leaf.visible = appear > 0.01;
      leaf.appear = appear;
    }

    gust *= math.pow(0.2, dt * 1.45).toDouble();
  }

  Offset pointOnStem(double t) {
    final length = maxStemLength * growth;
    final swayInfluence = stemAngle * 28;
    final x = math.sin(t * 1.35) * (stemCurve * t * t) + swayInfluence * t;
    final y = -length * t;
    return Offset(x, y);
  }

  Offset tangentOnStem(double t) {
    const eps = 0.001;
    final p1 = pointOnStem((t - eps).clamp(0.0, 1.0));
    final p2 = pointOnStem((t + eps).clamp(0.0, 1.0));
    final delta = p2 - p1;
    final len = delta.distance;
    if (len <= 0.0001) return const Offset(0, -1);
    return Offset(delta.dx / len, delta.dy / len);
  }
}

class LeafState {
  LeafState({
    required this.index,
    required this.side,
    required this.anchorT,
    required this.lengthScale,
    required this.widthScale,
    required this.angleBiasDeg,
    required this.stemOffset,
  });

  final int index;
  final int side;
  final double anchorT;
  final double lengthScale;
  final double widthScale;
  final double angleBiasDeg;
  final double stemOffset;

  double open = 0;
  double openVelocity = 0;
  double sway = 0;
  double swayVelocity = 0;
  double appear = 0;
  bool visible = false;
}

class PlantPainter extends CustomPainter {
  PlantPainter({required this.simulation});

  final PlantSimulation simulation;

  static const Color stemTop = Color(0xFF52B788);
  static const Color stemBottom = Color(0xFF1F6B39);
  static const Color leafLight = Color(0xFF95D5B2);
  static const Color leafDark = Color(0xFF2D6A4F);
  static const Color budOuter = Color(0xFF95D5B2);
  static const Color budInner = Color(0xFFD8F3DC);

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackgroundGlow(canvas, size);

    final base = Offset(size.width * 0.5, size.height * 0.80);
    canvas.save();
    canvas.translate(base.dx, base.dy);

    _paintGround(canvas, size);
    _paintStemGlow(canvas);
    _paintStem(canvas);

    for (final leaf in simulation.leaves) {
      if (!leaf.visible) continue;
      _paintLeaf(canvas, leaf);
    }

    _paintBud(canvas);

    canvas.restore();
  }

  void _paintBackgroundGlow(Canvas canvas, Size size) {
    final glowPaint =
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.5, size.height * 0.22),
            math.min(size.width, size.height) * 0.22,
            [const Color(0x6674C69D), const Color(0x0074C69D)],
          );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.22),
      math.min(size.width, size.height) * 0.22,
      glowPaint,
    );
  }

  void _paintGround(Canvas canvas, Size size) {
    final floorShadow = Paint()..color = Colors.black.withValues(alpha: 0.12);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 136), width: 270, height: 34),
      floorShadow,
    );

    final bodyPath =
        Path()
          ..moveTo(-112, 18)
          ..quadraticBezierTo(-104, 92, -74, 148)
          ..quadraticBezierTo(-50, 188, -20, 192)
          ..lineTo(20, 192)
          ..quadraticBezierTo(50, 188, 74, 148)
          ..quadraticBezierTo(104, 92, 112, 18)
          ..close();

    final bodyBounds = bodyPath.getBounds();
    final bodyPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            bodyBounds.topLeft,
            bodyBounds.bottomRight,
            const [Color(0xFFC56E4E), Color(0xFFA45237), Color(0xFF7C3D2A)],
            const [0.0, 0.5, 1.0],
          );

    canvas.drawPath(bodyPath, bodyPaint);

    final innerCutout = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 120), width: 98, height: 96),
      const Radius.circular(22),
    );
    canvas.drawRRect(
      innerCutout,
      Paint()..color = const Color(0xFFD3A975).withValues(alpha: 0.95),
    );

    final leftAccent =
        Path()
          ..moveTo(-88, 34)
          ..quadraticBezierTo(-82, 88, -58, 134)
          ..quadraticBezierTo(-42, 160, -26, 176)
          ..lineTo(-10, 176)
          ..quadraticBezierTo(-28, 145, -42, 98)
          ..quadraticBezierTo(-54, 60, -62, 28)
          ..close();
    canvas.drawPath(
      leftAccent,
      Paint()..color = const Color(0xFFD98A64).withValues(alpha: 0.65),
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 296, height: 74),
      Paint()..color = const Color(0xFFD9865C),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 12), width: 196, height: 42),
      Paint()..color = const Color(0xFF2C1B16),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 10), width: 174, height: 26),
      Paint()..color = const Color(0xFF1B100D),
    );

    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 8), width: 296, height: 74),
      math.pi * 0.06,
      math.pi * 0.88,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _paintStemGlow(Canvas canvas) {
    final tip = simulation.pointOnStem(1);
    final radius = 10 + simulation.growth * 14;
    final glow =
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
          ..color = const Color(0x6674C69D);
    canvas.drawOval(
      Rect.fromCenter(center: tip, width: radius * 2, height: radius * 3),
      glow,
    );
  }

  void _paintStem(Canvas canvas) {
    final stemPath = _buildStemRibbonPath();
    final bounds = stemPath.getBounds();

    final stemShadow = stemPath.shift(const Offset(3, 2));
    canvas.drawPath(
      stemShadow,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    canvas.drawPath(
      stemPath,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          const [Color(0xFF3DA96E), Color(0xFF2B8B59), Color(0xFF1D6B42)],
          const [0.0, 0.5, 1.0],
        ),
    );

    final highlight = _buildStemHighlightPath();
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  Path _buildStemRibbonPath() {
    final left = <Offset>[];
    final right = <Offset>[];

    for (int i = 0; i <= 18; i++) {
      final t = i / 18;
      final center = simulation.pointOnStem(t);
      final tangent = simulation.tangentOnStem(t);
      final normal = Offset(-tangent.dy, tangent.dx);
      final halfWidth = ui.lerpDouble(18, 6, t)!;
      left.add(center + normal * halfWidth);
      right.add(center - normal * halfWidth);
    }

    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (int i = 1; i < left.length; i++) {
      path.lineTo(left[i].dx, left[i].dy);
    }
    for (int i = right.length - 1; i >= 0; i--) {
      path.lineTo(right[i].dx, right[i].dy);
    }
    path.close();
    return path;
  }

  Path _buildStemHighlightPath() {
    final path = Path();
    for (int i = 0; i <= 16; i++) {
      final t = i / 16;
      final center = simulation.pointOnStem(t);
      final tangent = simulation.tangentOnStem(t);
      final normal = Offset(-tangent.dy, tangent.dx);
      final offset = ui.lerpDouble(6, 2.5, t)!;
      final point = center + normal * offset;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  void _paintLeaf(Canvas canvas, LeafState leaf) {
    final stemPoint = simulation.pointOnStem(leaf.anchorT);
    final tangent = simulation.tangentOnStem(leaf.anchorT);
    final normal =
        leaf.side == 1
            ? Offset(-tangent.dy, tangent.dx)
            : Offset(tangent.dy, -tangent.dx);
    final anchor = stemPoint + normal * leaf.stemOffset;
    final tangentAngle = math.atan2(tangent.dy, tangent.dx);
    final sideAngle =
        tangentAngle + (leaf.side == 1 ? math.pi / 2 : -math.pi / 2);

    final baseLength = (92 - leaf.index * 6.0) * leaf.lengthScale;
    final baseWidth = (48 - leaf.index * 2.4) * leaf.widthScale;
    final unfurl = easeOutBack(leaf.open.clamp(0.0, 1.0));
    final length = ui.lerpDouble(0.12, 1.0, unfurl)! * baseLength;
    final width = ui.lerpDouble(0.08, 1.0, unfurl)! * baseWidth;
    final curl = ui.lerpDouble(24, 2.5, leaf.open.clamp(0.0, 1.0))!;
    final droop =
        ui.lerpDouble(-22, 0, leaf.open.clamp(0.0, 1.0))! + leaf.sway * 18;
    final localRot =
        droop +
        leaf.side * ui.lerpDouble(50, 0, leaf.open.clamp(0.0, 1.0))! +
        leaf.angleBiasDeg;

    final leafPath = _buildLeafPath(length, width, curl);
    final highlightPath = _buildLeafHighlightPath(length, width, curl);

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(sideAngle + localRot * math.pi / 180);
    canvas.scale(leaf.appear, leaf.appear);

    final bodyBounds = leafPath.getBounds();
    final bodyPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            bodyBounds.topLeft,
            bodyBounds.bottomRight,
            [leafLight, leafDark],
          );

    final edgePaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;

    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final veinPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(leafPath, bodyPaint);
    canvas.drawPath(leafPath, edgePaint);
    canvas.drawPath(highlightPath, shinePaint);

    final vein =
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(
            width * 0.28,
            -length * 0.45,
            curl * 0.65,
            -length * 0.92,
          );
    canvas.drawPath(vein, veinPaint);

    canvas.restore();
  }

  void _paintBud(Canvas canvas) {
    final tip = simulation.pointOnStem(1.0);
    final scale = 0.92 + simulation.growth * 0.18;
    final rotate = simulation.stemAngle * 24 * math.pi / 180;

    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(rotate);
    canvas.scale(scale, scale);

    final budPaint = Paint()..color = budOuter;
    final innerPaint = Paint()..color = budInner.withValues(alpha: 0.85);

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 20, height: 30),
      budPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: 11, height: 18),
      innerPaint,
    );

    canvas.restore();
  }

  Path _buildLeafPath(double length, double width, double curl) {
    return Path()
      ..moveTo(0, 0)
      ..cubicTo(
        width * 0.55,
        -length * 0.18,
        width * 0.95,
        -length * 0.60,
        curl,
        -length,
      )
      ..cubicTo(
        width * 0.25,
        -length * 0.72,
        width * 0.06,
        -length * 0.24,
        0,
        0,
      )
      ..close();
  }

  Path _buildLeafHighlightPath(double length, double width, double curl) {
    return Path()
      ..moveTo(width * 0.08, -length * 0.12)
      ..cubicTo(
        width * 0.34,
        -length * 0.22,
        width * 0.36,
        -length * 0.52,
        curl * 0.45,
        -length * 0.74,
      )
      ..cubicTo(
        width * 0.12,
        -length * 0.58,
        width * 0.06,
        -length * 0.20,
        width * 0.08,
        -length * 0.12,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant PlantPainter oldDelegate) {
    return true;
  }
}

double smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double easeOutBack(double t) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
}
