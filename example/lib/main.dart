import 'dart:math' as math;

import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DitherKitExampleApp());
}

class DitherKitExampleApp extends StatelessWidget {
  const DitherKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DitherKit for Flutter',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(surface: Color(0xff0a0a0a)),
        useMaterial3: true,
      ),
      home: const DitherKitExamplePage(),
    );
  }
}

class DitherKitExamplePage extends StatefulWidget {
  const DitherKitExamplePage({super.key});

  @override
  State<DitherKitExamplePage> createState() => _DitherKitExamplePageState();
}

class _DitherKitExamplePageState extends State<DitherKitExamplePage>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: TickerMode(
          enabled: !reducedMotion,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 48),
                children: [
                  const Text(
                    'DITHER KIT',
                    style: TextStyle(
                      color: Color(0xfff5f5f0),
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Dithered charts\nfor Flutter.',
                    style: TextStyle(
                      color: Color(0xfff5f5f0),
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      height: 0.95,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pixel-built CustomPaint charts with an entrance sweep and quiet idle sparkles.',
                    style: TextStyle(color: Color(0xffa1a1a1), fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  _DitherPanel(
                    title: 'Weekly activity',
                    kind: 'AREA / GRADIENT',
                    color: DitherColor.purple,
                    entrance: _entrance,
                    idle: _idle,
                    reducedMotion: reducedMotion,
                    child: const DitherAreaChart(
                      values: [18, 32, 26, 49, 38, 64, 58, 74, 66, 92],
                      color: DitherColor.purple,
                      variant: DitherVariant.gradient,
                      height: 220,
                      intensity: 0.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DitherPanel(
                    title: 'Release cadence',
                    kind: 'BAR / HATCHED',
                    color: DitherColor.orange,
                    entrance: _entrance,
                    idle: _idle,
                    reducedMotion: reducedMotion,
                    child: const DitherBarChart(
                      values: [4, 8, 5, 12, 9, 15, 11],
                      color: DitherColor.orange,
                      variant: DitherVariant.hatched,
                      height: 180,
                      intensity: 0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DitherPanel(
                    title: 'Live signal',
                    kind: 'SPARKLINE / DOTTED',
                    color: DitherColor.green,
                    entrance: _entrance,
                    idle: _idle,
                    reducedMotion: reducedMotion,
                    child: const DitherSparkline(
                      values: [5, 8, 6, 13, 10, 18, 15, 24, 19, 30],
                      color: DitherColor.green,
                      variant: DitherVariant.dotted,
                      height: 120,
                    ),
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

class _DitherPanel extends StatelessWidget {
  const _DitherPanel({
    required this.title,
    required this.kind,
    required this.color,
    required this.entrance,
    required this.idle,
    required this.reducedMotion,
    required this.child,
  });

  final String title;
  final String kind;
  final DitherColor color;
  final Animation<double> entrance;
  final Animation<double> idle;
  final bool reducedMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title $kind chart',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xff070707),
          border: Border.fromBorderSide(BorderSide(color: Color(0xff282828))),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xffededeb),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    kind,
                    style: const TextStyle(
                      color: Color(0xff8b8b8b),
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DitherMotion(
                color: color,
                entrance: entrance,
                idle: idle,
                reducedMotion: reducedMotion,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DitherMotion extends StatelessWidget {
  const _DitherMotion({
    required this.color,
    required this.entrance,
    required this.idle,
    required this.reducedMotion,
    required this.child,
  });

  final DitherColor color;
  final Animation<double> entrance;
  final Animation<double> idle;
  final bool reducedMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entrance, idle]),
      child: child,
      builder: (context, child) {
        final reveal = reducedMotion
            ? 1.0
            : Curves.easeOutCubic.transform(entrance.value);
        return Stack(
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: reveal,
                child: child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SparklePainter(
                    color: color,
                    phase: reducedMotion ? 0 : idle.value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color, required this.phase});

  final DitherColor color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    const stars = [
      (0.16, 0.32, 0.08),
      (0.42, 0.72, 0.31),
      (0.69, 0.44, 0.57),
      (0.88, 0.66, 0.82),
    ];
    final star = ditherRgb(seedOf(color).starOrFill);
    for (final (xFactor, yFactor, offset) in stars) {
      final glint = (math.sin((phase + offset) * math.pi * 2) + 1) / 2;
      if (glint < 0.58) continue;
      final center = Offset(size.width * xFactor, size.height * yFactor);
      final paint = Paint()..color = star.withValues(alpha: glint * 0.7);
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 2, height: 8 * glint),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 8 * glint, height: 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.phase != phase;
  }
}
