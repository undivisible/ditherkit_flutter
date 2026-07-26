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
    this.interactive = false,
    this.markerIndex,
    this.hovered = false,
    this.onHoverChange,
    this.onSelectionChange,
    this.replayToken = 0,
    super.key,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double height;
  final bool animate;
  final bool interactive;
  final int? markerIndex;
  final bool hovered;
  final ValueChanged<int?>? onHoverChange;
  final ValueChanged<int?>? onSelectionChange;
  final Object replayToken;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return DitherChartCanvas(
      height: height,
      animate: animate,
      replayKey: (values, replayToken),
      seriesLength: values.length,
      interactive: interactive,
      markerIndex: markerIndex,
      hovered: hovered,
      onHoverChange: onHoverChange,
      onSelectionChange: onSelectionChange,
      painter: (reveal, idlePhase, markerIndex, hoverIntensity) =>
          _SparklinePainter(
            values: values,
            color: color,
            variant: variant,
            intensity: hoverIntensity,
            reveal: reveal,
            idlePhase: idlePhase,
            markerIndex: markerIndex,
          ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.variant,
    this.intensity = 0,
    this.reveal = 1,
    this.idlePhase,
    this.markerIndex,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double intensity;
  final double reveal;
  final double? idlePhase;
  final int? markerIndex;

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
      markerIndex: markerIndex,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        oldDelegate.intensity != intensity ||
        oldDelegate.reveal != reveal ||
        oldDelegate.idlePhase != idlePhase ||
        oldDelegate.markerIndex != markerIndex;
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
