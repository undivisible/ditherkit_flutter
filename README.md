# ditherkit_flutter

Ordered-dither charts, painting primitives, palettes, and sparklines for Flutter.

```yaml
dependencies:
  ditherkit_flutter: ^0.1.0
```

```dart
import 'package:ditherkit_flutter/ditherkit_flutter.dart';
```

The dither paint implementation is ported from [Boring-Software-Inc/dither-kit](https://github.com/Boring-Software-Inc/dither-kit).

Try the Flutter web example at [ditherkit-flutter.undivisible.dev](https://ditherkit-flutter.undivisible.dev). It renders `DitherAreaChart`, `DitherBarChart`, and `DitherSparkline` directly from this package.

```dart
DitherAreaChart(
  values: [18, 32, 26, 49, 38, 64],
  color: DitherColor.purple,
  variant: DitherVariant.gradient,
  height: 180,
)
```

The complete Flutter example is in [`example/`](example/).
