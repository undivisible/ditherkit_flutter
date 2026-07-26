import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dither_paint.dart';
import 'palette.dart';

enum DitherBloom { off, low, high, aura }

enum DitherAvatarMirror { auto, horizontal, vertical }

enum DitherGradientDirection { up, down, left, right }

typedef DitherPixelColor = Object;

Rgb ditherFillOf(DitherPixelColor color) {
  if (color is DitherColor) return seedOf(color).fill;
  if (color is num) return ditherHueFill(color.toDouble());
  throw ArgumentError.value(color, 'color', 'Expected DitherColor or hue');
}

Rgb ditherHueFill(double hue) {
  final h = (hue % 360 + 360) % 360;
  const saturation = 0.85;
  const lightness = 0.58;
  final chroma = (1 - (2 * lightness - 1).abs()) * saturation;
  final x = chroma * (1 - ((h / 60) % 2 - 1).abs());
  final m = lightness - chroma / 2;
  final (r, g, b) = switch (h) {
    < 60 => (chroma, x, 0.0),
    < 120 => (x, chroma, 0.0),
    < 180 => (0.0, chroma, x),
    < 240 => (0.0, x, chroma),
    < 300 => (x, 0.0, chroma),
    _ => (chroma, 0.0, x),
  };
  return (
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
  );
}

class DitherAvatar extends StatefulWidget {
  const DitherAvatar({
    required this.name,
    this.hue,
    this.mirror = DitherAvatarMirror.auto,
    this.size = 64,
    this.bloom = DitherBloom.off,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 600),
    this.replayToken = 0,
    super.key,
  });

  final String name;
  final double? hue;
  final DitherAvatarMirror mirror;
  final double size;
  final DitherBloom bloom;
  final bool animate;
  final Duration animationDuration;
  final Object replayToken;

  @override
  State<DitherAvatar> createState() => _DitherAvatarState();
}

class _DitherAvatarState extends State<DitherAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
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
  void didUpdateWidget(covariant DitherAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name ||
        oldWidget.hue != widget.hue ||
        oldWidget.mirror != widget.mirror ||
        oldWidget.animate != widget.animate ||
        oldWidget.animationDuration != widget.animationDuration ||
        oldWidget.replayToken != widget.replayToken) {
      _play();
    }
  }

  void _play() {
    _controller.duration = widget.animationDuration;
    if (!widget.animate || _reducedMotion == true) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _AvatarModel.from(widget.name, widget.hue, widget.mirror);
    return Semantics(
      image: true,
      label: '${widget.name} avatar',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _AvatarPainter(
              model,
              Curves.easeOutCubic.transform(_controller.value),
              widget.bloom,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarModel {
  const _AvatarModel(this.on, this.density, this.fill);

  factory _AvatarModel.from(
    String name,
    double? hue,
    DitherAvatarMirror mirror,
  ) {
    final random = _XorShift32(_fnv1a(name));
    final bits = List<bool>.generate(32, (_) => random.next() < 0.5);
    final drawnVertical = random.next() < 0.5;
    final drawnHue = (random.next() * 180).floor() * 2.0;
    final halfDensity = List<double>.generate(
      32,
      (_) => 0.55 + random.next() * 0.45,
    );
    final vertical = switch (mirror) {
      DitherAvatarMirror.auto => drawnVertical,
      DitherAvatarMirror.vertical => true,
      DitherAvatarMirror.horizontal => false,
    };
    final on = List<bool>.filled(64, false);
    final density = List<double>.filled(64, 0);
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 8; column++) {
        final index = vertical
            ? math.min(row, 7 - row).toInt() * 8 + column
            : row * 4 + math.min(column, 7 - column).toInt();
        on[row * 8 + column] = bits[index];
        density[row * 8 + column] = halfDensity[index];
      }
    }
    return _AvatarModel(on, density, ditherHueFill(hue ?? drawnHue));
  }

  final List<bool> on;
  final List<double> density;
  final Rgb fill;
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.model, this.progress, this.bloom);

  final _AvatarModel model;
  final double progress;
  final DitherBloom bloom;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 8;
    final fill = ditherRgb(model.fill);
    if (bloom != DitherBloom.off) {
      final glow = Paint()
        ..color = fill.withValues(alpha: bloom == DitherBloom.aura ? 0.16 : 0.4)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          bloom == DitherBloom.aura ? cell * 1.6 : cell * 0.5,
        );
      canvas.drawRect(Offset.zero & size, glow);
    }
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 8; column++) {
        final index = row * 8 + column;
        if (!model.on[index]) continue;
        final start = bayerAt(column, row) * 0.7;
        final alpha = clamp01((progress - start) / 0.3);
        if (alpha == 0) continue;
        final density = model.density[index];
        final base = 0.35 + 0.65 * density;
        final square = Rect.fromLTWH(column * cell, row * cell, cell, cell);
        final paint = Paint()..color = fill.withValues(alpha: base * alpha);
        canvas.drawRect(square, paint);
        final dim = Paint()
          ..color = fill.withValues(alpha: base * 0.35 * alpha);
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            if (density > bayerAt(x, y)) continue;
            canvas.drawRect(
              Rect.fromLTWH(
                square.left + x * cell / 4,
                square.top + y * cell / 4,
                cell / 4,
                cell / 4,
              ),
              dim,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.model != model ||
      oldDelegate.progress != progress ||
      oldDelegate.bloom != bloom;
}

class DitherButton extends StatefulWidget {
  const DitherButton({
    required this.child,
    this.onPressed,
    this.color = DitherColor.blue,
    this.variant = DitherVariant.gradient,
    this.bloom = DitherBloom.off,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final DitherPixelColor color;
  final DitherVariant variant;
  final DitherBloom bloom;
  final EdgeInsetsGeometry padding;

  @override
  State<DitherButton> createState() => _DitherButtonState();
}

class _DitherButtonState extends State<DitherButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  double _target = 0;

  void _setTarget(double value) {
    setState(() => _target = value);
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _controller.value = value / 1.5;
    } else {
      _controller.animateTo(value / 1.5, curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        onEnter: enabled ? (_) => _setTarget(1) : null,
        onExit: enabled ? (_) => _setTarget(0) : null,
        child: GestureDetector(
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => _setTarget(1.5) : null,
          onTapUp: enabled ? (_) => _setTarget(_target > 0 ? 1 : 0) : null,
          onTapCancel: enabled ? () => _setTarget(0) : null,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: enabled ? 1 : 0.4,
              child: CustomPaint(
                painter: _ButtonPainter(
                  ditherFillOf(widget.color),
                  widget.variant,
                  _controller.value * 1.5,
                  widget.bloom,
                ),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonPainter extends CustomPainter {
  const _ButtonPainter(this.fill, this.variant, this.intensity, this.bloom);

  final Rgb fill;
  final DitherVariant variant;
  final double intensity;
  final DitherBloom bloom;

  @override
  void paint(Canvas canvas, Size size) {
    final backing = backingSize(size.width, size.height);
    final scaleX = size.width / backing.cols;
    final scaleY = size.height / backing.rows;
    final color = ditherRgb(fill);
    if (bloom != DitherBloom.off) {
      final glow = Paint()
        ..color = color.withValues(
          alpha: bloom == DitherBloom.aura ? 0.12 : 0.3,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          bloom == DitherBloom.aura ? 14 : 4,
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
        glow,
      );
    }
    canvas.save();
    canvas.scale(scaleX, scaleY);
    for (var y = 0; y < backing.rows; y++) {
      final density = switch (variant) {
        DitherVariant.gradient => 0.25 + 0.75 * (y + 0.5) / backing.rows,
        DitherVariant.dotted => 0.5,
        _ => 0.75,
      };
      for (var x = 0; x < backing.cols; x++) {
        if (variant == DitherVariant.hatched && ((x + y) & 3) >= 2) continue;
        final lit =
            variant == DitherVariant.solid ||
            density >
                bayerAt(x, y) -
                    0.1 * intensity -
                    (variant == DitherVariant.dotted ? 0.12 : 0);
        if (variant == DitherVariant.dotted && !lit) continue;
        final alpha = clamp01(
          (lit ? 1 : offTier) * (0.3 + density * 0.7) * (1 + 0.22 * intensity),
        );
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          Paint()..color = color.withValues(alpha: alpha),
        );
      }
    }
    final edge = Paint()
      ..color = color.withValues(alpha: clamp01(0.5 + 0.25 * intensity));
    canvas.drawRect(Rect.fromLTWH(0, 0, backing.cols.toDouble(), 1), edge);
    canvas.drawRect(
      Rect.fromLTWH(0, backing.rows - 1, backing.cols.toDouble(), 1),
      edge,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, backing.rows.toDouble()), edge);
    canvas.drawRect(
      Rect.fromLTWH(backing.cols - 1, 0, 1, backing.rows.toDouble()),
      edge,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ButtonPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.variant != variant ||
      oldDelegate.intensity != intensity ||
      oldDelegate.bloom != bloom;
}

class DitherGradient extends StatelessWidget {
  const DitherGradient({
    required this.from,
    this.to,
    this.direction = DitherGradientDirection.up,
    this.cell = 3,
    this.opacity = 1,
    this.bloom = DitherBloom.off,
    super.key,
  });

  final DitherPixelColor from;
  final DitherPixelColor? to;
  final DitherGradientDirection direction;
  final double cell;
  final double opacity;
  final DitherBloom bloom;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _GradientPainter(
        ditherFillOf(from),
        to == null ? null : ditherFillOf(to!),
        direction,
        cell,
        opacity,
        bloom,
      ),
      size: Size.infinite,
    ),
  );
}

class _GradientPainter extends CustomPainter {
  const _GradientPainter(
    this.from,
    this.to,
    this.direction,
    this.cell,
    this.opacity,
    this.bloom,
  );

  final Rgb from;
  final Rgb? to;
  final DitherGradientDirection direction;
  final double cell;
  final double opacity;
  final DitherBloom bloom;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cols = math.min(960, math.max(4, (size.width / cell).round()));
    final rows = math.min(600, math.max(4, (size.height / cell).round()));
    final scaleX = size.width / cols;
    final scaleY = size.height / rows;
    if (bloom != DitherBloom.off) {
      final glow = Paint()
        ..color = ditherRgb(
          from,
        ).withValues(alpha: bloom == DitherBloom.aura ? 0.1 : 0.25)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          bloom == DitherBloom.aura ? 16 : 5,
        );
      canvas.drawRect(Offset.zero & size, glow);
    }
    canvas.save();
    canvas.scale(scaleX, scaleY);
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final t = switch (direction) {
          DitherGradientDirection.up => 1 - (y + 0.5) / rows,
          DitherGradientDirection.down => (y + 0.5) / rows,
          DitherGradientDirection.left => 1 - (x + 0.5) / cols,
          DitherGradientDirection.right => (x + 0.5) / cols,
        };
        final density = 1 - t;
        final lit = density > bayerAt(x, y);
        final color = to == null
            ? ditherRgb(from)
            : ditherRgb(lit ? from : to!);
        final alpha = to == null
            ? (lit ? 0.35 + 0.65 * density : 0.12 * density) * opacity
            : opacity;
        if (alpha <= 0.004) continue;
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          Paint()..color = color.withValues(alpha: alpha),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.direction != direction ||
      oldDelegate.cell != cell ||
      oldDelegate.opacity != opacity ||
      oldDelegate.bloom != bloom;
}

int _fnv1a(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

class _XorShift32 {
  _XorShift32(int seed) : _state = seed == 0 ? 0x9e3779b9 : seed;

  int _state;

  double next() {
    _state ^= (_state << 13) & 0xffffffff;
    _state ^= _state >> 17;
    _state ^= (_state << 5) & 0xffffffff;
    _state &= 0xffffffff;
    return _state / 0x100000000;
  }
}
