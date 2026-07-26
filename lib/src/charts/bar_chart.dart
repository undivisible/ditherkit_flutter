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
    this.interactive = true,
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
  final double intensity;
  final bool animate;
  final bool interactive;
  final int? markerIndex;
  final bool hovered;
  final ValueChanged<int?>? onHoverChange;
  final ValueChanged<int?>? onSelectionChange;
  final Object replayToken;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    return DitherChartCanvas(
      height: height,
      animate: animate,
      replayKey: (Object.hashAll(values), replayToken),
      seriesLength: values.length,
      interactive: interactive,
      markerIndex: markerIndex,
      hovered: hovered,
      onHoverChange: onHoverChange,
      onSelectionChange: onSelectionChange,
      painter: (reveal, idlePhase, markerIndex, hoverIntensity) =>
          DitherBarPainter(
            values: values,
            color: color,
            variant: variant,
            intensity: intensity + hoverIntensity,
            reveal: reveal,
            markerIndex: markerIndex,
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
    this.markerIndex,
  });

  final List<double> values;
  final DitherColor color;
  final DitherVariant variant;
  final double intensity;
  final double reveal;
  final int? markerIndex;

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
      markerIndex: markerIndex,
    );
  }

  @override
  bool shouldRepaint(covariant DitherBarPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.variant != variant ||
        oldDelegate.intensity != intensity ||
        oldDelegate.reveal != reveal ||
        oldDelegate.markerIndex != markerIndex;
  }
}
