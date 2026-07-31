import 'dart:math' as math;

import 'package:flutter/material.dart';

class DitherChartCanvas extends StatefulWidget {
  const DitherChartCanvas({
    required this.height,
    required this.animate,
    required this.replayKey,
    required this.seriesLength,
    required this.painter,
    this.interactive = true,
    this.idleAnimation = false,
    this.markerIndex,
    this.hovered = false,
    this.onHoverChange,
    this.onSelectionChange,
    super.key,
  });

  final double height;
  final bool animate;
  final Object replayKey;
  final int seriesLength;
  final bool interactive;
  final bool idleAnimation;
  final int? markerIndex;
  final bool hovered;
  final ValueChanged<int?>? onHoverChange;
  final ValueChanged<int?>? onSelectionChange;
  final CustomPainter Function(
    double reveal,
    double? idlePhase,
    int? markerIndex,
    double intensity,
  )
  painter;

  @override
  State<DitherChartCanvas> createState() => _DitherChartCanvasState();
}

class _DitherChartCanvasState extends State<DitherChartCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  bool? _reducedMotion;
  int? _hoverIndex;
  int? _selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    _play();
  }

  @override
  void didUpdateWidget(covariant DitherChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayKey != widget.replayKey ||
        oldWidget.animate != widget.animate) {
      _play();
    }
    _syncIdle();
  }

  void _play() {
    if (!widget.animate || _reducedMotion == true) {
      _entrance.value = 1;
      _syncIdle();
      _hover.value = widget.hovered ? 1 : 0;
      return;
    }
    _entrance.forward(from: 0);
    _syncIdle();
  }

  void _syncIdle() {
    final active =
        widget.idleAnimation &&
        widget.animate &&
        _reducedMotion != true &&
        (widget.hovered || _hoverIndex != null);
    if (active) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle
        ..stop()
        ..value = 0;
    }
  }

  void _setHover(Offset position, Size size) {
    if (!widget.interactive || size.width <= 0) return;
    final length = widget.seriesLength;
    if (length == 0) return;
    final index = (position.dx / size.width * math.max(1, length - 1))
        .round()
        .clamp(0, length - 1);
    if (_hoverIndex != index) {
      setState(() => _hoverIndex = index);
      widget.onHoverChange?.call(index);
      _syncIdle();
    }
    if (_reducedMotion != true) _hover.forward();
  }

  void _clearHover() {
    if (_hoverIndex != null) {
      setState(() => _hoverIndex = null);
      widget.onHoverChange?.call(null);
      _syncIdle();
    }
    if (_reducedMotion != true && !widget.hovered) _hover.reverse();
  }

  void _select() {
    if (!widget.interactive) return;
    final next = _hoverIndex == _selectedIndex ? null : _hoverIndex;
    setState(() => _selectedIndex = next);
    widget.onSelectionChange?.call(next);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _idle, _hover]),
      builder: (context, child) => SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return MouseRegion(
              onExit: widget.interactive ? (_) => _clearHover() : null,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerHover: widget.interactive
                    ? (event) => _setHover(event.localPosition, size)
                    : null,
                onPointerDown: widget.interactive
                    ? (event) => _setHover(event.localPosition, size)
                    : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.interactive ? _select : null,
                  child: CustomPaint(
                    isComplex: true,
                    painter: widget.painter(
                      _reducedMotion == true || !widget.animate
                          ? 1
                          : Curves.easeOutCubic.transform(_entrance.value),
                      _reducedMotion == true || !widget.animate
                          ? null
                          : _idle.isAnimating
                          ? _idle.value
                          : null,
                      _hoverIndex ?? widget.markerIndex ?? _selectedIndex,
                      _reducedMotion == true
                          ? (widget.hovered ? 1 : 0)
                          : math.max(_hover.value, widget.hovered ? 1 : 0),
                    ),
                    willChange:
                        _entrance.isAnimating ||
                        _idle.isAnimating ||
                        _hover.isAnimating,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
