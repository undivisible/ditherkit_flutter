import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dither/dither_paint.dart';
import '../dither/palette.dart';
import '../dither/primitives.dart';

typedef DitherChartRow = Map<String, Object?>;

enum DitherChartKind { area, line, bar }

enum DitherStackType { defaultValue, stacked, percent }

class DitherSeries {
  const DitherSeries({
    required this.dataKey,
    required this.color,
    this.label,
    this.variant = DitherVariant.gradient,
    this.isClickable = false,
  });

  final String dataKey;
  final DitherColor color;
  final String? label;
  final DitherVariant variant;
  final bool isClickable;
}

class DitherReferenceLine {
  const DitherReferenceLine({required this.value, this.label});

  final double value;
  final String? label;
}

class DitherCartesianChart extends StatefulWidget {
  const DitherCartesianChart({
    required this.data,
    required this.series,
    this.kind = DitherChartKind.area,
    this.height = 240,
    this.stackType = DitherStackType.defaultValue,
    this.labelKey,
    this.showGrid = true,
    this.showAxes = true,
    this.showLegend = false,
    this.showTooltip = true,
    this.interactive = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 700),
    this.replayToken = 0,
    this.hovered = false,
    this.markerIndex,
    this.bloom = DitherBloom.off,
    this.bloomOnHover = false,
    this.referenceLine,
    this.selectedDataKey,
    this.onHoverChange,
    this.onSelectionChange,
    super.key,
  });

  final List<DitherChartRow> data;
  final List<DitherSeries> series;
  final DitherChartKind kind;
  final double height;
  final DitherStackType stackType;
  final String? labelKey;
  final bool showGrid;
  final bool showAxes;
  final bool showLegend;
  final bool showTooltip;
  final bool interactive;
  final bool animate;
  final Duration animationDuration;
  final Object replayToken;
  final bool hovered;
  final int? markerIndex;
  final DitherBloom bloom;
  final bool bloomOnHover;
  final DitherReferenceLine? referenceLine;
  final String? selectedDataKey;
  final ValueChanged<int?>? onHoverChange;
  final ValueChanged<String?>? onSelectionChange;

  @override
  State<DitherCartesianChart> createState() => _DitherCartesianChartState();
}

class _DitherCartesianChartState extends State<DitherCartesianChart>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(vsync: this);
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool? _reducedMotion;
  int? _hoverIndex;
  String? _hoverSeries;
  String? _selected;
  bool _pointerInside = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduced) return;
    _reducedMotion = reduced;
    _play();
  }

  @override
  void didUpdateWidget(covariant DitherCartesianChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.series != widget.series ||
        oldWidget.replayToken != widget.replayToken ||
        oldWidget.animate != widget.animate ||
        oldWidget.animationDuration != widget.animationDuration) {
      _play();
    }
  }

  void _play() {
    _entrance.duration = widget.animationDuration;
    if (!widget.animate || _reducedMotion == true) {
      _entrance.value = 1;
      _idle.stop();
    } else {
      _entrance.forward(from: 0);
      _idle.repeat();
    }
  }

  void _setHover(Offset position, Size size) {
    if (!widget.interactive || widget.data.isEmpty) return;
    final plot = _plotRect(size, widget.showAxes);
    final index = _nearestIndex(position.dx, plot, widget.data.length);
    final layout = _CartesianLayout.from(
      widget.data,
      widget.series,
      widget.stackType,
    );
    final series = _nearestSeries(position, plot, layout, widget.kind);
    if (_hoverIndex == index && _hoverSeries == series?.dataKey) return;
    setState(() {
      _hoverIndex = index;
      _hoverSeries = series?.dataKey;
    });
    widget.onHoverChange?.call(index);
  }

  void _clearHover() {
    if (_hoverIndex == null && !_pointerInside) return;
    setState(() {
      _hoverIndex = null;
      _hoverSeries = null;
      _pointerInside = false;
    });
    widget.onHoverChange?.call(null);
  }

  void _select() {
    final hovered = _hoverSeries;
    if (hovered == null ||
        !widget.series.any(
          (series) => series.dataKey == hovered && series.isClickable,
        ))
      return;
    final next = (_selected ?? widget.selectedDataKey) == hovered
        ? null
        : hovered;
    setState(() => _selected = next);
    widget.onSelectionChange?.call(next);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedDataKey ?? _selected;
    final visibleHover = widget.markerIndex ?? _hoverIndex;
    final reduced = _reducedMotion == true || !widget.animate;
    final chart = AnimatedBuilder(
      animation: Listenable.merge([_entrance, _idle]),
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final layout = _CartesianLayout.from(
            widget.data,
            widget.series,
            widget.stackType,
          );
          final painter = _CartesianPainter(
            layout: layout,
            kind: widget.kind,
            showGrid: widget.showGrid,
            showAxes: widget.showAxes,
            reveal: reduced
                ? 1
                : Curves.easeInOutCubic.transform(_entrance.value),
            idlePhase: reduced ? null : _idle.value,
            hovered: visibleHover,
            hoveredSeries: _hoverSeries,
            selected: selected,
            intensity: widget.hovered || _pointerInside ? 1 : 0,
            bloom: widget.bloom,
            bloomOnHover: widget.bloomOnHover,
            pointerInside: _pointerInside || widget.hovered,
            referenceLine: widget.referenceLine,
          );
          return MouseRegion(
            onEnter: widget.interactive
                ? (_) => setState(() => _pointerInside = true)
                : null,
            onExit: widget.interactive ? (_) => _clearHover() : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.interactive ? _select : null,
              onPanDown: widget.interactive
                  ? (details) => _setHover(details.localPosition, size)
                  : null,
              onPanUpdate: widget.interactive
                  ? (details) => _setHover(details.localPosition, size)
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(size: Size.infinite, painter: painter),
                  if (widget.showTooltip &&
                      visibleHover != null &&
                      widget.data.isNotEmpty)
                    _CartesianTooltip(
                      layout: layout,
                      index: visibleHover.clamp(0, widget.data.length - 1),
                      labelKey: widget.labelKey,
                      selected: selected,
                      rect: _plotRect(size, widget.showAxes),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    final body = SizedBox(height: widget.height, child: chart);
    if (!widget.showLegend) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: widget.series
              .map((series) {
                final dimmed = selected != null && selected != series.dataKey;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoverSeries = series.dataKey),
                  onExit: (_) => setState(() => _hoverSeries = null),
                  child: Opacity(
                    opacity: dimmed ? 0.4 : 1,
                    child: TextButton.icon(
                      onPressed: series.isClickable
                          ? () {
                              final next = selected == series.dataKey
                                  ? null
                                  : series.dataKey;
                              setState(() => _selected = next);
                              widget.onSelectionChange?.call(next);
                            }
                          : null,
                      icon: Container(
                        width: 8,
                        height: 8,
                        color: ditherRgb(seedOf(series.color).fill),
                      ),
                      label: Text(series.label ?? series.dataKey),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        body,
      ],
    );
  }
}

class _CartesianTooltip extends StatelessWidget {
  const _CartesianTooltip({
    required this.layout,
    required this.index,
    required this.labelKey,
    required this.selected,
    required this.rect,
  });

  final _CartesianLayout layout;
  final int index;
  final String? labelKey;
  final String? selected;
  final Rect rect;

  @override
  Widget build(BuildContext context) {
    final x =
        rect.left +
        (layout.data.length <= 1
            ? 0
            : index / (layout.data.length - 1) * rect.width);
    final top = rect.top + 4;
    final label = labelKey == null
        ? null
        : layout.data[index][labelKey]?.toString();
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      left: (x - 72).clamp(0.0, math.max(0.0, rect.right - 144)).toDouble(),
      top: top,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xee0b0b0c),
            border: Border.all(color: const Color(0xff383838)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xffeeeeea),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(
                      label,
                      style: const TextStyle(color: Color(0xffa0a0a0)),
                    ),
                  for (final series in layout.series)
                    Opacity(
                      opacity: selected != null && selected != series.dataKey
                          ? 0.4
                          : 1,
                      child: Text(
                        '${series.label ?? series.dataKey}  ${_number(layout.valueAt(series.dataKey, index))}',
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

class _CartesianPainter extends CustomPainter {
  const _CartesianPainter({
    required this.layout,
    required this.kind,
    required this.showGrid,
    required this.showAxes,
    required this.reveal,
    required this.idlePhase,
    required this.hovered,
    required this.hoveredSeries,
    required this.selected,
    required this.intensity,
    required this.bloom,
    required this.bloomOnHover,
    required this.pointerInside,
    required this.referenceLine,
  });

  final _CartesianLayout layout;
  final DitherChartKind kind;
  final bool showGrid;
  final bool showAxes;
  final double reveal;
  final double? idlePhase;
  final int? hovered;
  final String? hoveredSeries;
  final String? selected;
  final double intensity;
  final DitherBloom bloom;
  final bool bloomOnHover;
  final bool pointerInside;
  final DitherReferenceLine? referenceLine;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.data.isEmpty || size.isEmpty) return;
    final plot = _plotRect(size, showAxes);
    if (plot.width <= 0 || plot.height <= 0) return;
    canvas.save();
    canvas.clipRect(plot);
    if (showGrid) _paintGrid(canvas, plot);
    final baseline = _y(0, plot, layout);
    final selectedKey = selected ?? hoveredSeries;
    final rendered = <Path>[];
    for (
      var seriesIndex = 0;
      seriesIndex < layout.series.length;
      seriesIndex++
    ) {
      final series = layout.series[seriesIndex];
      final bands = layout.bands[series.dataKey]!;
      final dim = selectedKey != null && selectedKey != series.dataKey
          ? 0.3
          : 1.0;
      final localIntensity =
          intensity + (hoveredSeries == series.dataKey ? 0.4 : 0);
      if (kind == DitherChartKind.bar) {
        _paintBars(canvas, plot, bands, series, baseline, dim, localIntensity);
      } else {
        final line = _paintContinuous(
          canvas,
          plot,
          bands,
          series,
          dim,
          localIntensity,
        );
        rendered.add(line);
      }
    }
    if (bloom != DitherBloom.off && (!bloomOnHover || pointerInside)) {
      final blur = bloom == DitherBloom.aura
          ? 16.0
          : bloom == DitherBloom.high
          ? 6.0
          : 3.0;
      final alpha = bloom == DitherBloom.aura ? 0.1 : 0.25;
      for (var i = 0; i < rendered.length; i++) {
        final series = layout.series[i];
        canvas.drawPath(
          rendered[i],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = bloom == DitherBloom.aura ? 5 : 2
            ..color = ditherRgb(
              seedOf(series.color).lineOrFill,
            ).withValues(alpha: alpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
      }
    }
    if (referenceLine != null) {
      final y = _y(referenceLine!.value, plot, layout);
      final line = Paint()
        ..color = const Color(0xff8a8a8a)
        ..strokeWidth = 1;
      for (var x = plot.left; x < plot.right; x += 7) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 4, plot.right), y),
          line,
        );
      }
    }
    if (hovered != null)
      _paintHover(canvas, plot, hovered!.clamp(0, layout.data.length - 1));
    canvas.restore();
    if (showAxes) _paintAxes(canvas, size, plot);
  }

  void _paintGrid(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..color = const Color(0xff2a2a2a)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      for (var x = plot.left; x < plot.right; x += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, plot.right), y),
          paint,
        );
      }
    }
  }

  void _paintAxes(Canvas canvas, Size size, Rect plot) {
    final paint = Paint()
      ..color = const Color(0xff525252)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(plot.left, plot.top),
      Offset(plot.left, plot.bottom),
      paint,
    );
    final labels = [layout.max, (layout.max + layout.min) / 2, layout.min];
    for (var i = 0; i < labels.length; i++) {
      final span = TextSpan(
        text: _number(labels[i]),
        style: const TextStyle(
          color: Color(0xff898989),
          fontFamily: 'monospace',
          fontSize: 9,
        ),
      );
      final text = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout(maxWidth: 30);
      final y = plot.top + (plot.height - text.height) * i / 2;
      text.paint(canvas, Offset(1, y));
    }
  }

  Path _paintContinuous(
    Canvas canvas,
    Rect plot,
    List<_Band> bands,
    DitherSeries series,
    double dim,
    double localIntensity,
  ) {
    final backing = backingSize(plot.width, plot.height);
    final cols = backing.cols;
    final rows = backing.rows;
    final top = List<int>.generate(cols, (column) {
      final source = _interpolateBand(bands, column / math.max(1, cols - 1));
      final value = source.high;
      return ((_y(value, plot, layout) - plot.top) / plot.height * (rows - 1))
          .round()
          .clamp(0, rows - 1);
    });
    final floor = List<int>.generate(cols, (column) {
      final source = _interpolateBand(bands, column / math.max(1, cols - 1));
      final value = kind == DitherChartKind.line
          ? source.high - (layout.max - layout.min) * 0.12
          : source.low;
      return ((_y(value, plot, layout) - plot.top) / plot.height * (rows - 1))
          .round()
          .clamp(0, rows - 1);
    });
    final path = Path();
    for (var x = 0; x < cols; x++) {
      final px = plot.left + x / math.max(1, cols - 1) * plot.width;
      final py = plot.top + top[x] / math.max(1, rows - 1) * plot.height;
      if (x == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    final visible = (cols * reveal).ceil();
    canvas.save();
    canvas.translate(plot.left, plot.top);
    canvas.scale(plot.width / cols, plot.height / rows);
    for (var x = 0; x < visible; x++) {
      final start = math.min(top[x], floor[x]);
      final end = math.max(top[x], floor[x]);
      paintDitherColumn(
        canvas,
        x,
        start,
        end,
        seedOf(series.color),
        series.variant,
        intensity: localIntensity,
        dim: dim,
      );
    }
    if (idlePhase != null)
      _paintStars(canvas, top, floor, series, visible, dim);
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = ditherRgb(
          seedOf(series.color).lineOrFill,
        ).withValues(alpha: dim),
    );
    return path;
  }

  void _paintBars(
    Canvas canvas,
    Rect plot,
    List<_Band> bands,
    DitherSeries series,
    double baseline,
    double dim,
    double localIntensity,
  ) {
    final count = math.max(1, layout.data.length);
    final group = plot.width / count;
    final seriesIndex = layout.series.indexOf(series);
    final width =
        kind == DitherChartKind.bar &&
            layout.stackType == DitherStackType.defaultValue
        ? group * 0.72 / math.max(1, layout.series.length)
        : group * 0.72;
    for (var index = 0; index < bands.length; index++) {
      final band = bands[index];
      final left =
          plot.left +
          index * group +
          group * 0.14 +
          (layout.stackType == DitherStackType.defaultValue
              ? seriesIndex * width
              : 0);
      final top = _y(band.high, plot, layout);
      final floor = _y(band.low, plot, layout);
      final revealStart = index / math.max(1, bands.length - 1) * 0.45;
      final progress = clamp01((reveal - revealStart) / 0.55);
      final grown =
          baseline + (top - baseline) * Curves.easeOutCubic.transform(progress);
      final rect = Rect.fromLTRB(
        left,
        math.min(grown, baseline),
        left + width,
        math.max(grown, baseline),
      );
      if (rect.height <= 0) continue;
      final backing = backingSize(rect.width, rect.height);
      canvas.save();
      canvas.clipRect(rect);
      canvas.translate(rect.left, rect.top);
      canvas.scale(rect.width / backing.cols, rect.height / backing.rows);
      for (var x = 0; x < backing.cols; x++) {
        paintDitherColumn(
          canvas,
          x,
          0,
          backing.rows - 1,
          seedOf(series.color),
          series.variant,
          intensity: localIntensity,
          dim: dim,
        );
      }
      canvas.restore();
      canvas.drawRect(
        Rect.fromLTRB(
          left,
          math.min(top, floor),
          left + width,
          math.max(top, floor),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ditherRgb(
            seedOf(series.color).lineOrFill,
          ).withValues(alpha: dim),
      );
    }
  }

  void _paintStars(
    Canvas canvas,
    List<int> top,
    List<int> floor,
    DitherSeries series,
    int visible,
    double dim,
  ) {
    final phase = idlePhase!;
    final count = math.max(4, top.length ~/ 14);
    for (var i = 0; i < count; i++) {
      final x = (i * 67 + 13) % top.length;
      if (x >= visible) continue;
      final y = (top[x] + ((floor[x] - top[x]) * ((i * 53 + 7) % 100) / 100))
          .round();
      final twinkle = (math.sin((phase * 4 + i * 0.71) * math.pi * 2) + 1) / 2;
      if (twinkle < 0.55) continue;
      final paint = Paint()
        ..color = ditherRgb(
          seedOf(series.color).starOrFill,
        ).withValues(alpha: twinkle * dim);
      canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      if (twinkle > 0.9) {
        canvas.drawRect(Rect.fromLTWH(x - 1.0, y.toDouble(), 3, 1), paint);
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y - 1.0, 1, 3), paint);
      }
    }
  }

  void _paintHover(Canvas canvas, Rect plot, int index) {
    final x =
        plot.left +
        (layout.data.length <= 1
            ? 0
            : index / (layout.data.length - 1) * plot.width);
    final paint = Paint()
      ..color = const Color(0xffd3d3d3).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var y = plot.top; y < plot.bottom; y += 6) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + 3, plot.bottom)),
        paint,
      );
    }
    for (final series in layout.series) {
      final band = layout.bands[series.dataKey]![index];
      final point = Offset(x, _y(band.high, plot, layout));
      final color = ditherRgb(seedOf(series.color).lineOrFill);
      canvas.drawCircle(
        point,
        5,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(point, 2.5, Paint()..color = const Color(0xff0b0b0c));
      canvas.drawCircle(
        point,
        2.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CartesianPainter oldDelegate) => true;
}

class _CartesianLayout {
  const _CartesianLayout(
    this.data,
    this.series,
    this.stackType,
    this.bands,
    this.min,
    this.max,
  );

  factory _CartesianLayout.from(
    List<DitherChartRow> data,
    List<DitherSeries> series,
    DitherStackType stackType,
  ) {
    final bands = <String, List<_Band>>{
      for (final item in series) item.dataKey: [],
    };
    var min = 0.0;
    var max = 0.0;
    for (final row in data) {
      var positive = 0.0;
      var negative = 0.0;
      final total = stackType == DitherStackType.percent
          ? series.fold<double>(
              0,
              (sum, item) => sum + _value(row[item.dataKey]).abs(),
            )
          : 1.0;
      for (final item in series) {
        var value = _value(row[item.dataKey]);
        if (stackType == DitherStackType.percent && total > 0) value /= total;
        final low = stackType == DitherStackType.defaultValue
            ? 0.0
            : value < 0
            ? negative
            : positive;
        final high = low + value;
        bands[item.dataKey]!.add(_Band(low, high));
        if (stackType != DitherStackType.defaultValue) {
          if (value < 0)
            negative = high;
          else
            positive = high;
        }
        min = math.min(min, math.min(low, high));
        max = math.max(max, math.max(low, high));
      }
    }
    if (min == max) max = min + 1;
    return _CartesianLayout(data, series, stackType, bands, min, max);
  }

  final List<DitherChartRow> data;
  final List<DitherSeries> series;
  final DitherStackType stackType;
  final Map<String, List<_Band>> bands;
  final double min;
  final double max;

  double valueAt(String key, int index) => _value(data[index][key]);
}

class _Band {
  const _Band(this.low, this.high);

  final double low;
  final double high;
}

Rect _plotRect(Size size, bool axes) {
  final left = axes ? 34.0 : 0.0;
  final right = axes ? 8.0 : 0.0;
  final top = 10.0;
  final bottom = axes ? 22.0 : 0.0;
  return Rect.fromLTWH(
    left,
    top,
    math.max(1.0, size.width - left - right),
    math.max(1.0, size.height - top - bottom),
  );
}

double _y(double value, Rect plot, _CartesianLayout layout) =>
    plot.bottom -
    (value - layout.min) / (layout.max - layout.min) * plot.height;

int _nearestIndex(double x, Rect plot, int length) {
  if (length <= 1) return 0;
  return (((x - plot.left) / plot.width).clamp(0.0, 1.0) * (length - 1))
      .round();
}

DitherSeries? _nearestSeries(
  Offset point,
  Rect plot,
  _CartesianLayout layout,
  DitherChartKind kind,
) {
  if (layout.series.isEmpty || layout.data.isEmpty) return null;
  final index = _nearestIndex(point.dx, plot, layout.data.length);
  DitherSeries? closest;
  var distance = double.infinity;
  for (final series in layout.series) {
    final band = layout.bands[series.dataKey]![index];
    final value = kind == DitherChartKind.bar
        ? (band.low + band.high) / 2
        : band.high;
    final candidate = (_y(value, plot, layout) - point.dy).abs();
    if (candidate < distance) {
      distance = candidate;
      closest = series;
    }
  }
  return closest;
}

_Band _interpolateBand(List<_Band> source, double t) {
  if (source.length == 1) return source.first;
  final raw = t * (source.length - 1);
  final i = raw.floor();
  final fraction = raw - i;
  final a = source[i];
  final b = source[math.min(i + 1, source.length - 1)];
  return _Band(
    a.low + (b.low - a.low) * fraction,
    a.high + (b.high - a.high) * fraction,
  );
}

double _value(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : 0;

String _number(double value) => value.abs() >= 1000
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
