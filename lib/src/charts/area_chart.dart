import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dither/dither_paint.dart';
import '../dither/palette.dart';
import 'chart_motion.dart';

/// Full-width dithered area chart (same paint engine as [DitherSparkline]).
class DitherAreaChart extends StatelessWidget {
  const DitherAreaChart({
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
    if (values.length < 2) return SizedBox(height: height);
    return DitherChartCanvas(
      height: height,
      animate: animate,
      replayKey: values,
      painter: (reveal, idlePhase) => DitherAreaPainter(
        values: values,
        color: color,
        variant: variant,
        intensity: intensity,
        reveal: reveal,
        idlePhase: idlePhase,
      ),
    );
  }
}

class DitherAreaPainter extends CustomPainter {
  DitherAreaPainter({
    required this.values,
    required this.color,
    required this.variant,
    this.intensity = 0,
    this.reveal = 1,
    this.idlePhase,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double intensity;
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
      intensity: intensity,
      reveal: reveal,
      idlePhase: idlePhase,
    );
  }

  @override
  bool shouldRepaint(covariant DitherAreaPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        oldDelegate.intensity != intensity ||
        oldDelegate.reveal != reveal ||
        oldDelegate.idlePhase != idlePhase;
  }
}

/// Paint discrete bars with the same Bayer column engine.
void paintBarChart(
  Canvas canvas,
  Size size, {
  required List<double> values,
  required DitherColor color,
  DitherVariant variant = DitherVariant.gradient,
  double intensity = 0,
  double gapFraction = 0.2,
  double reveal = 1,
}) {
  if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
  final backing = backingSize(size.width, size.height);
  final cols = backing.cols;
  final rows = backing.rows;
  final min = math.min(0.0, values.reduce(math.min));
  final max = math.max(0.0, values.reduce(math.max));
  final span = math.max(max - min, 1e-9);
  final n = values.length;
  final barWidth = math.max(1, (cols / n * (1 - gapFraction)).floor());
  final stride = cols / n;
  final seed = seedOf(color);
  final baseline = (rows - 1 - (0 - min) / span * (rows - 1)).round().clamp(
    0,
    rows - 1,
  );

  canvas.save();
  canvas.scale(size.width / cols, size.height / rows);
  for (var i = 0; i < n; i++) {
    final normalized = (values[i] - min) / span;
    final target = (rows - 1 - normalized * (rows - 1)).round().clamp(
      0,
      rows - 1,
    );
    final start = n > 1 ? i / (n - 1) * 0.55 : 0.0;
    final progress = _easeOutCubic(
      clamp01((clamp01(reveal) - start) / (1 - 0.55)),
    );
    final grown = baseline + (target - baseline) * progress;
    final top = math.min(grown, baseline).round();
    final floor = math.max(grown, baseline).round();
    final x0 = (i * stride + (stride - barWidth) / 2).round();
    for (var x = x0; x < x0 + barWidth && x < cols; x++) {
      paintDitherColumn(
        canvas,
        x,
        top,
        floor,
        seed,
        variant,
        intensity: intensity,
      );
    }
  }
  canvas.restore();
}

double _easeOutCubic(double value) => 1 - math.pow(1 - value, 3).toDouble();
