import 'package:flutter/material.dart';

class DitherChartCanvas extends StatefulWidget {
  const DitherChartCanvas({
    required this.height,
    required this.animate,
    required this.replayKey,
    required this.painter,
    super.key,
  });

  final double height;
  final bool animate;
  final Object replayKey;
  final CustomPainter Function(double reveal, double? idlePhase) painter;

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
  bool? _reducedMotion;

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
  }

  void _play() {
    if (!widget.animate || _reducedMotion == true) {
      _entrance.value = 1;
      _idle.value = 0;
      _idle.stop();
      return;
    }
    _entrance.forward(from: 0);
    _idle.repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _idle]),
      builder: (context, child) => SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: widget.painter(
            _reducedMotion == true || !widget.animate
                ? 1
                : Curves.easeOutCubic.transform(_entrance.value),
            _reducedMotion == true || !widget.animate ? null : _idle.value,
          ),
          willChange: widget.animate && _reducedMotion != true,
        ),
      ),
    );
  }
}
