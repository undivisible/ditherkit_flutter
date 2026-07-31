# ditherkit_flutter

Ordered-dither charts, polar charts, painting primitives, palettes, and sparklines for Flutter.

```yaml
dependencies:
  ditherkit_flutter: ^0.1.2
```

```dart
import 'package:ditherkit_flutter/ditherkit_flutter.dart';
```

The dither paint implementation is ported from [Boring-Software-Inc/dither-kit](https://github.com/Boring-Software-Inc/dither-kit).

Try the Flutter web example at [ditherkit-flutter.undivisible.dev](https://ditherkit-flutter.undivisible.dev). It renders `DitherAreaChart`, `DitherBarChart`, `DitherSparkline`, interactive cartesian line charts, pie/donut charts, radar charts, avatars, buttons, and gradients directly from this package.

```dart
DitherAreaChart(
  values: [18, 32, 26, 49, 38, 64],
  color: DitherColor.purple,
  variant: DitherVariant.gradient,
  height: 180,
)
```

```dart
DitherCartesianChart(
  data: [
    {'week': 'W1', 'desktop': 18, 'mobile': 11},
    {'week': 'W2', 'desktop': 34, 'mobile': 22},
  ],
  series: const [
    DitherSeries(dataKey: 'desktop', color: DitherColor.blue),
    DitherSeries(dataKey: 'mobile', color: DitherColor.pink),
  ],
  kind: DitherChartKind.line,
  labelKey: 'week',
  showLegend: true,
)
```

The complete Flutter example is in [`example/`](example/).
