import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DitherKitExampleApp());
}

class DitherKitExampleApp extends StatelessWidget {
  const DitherKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DitherKit for Flutter',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(surface: Color(0xff0a0a0a)),
        useMaterial3: true,
      ),
      home: const DitherKitExamplePage(),
    );
  }
}

class DitherKitExamplePage extends StatelessWidget {
  const DitherKitExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 48),
              children: [
                const Text(
                  'DITHER KIT',
                  style: TextStyle(
                    color: Color(0xfff5f5f0),
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dithered charts\nfor Flutter.',
                  style: TextStyle(
                    color: Color(0xfff5f5f0),
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    height: 0.95,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pixel-built CustomPaint charts with an entrance sweep and quiet idle sparkles.',
                  style: TextStyle(color: Color(0xffa1a1a1), fontSize: 16),
                ),
                const SizedBox(height: 40),
                _DitherPanel(
                  title: 'Weekly activity',
                  kind: 'AREA / GRADIENT',
                  child: const DitherAreaChart(
                    values: [18, 32, 26, 49, 38, 64, 58, 74, 66, 92],
                    color: DitherColor.purple,
                    variant: DitherVariant.gradient,
                    height: 220,
                    intensity: 0.35,
                  ),
                ),
                const SizedBox(height: 16),
                _DitherPanel(
                  title: 'Release cadence',
                  kind: 'BAR / HATCHED',
                  child: const DitherBarChart(
                    values: [4, 8, 5, 12, 9, 15, 11],
                    color: DitherColor.orange,
                    variant: DitherVariant.hatched,
                    height: 180,
                    intensity: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                _DitherPanel(
                  title: 'Live signal',
                  kind: 'SPARKLINE / DOTTED',
                  child: const DitherSparkline(
                    values: [5, 8, 6, 13, 10, 18, 15, 24, 19, 30],
                    color: DitherColor.green,
                    variant: DitherVariant.dotted,
                    height: 120,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 16),
                _DitherPanel(
                  title: 'Composable charts',
                  kind: 'LINE / TOOLTIP / LEGEND',
                  child: DitherCartesianChart(
                    data: const [
                      {'week': 'W1', 'desktop': 18, 'mobile': 11},
                      {'week': 'W2', 'desktop': 34, 'mobile': 22},
                      {'week': 'W3', 'desktop': 25, 'mobile': 31},
                      {'week': 'W4', 'desktop': 49, 'mobile': 28},
                      {'week': 'W5', 'desktop': 42, 'mobile': 44},
                    ],
                    series: const [
                      DitherSeries(
                        dataKey: 'desktop',
                        color: DitherColor.blue,
                        isClickable: true,
                      ),
                      DitherSeries(
                        dataKey: 'mobile',
                        color: DitherColor.pink,
                        variant: DitherVariant.hatched,
                        isClickable: true,
                      ),
                    ],
                    kind: DitherChartKind.line,
                    labelKey: 'week',
                    showLegend: true,
                    bloom: DitherBloom.low,
                    referenceLine: const DitherReferenceLine(value: 30),
                  ),
                ),
                const SizedBox(height: 16),
                _DitherPanel(
                  title: 'Polar charts',
                  kind: 'PIE / RADAR',
                  child: Column(
                    children: const [
                      DitherPieChart(
                        height: 240,
                        innerRadius: 0.52,
                        data: [
                          DitherPieSlice(
                            name: 'build',
                            value: 42,
                            color: DitherColor.purple,
                          ),
                          DitherPieSlice(
                            name: 'test',
                            value: 29,
                            color: DitherColor.green,
                            variant: DitherVariant.dotted,
                          ),
                          DitherPieSlice(
                            name: 'ship',
                            value: 18,
                            color: DitherColor.orange,
                            variant: DitherVariant.hatched,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      DitherRadarChart(
                        height: 280,
                        nameKey: 'skill',
                        data: [
                          {'skill': 'speed', 'core': 82, 'edge': 55},
                          {'skill': 'clarity', 'core': 64, 'edge': 86},
                          {'skill': 'reach', 'core': 75, 'edge': 48},
                          {'skill': 'craft', 'core': 57, 'edge': 79},
                          {'skill': 'care', 'core': 90, 'edge': 61},
                        ],
                        series: [
                          DitherSeries(
                            dataKey: 'core',
                            color: DitherColor.blue,
                          ),
                          DitherSeries(
                            dataKey: 'edge',
                            color: DitherColor.pink,
                            variant: DitherVariant.hatched,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DitherPanel(
                  title: 'Standalone primitives',
                  kind: 'AVATAR / BUTTON / GRADIENT',
                  child: SizedBox(
                    height: 132,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: DitherGradient(
                            from: DitherColor.purple,
                            direction: DitherGradientDirection.up,
                            opacity: 0.55,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const DitherAvatar(name: 'dither-kit', size: 72),
                              const SizedBox(width: 16),
                              DitherButton(
                                color: DitherColor.green,
                                onPressed: () {},
                                child: const Text('Save changes'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DitherPanel extends StatelessWidget {
  const _DitherPanel({
    required this.title,
    required this.kind,
    required this.child,
  });

  final String title;
  final String kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title $kind chart',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xff070707),
          border: Border.fromBorderSide(BorderSide(color: Color(0xff282828))),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xffededeb),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    kind,
                    style: const TextStyle(
                      color: Color(0xff8b8b8b),
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
