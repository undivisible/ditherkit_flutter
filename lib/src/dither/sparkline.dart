import 'package:flutter/material.dart';

import 'dither_paint.dart';
import 'palette.dart';
import '../charts/chart_motion.dart';

/// Full-width dithered sparkline (dither-kit port).
class DitherSparkline extends StatelessWidget {
  const DitherSparkline({
    required this.values,
    this.color = DitherColor.blue,
    this.variant = DitherVariant.gradient,
    this.height = 56,
    this.animate = false,
    super.key,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return DitherChartCanvas(
      height: height,
      animate: animate,
      replayKey: values,
      painter: (reveal, idlePhase) => _SparklinePainter(
        values: values,
        color: color,
        variant: variant,
        reveal: reveal,
        idlePhase: idlePhase,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.variant,
    this.reveal = 1,
    this.idlePhase,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double reveal;
  final double? idlePhase;

  @override
  void paint(Canvas canvas, Size size) {
    paintSparkline(
      canvas,
      size,
      values: values,
      color: color,
      variant: variant,
      reveal: reveal,
      idlePhase: idlePhase,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        oldDelegate.reveal != reveal ||
        oldDelegate.idlePhase != idlePhase;
  }
}

DitherVariant ditherVariantFromName(String? name) {
  return switch (name?.toLowerCase()) {
    'dotted' => DitherVariant.dotted,
    'hatched' => DitherVariant.hatched,
    'solid' => DitherVariant.solid,
    _ => DitherVariant.gradient,
  };
}

List<double> parseSparklineValues(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final cleaned = raw.replaceAll('[', '').replaceAll(']', '');
  return cleaned
      .split(RegExp(r'[,\s]+'))
      .map((part) => double.tryParse(part.trim()))
      .whereType<double>()
      .toList(growable: false);
}
