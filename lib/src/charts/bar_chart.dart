import 'package:flutter/material.dart';

import '../dither/dither_paint.dart';
import '../dither/palette.dart';
import 'area_chart.dart';
import 'chart_motion.dart';

/// Full-width dithered bar chart.
class DitherBarChart extends StatelessWidget {
  const DitherBarChart({
    required this.values,
    this.color = DitherColor.blue,
    this.variant = DitherVariant.gradient,
    this.height = 120,
    this.intensity = 0,
    this.animate = true,
    super.key,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double height;
  final double intensity;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    return DitherChartCanvas(
      height: height,
      animate: animate,
      replayKey: values,
      painter: (reveal, idlePhase) => DitherBarPainter(
        values: values,
        color: color,
        variant: variant,
        intensity: intensity,
        reveal: reveal,
      ),
    );
  }
}

class DitherBarPainter extends CustomPainter {
  DitherBarPainter({
    required this.values,
    required this.color,
    required this.variant,
    this.intensity = 0,
    this.reveal = 1,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double intensity;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    paintBarChart(
      canvas,
      size,
      values: values,
      color: color,
      variant: variant,
      intensity: intensity,
      reveal: reveal,
    );
  }

  @override
  bool shouldRepaint(covariant DitherBarPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        oldDelegate.intensity != intensity ||
        oldDelegate.reveal != reveal;
  }
}
