import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dither/dither_paint.dart';
import '../dither/palette.dart';
import '../dither/primitives.dart';
import 'composable_charts.dart';

class DitherPieSlice {
  const DitherPieSlice({
    required this.name,
    required this.value,
    required this.color,
    this.variant = DitherVariant.gradient,
    this.label,
  });

  final String name;
  final double value;
  final DitherColor color;
  final DitherVariant variant;
  final String? label;
}

class DitherPieChart extends StatefulWidget {
  const DitherPieChart({
    required this.data,
    this.height = 260,
    this.innerRadius = 0,
    this.showLegend = false,
    this.interactive = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 700),
    this.replayToken = 0,
    this.bloom = DitherBloom.off,
    this.bloomOnHover = false,
    this.selectedName,
    this.onSelectionChange,
    super.key,
  }) : assert(innerRadius >= 0 && innerRadius < 1);

  final List<DitherPieSlice> data;
  final double height;
  final double innerRadius;
  final bool showLegend;
  final bool interactive;
  final bool animate;
  final Duration animationDuration;
  final Object replayToken;
  final DitherBloom bloom;
  final bool bloomOnHover;
  final String? selectedName;
  final ValueChanged<String?>? onSelectionChange;

  @override
  State<DitherPieChart> createState() => _DitherPieChartState();
}

class _DitherPieChartState extends State<DitherPieChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool? _reduced;
  int? _hovered;
  String? _selected;
  bool _inside = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    _play();
  }

  @override
  void didUpdateWidget(covariant DitherPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pieSignature(oldWidget) != _pieSignature(widget) ||
        oldWidget.replayToken != widget.replayToken ||
        oldWidget.animate != widget.animate ||
        oldWidget.animationDuration != widget.animationDuration)
      _play();
  }

  void _play() {
    _controller.duration = widget.animationDuration;
    if (!widget.animate || _reduced == true) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _hover(Offset point, Size size) {
    final next = _pieAt(point, size, widget.data, widget.innerRadius);
    if (_hovered == next) return;
    setState(() => _hovered = next);
  }

  void _select() {
    if (_hovered == null) return;
    final name = widget.data[_hovered!].name;
    final next = (widget.selectedName ?? _selected) == name ? null : name;
    setState(() => _selected = next);
    widget.onSelectionChange?.call(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedName ?? _selected;
    final chart = SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return MouseRegion(
              onEnter: widget.interactive
                  ? (_) => setState(() => _inside = true)
                  : null,
              onExit: widget.interactive
                  ? (_) => setState(() {
                      _inside = false;
                      _hovered = null;
                    })
                  : null,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerHover: widget.interactive
                    ? (event) => _hover(event.localPosition, size)
                    : null,
                onPointerDown: widget.interactive
                    ? (event) => _hover(event.localPosition, size)
                    : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: widget.interactive
                      ? (details) => _hover(details.localPosition, size)
                      : null,
                  onPanUpdate: widget.interactive
                      ? (details) => _hover(details.localPosition, size)
                      : null,
                  onTap: widget.interactive ? _select : null,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PiePainter(
                      widget.data,
                      widget.innerRadius,
                      _reduced == true || !widget.animate
                          ? 1
                          : Curves.easeInOutCubic.transform(_controller.value),
                      _hovered,
                      selected,
                      widget.bloom,
                      widget.bloomOnHover,
                      _inside,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (!widget.showLegend) return chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          children: widget.data
              .map(
                (slice) => Text(
                  '${slice.label ?? slice.name}  ${_pieNumber(slice.value)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: ditherRgb(seedOf(slice.color).fill),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        chart,
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter(
    this.data,
    this.inner,
    this.reveal,
    this.hovered,
    this.selected,
    this.bloom,
    this.bloomOnHover,
    this.inside,
  );

  final List<DitherPieSlice> data;
  final double inner;
  final double reveal;
  final int? hovered;
  final String? selected;
  final DitherBloom bloom;
  final bool bloomOnHover;
  final bool inside;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final innerRadius = radius * inner;
    final total = data.fold<double>(
      0,
      (sum, slice) => sum + math.max(0.0, slice.value),
    );
    if (total == 0) return;
    var start = -math.pi / 2;
    final revealEnd = -math.pi / 2 + math.pi * 2 * reveal;
    for (var index = 0; index < data.length; index++) {
      final slice = data[index];
      final end = start + math.pi * 2 * math.max(0.0, slice.value) / total;
      final drawEnd = math.min(end, revealEnd);
      if (drawEnd <= start) break;
      final active = hovered == index;
      final dim = selected != null && selected != slice.name ? 0.3 : 1.0;
      final offset = active
          ? Offset(
                  math.cos((start + drawEnd) / 2),
                  math.sin((start + drawEnd) / 2),
                ) *
                6
          : Offset.zero;
      _paintSlice(
        canvas,
        center + offset,
        radius + (active ? 4 : 0),
        innerRadius,
        start,
        drawEnd,
        slice,
        dim,
        active ? 0.4 : 0,
      );
      if (bloom != DitherBloom.off && (!bloomOnHover || inside)) {
        final path = _wedge(
          center + offset,
          radius + (active ? 4 : 0),
          innerRadius,
          start,
          drawEnd,
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = bloom == DitherBloom.aura ? 12 : 4
            ..color = ditherRgb(
              seedOf(slice.color).fill,
            ).withValues(alpha: bloom == DitherBloom.aura ? 0.1 : 0.2)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              bloom == DitherBloom.aura ? 15 : 5,
            ),
        );
      }
      start = end;
    }
  }

  void _paintSlice(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
    double start,
    double end,
    DitherPieSlice slice,
    double dim,
    double intensity,
  ) {
    final cell = 2.0;
    final fill = ditherRgb(seedOf(slice.color).fill);
    final rim = Paint()
      ..color = ditherRgb(seedOf(slice.color).lineOrFill).withValues(alpha: dim)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = _wedge(center, radius, innerRadius, start, end);
    final bounds = path.getBounds();
    canvas.save();
    canvas.clipPath(path);
    for (var y = bounds.top; y < bounds.bottom; y += cell) {
      for (var x = bounds.left; x < bounds.right; x += cell) {
        final point = Offset(x + cell / 2, y + cell / 2);
        final radial = (point - center).distance;
        final density =
            (radial - innerRadius) / math.max(1.0, radius - innerRadius);
        if (slice.variant == DitherVariant.hatched &&
            (((x ~/ cell).round() + (y ~/ cell).round()) & 3) >= 2)
          continue;
        final lit =
            slice.variant == DitherVariant.solid ||
            density >
                bayerAt((x / cell).round(), (y / cell).round()) -
                    intensity * 0.1 -
                    (slice.variant == DitherVariant.dotted ? 0.12 : 0);
        if (slice.variant == DitherVariant.dotted && !lit) continue;
        final alpha = clamp01(
          (lit ? 1 : offTier) * (0.35 + density * 0.65) * dim,
        );
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          Paint()..color = fill.withValues(alpha: alpha),
        );
      }
    }
    canvas.restore();
    canvas.drawPath(path, rim);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.inner != inner ||
        oldDelegate.reveal != reveal ||
        oldDelegate.hovered != hovered ||
        oldDelegate.selected != selected ||
        oldDelegate.bloom != bloom ||
        oldDelegate.bloomOnHover != bloomOnHover ||
        oldDelegate.inside != inside;
  }
}

class DitherRadarChart extends StatefulWidget {
  const DitherRadarChart({
    required this.data,
    required this.series,
    required this.nameKey,
    this.height = 280,
    this.showLegend = false,
    this.interactive = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 700),
    this.replayToken = 0,
    this.bloom = DitherBloom.off,
    this.bloomOnHover = false,
    this.selectedDataKey,
    this.onSelectionChange,
    super.key,
  });

  final List<DitherChartRow> data;
  final List<DitherSeries> series;
  final String nameKey;
  final double height;
  final bool showLegend;
  final bool interactive;
  final bool animate;
  final Duration animationDuration;
  final Object replayToken;
  final DitherBloom bloom;
  final bool bloomOnHover;
  final String? selectedDataKey;
  final ValueChanged<String?>? onSelectionChange;

  @override
  State<DitherRadarChart> createState() => _DitherRadarChartState();
}

class _DitherRadarChartState extends State<DitherRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool? _reduced;
  int? _hoverAxis;
  String? _selected;
  bool _inside = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    _play();
  }

  @override
  void didUpdateWidget(covariant DitherRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_radarSignature(oldWidget) != _radarSignature(widget) ||
        oldWidget.replayToken != widget.replayToken ||
        oldWidget.animate != widget.animate ||
        oldWidget.animationDuration != widget.animationDuration)
      _play();
  }

  void _play() {
    _controller.duration = widget.animationDuration;
    if (!widget.animate || _reduced == true)
      _controller.value = 1;
    else
      _controller.forward(from: 0);
  }

  void _hover(Offset position, Size size) {
    final next = _radarAxisAt(position, size, widget.data.length);
    if (_hoverAxis == next) return;
    setState(() => _hoverAxis = next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedDataKey ?? _selected;
    final chart = SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return MouseRegion(
              onEnter: widget.interactive
                  ? (_) => setState(() => _inside = true)
                  : null,
              onExit: widget.interactive
                  ? (_) => setState(() {
                      _inside = false;
                      _hoverAxis = null;
                    })
                  : null,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerHover: widget.interactive
                    ? (event) => _hover(event.localPosition, size)
                    : null,
                onPointerDown: widget.interactive
                    ? (event) => _hover(event.localPosition, size)
                    : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: widget.interactive
                      ? (details) => _hover(details.localPosition, size)
                      : null,
                  onPanUpdate: widget.interactive
                      ? (details) => _hover(details.localPosition, size)
                      : null,
                  onTap: widget.interactive && widget.series.isNotEmpty
                      ? () {
                          final next = selected == widget.series.first.dataKey
                              ? null
                              : widget.series.first.dataKey;
                          setState(() => _selected = next);
                          widget.onSelectionChange?.call(next);
                        }
                      : null,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _RadarPainter(
                      widget.data,
                      widget.series,
                      widget.nameKey,
                      _reduced == true || !widget.animate
                          ? 1
                          : Curves.easeInOutCubic.transform(_controller.value),
                      _hoverAxis,
                      selected,
                      widget.bloom,
                      widget.bloomOnHover,
                      _inside,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (!widget.showLegend) return chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          children: widget.series
              .map(
                (series) => Text(
                  series.label ?? series.dataKey,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: ditherRgb(seedOf(series.color).fill),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        chart,
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(
    this.data,
    this.series,
    this.nameKey,
    this.reveal,
    this.hoverAxis,
    this.selected,
    this.bloom,
    this.bloomOnHover,
    this.inside,
  );

  final List<DitherChartRow> data;
  final List<DitherSeries> series;
  final String nameKey;
  final double reveal;
  final int? hoverAxis;
  final String? selected;
  final DitherBloom bloom;
  final bool bloomOnHover;
  final bool inside;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 3 || series.isEmpty || size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    final max = series
        .expand((series) => data.map((row) => _radarValue(row[series.dataKey])))
        .fold<double>(0, math.max);
    final scale = max == 0 ? 1 : max;
    final frame = Paint()
      ..color = const Color(0xff414141)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(
        _radarPath(center, radius * ring / 4, data.length),
        frame,
      );
    }
    for (var i = 0; i < data.length; i++) {
      final end = _radarPoint(center, radius, i, data.length);
      canvas.drawLine(center, end, frame);
      final text = TextPainter(
        text: TextSpan(
          text: data[i][nameKey]?.toString() ?? '',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Color(0xffa2a2a2),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 70);
      text.paint(
        canvas,
        _radarPoint(center, radius + 8, i, data.length) -
            Offset(text.width / 2, text.height / 2),
      );
    }
    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final item = series[seriesIndex];
      final dim = selected != null && selected != item.dataKey ? 0.3 : 1.0;
      final points = List<Offset>.generate(
        data.length,
        (index) => _radarPoint(
          center,
          radius * _radarValue(data[index][item.dataKey]) / scale * reveal,
          index,
          data.length,
        ),
      );
      final path = Path()..addPolygon(points, true);
      if (bloom != DitherBloom.off && (!bloomOnHover || inside))
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = bloom == DitherBloom.aura ? 14 : 5
            ..color = ditherRgb(
              seedOf(item.color).fill,
            ).withValues(alpha: bloom == DitherBloom.aura ? 0.08 : 0.18)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              bloom == DitherBloom.aura ? 16 : 5,
            ),
        );
      _paintRadarFill(canvas, path, center, radius, item, dim, seriesIndex);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = ditherRgb(
            seedOf(item.color).lineOrFill,
          ).withValues(alpha: dim),
      );
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final active = hoverAxis == index;
        final color = ditherRgb(
          seedOf(item.color).lineOrFill,
        ).withValues(alpha: dim);
        canvas.drawCircle(point, active ? 3 : 1.8, Paint()..color = color);
      }
    }
  }

  void _paintRadarFill(
    Canvas canvas,
    Path path,
    Offset center,
    double radius,
    DitherSeries series,
    double dim,
    int layer,
  ) {
    final bounds = path.getBounds();
    final fill = ditherRgb(seedOf(series.color).fill);
    canvas.save();
    canvas.clipPath(path);
    for (var y = bounds.top; y < bounds.bottom; y += 2) {
      for (var x = bounds.left; x < bounds.right; x += 2) {
        final distance =
            (Offset(x, y) - center).distance / math.max(1.0, radius);
        final density = (1 - distance).clamp(0.0, 1.0);
        if (series.variant == DitherVariant.hatched &&
            (((x ~/ 2).round() + (y ~/ 2).round()) & 3) >= 2)
          continue;
        final lit =
            series.variant == DitherVariant.solid ||
            density >
                bayerAt((x / 2).round(), (y / 2).round()) +
                    layer * 0.2 -
                    (series.variant == DitherVariant.dotted ? 0.12 : 0);
        if (series.variant == DitherVariant.dotted && !lit) continue;
        canvas.drawRect(
          Rect.fromLTWH(x, y, 2, 2),
          Paint()
            ..color = fill.withValues(
              alpha: clamp01(
                (lit ? 1 : offTier) * (0.32 + density * 0.68) * dim,
              ),
            ),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.series != series ||
        oldDelegate.nameKey != nameKey ||
        oldDelegate.reveal != reveal ||
        oldDelegate.hoverAxis != hoverAxis ||
        oldDelegate.selected != selected ||
        oldDelegate.bloom != bloom ||
        oldDelegate.bloomOnHover != bloomOnHover ||
        oldDelegate.inside != inside;
  }
}

Path _wedge(
  Offset center,
  double radius,
  double innerRadius,
  double start,
  double end,
) {
  final path = Path();
  path.moveTo(
    center.dx + math.cos(start) * innerRadius,
    center.dy + math.sin(start) * innerRadius,
  );
  path.lineTo(
    center.dx + math.cos(start) * radius,
    center.dy + math.sin(start) * radius,
  );
  path.arcTo(
    Rect.fromCircle(center: center, radius: radius),
    start,
    end - start,
    false,
  );
  if (innerRadius > 0) {
    path.lineTo(
      center.dx + math.cos(end) * innerRadius,
      center.dy + math.sin(end) * innerRadius,
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      end,
      start - end,
      false,
    );
  } else {
    path.lineTo(center.dx, center.dy);
  }
  path.close();
  return path;
}

int? _pieAt(Offset point, Size size, List<DitherPieSlice> data, double inner) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) * 0.42;
  final delta = point - center;
  final distance = delta.distance;
  if (distance < radius * inner || distance > radius + 8) return null;
  var angle = math.atan2(delta.dy, delta.dx);
  if (angle < -math.pi / 2) angle += math.pi * 2;
  final total = data.fold<double>(
    0,
    (sum, slice) => sum + math.max(0.0, slice.value),
  );
  var start = -math.pi / 2;
  for (var index = 0; index < data.length; index++) {
    final end =
        start +
        math.pi * 2 * math.max(0.0, data[index].value) / math.max(1.0, total);
    if (angle >= start && angle <= end) return index;
    start = end;
  }
  return null;
}

Path _radarPath(Offset center, double radius, int count) => Path()
  ..addPolygon(
    List<Offset>.generate(
      count,
      (index) => _radarPoint(center, radius, index, count),
    ),
    true,
  );

Offset _radarPoint(Offset center, double radius, int index, int count) {
  final angle = -math.pi / 2 + math.pi * 2 * index / count;
  return center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

int _radarAxisAt(Offset point, Size size, int count) {
  final center = Offset(size.width / 2, size.height / 2);
  final angle =
      math.atan2(point.dy - center.dy, point.dx - center.dx) + math.pi / 2;
  return ((angle < 0 ? angle + math.pi * 2 : angle) / (math.pi * 2) * count)
          .round() %
      count;
}

double _radarValue(Object? value) =>
    value is num && value.isFinite ? value.toDouble().abs() : 0;

String _pieNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

int _pieSignature(DitherPieChart chart) => Object.hashAll([
  for (final slice in chart.data)
    Object.hash(
      slice.name,
      slice.value,
      slice.color,
      slice.variant,
      slice.label,
    ),
]);

int _radarSignature(DitherRadarChart chart) => Object.hashAll([
  for (final row in chart.data)
    Object.hashAll([
      for (final entry in row.entries) Object.hash(entry.key, entry.value),
    ]),
  for (final series in chart.series)
    Object.hash(
      series.dataKey,
      series.color,
      series.label,
      series.variant,
      series.isClickable,
    ),
]);
