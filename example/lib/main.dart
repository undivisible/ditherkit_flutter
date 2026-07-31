import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const List<double> _areaValues = [18, 32, 26, 49, 38, 64, 58, 74, 66, 92];
const List<double> _barValues = [4, 8, 5, 12, 9, 15, 11];
const List<double> _sparkValues = [5, 8, 6, 13, 10, 18, 15, 24, 19, 30];

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
        colorScheme: const ColorScheme.dark(surface: Color(0xff070707)),
        useMaterial3: true,
      ),
      home: const DitherKitExamplePage(),
    );
  }
}

class DitherKitExamplePage extends StatefulWidget {
  const DitherKitExamplePage({super.key});

  @override
  State<DitherKitExamplePage> createState() => _DitherKitExamplePageState();
}

class _DitherKitExamplePageState extends State<DitherKitExamplePage> {
  int _replayToken = 0;
  int? _scrubbedIndex;
  var _animate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => GridView.count(
          crossAxisCount: 3,
          childAspectRatio: constraints.maxWidth / constraints.maxHeight,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _DemoTile(
              label: 'Area chart',
              child: (height) => DitherAreaChart(
                values: _areaValues,
                color: DitherColor.purple,
                variant: DitherVariant.gradient,
                height: height,
                intensity: 0.35,
                animate: _animate,
                replayToken: _replayToken,
                onHoverChange: (index) =>
                    setState(() => _scrubbedIndex = index),
              ),
            ),
            _DemoTile(
              label: 'Bar chart',
              child: (height) => DitherBarChart(
                values: _barValues,
                color: DitherColor.orange,
                variant: DitherVariant.hatched,
                height: height,
                intensity: 0.2,
                animate: _animate,
                replayToken: _replayToken,
              ),
            ),
            _DemoTile(
              label: 'Sparkline',
              child: (height) => DitherSparkline(
                values: _sparkValues,
                color: DitherColor.green,
                variant: DitherVariant.dotted,
                height: height,
                animate: _animate,
                interactive: true,
                replayToken: _replayToken,
              ),
            ),
            _DemoTile(
              label: 'Pie chart',
              child: (height) => DitherPieChart(
                height: height,
                innerRadius: 0.52,
                animate: _animate,
                replayToken: _replayToken,
                data: const [
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
            ),
            _HeroTile(
              scrubbedIndex: _scrubbedIndex,
              onReplay: () => setState(() {
                _animate = true;
                _replayToken++;
              }),
            ),
            _DemoTile(
              label: 'Radar chart',
              child: (height) => DitherRadarChart(
                height: height,
                nameKey: 'skill',
                animate: _animate,
                replayToken: _replayToken,
                data: const [
                  {'skill': 'speed', 'core': 82, 'edge': 55},
                  {'skill': 'clarity', 'core': 64, 'edge': 86},
                  {'skill': 'reach', 'core': 75, 'edge': 48},
                  {'skill': 'craft', 'core': 57, 'edge': 79},
                  {'skill': 'care', 'core': 90, 'edge': 61},
                ],
                series: const [
                  DitherSeries(dataKey: 'core', color: DitherColor.blue),
                  DitherSeries(
                    dataKey: 'edge',
                    color: DitherColor.pink,
                    variant: DitherVariant.hatched,
                  ),
                ],
              ),
            ),
            _DemoTile(
              label: 'Line chart',
              child: (height) => DitherCartesianChart(
                data: const [
                  {'week': 'W1', 'desktop': 18, 'mobile': 11},
                  {'week': 'W2', 'desktop': 34, 'mobile': 22},
                  {'week': 'W3', 'desktop': 25, 'mobile': 31},
                  {'week': 'W4', 'desktop': 49, 'mobile': 28},
                  {'week': 'W5', 'desktop': 42, 'mobile': 44},
                ],
                series: const [
                  DitherSeries(dataKey: 'desktop', color: DitherColor.blue),
                  DitherSeries(
                    dataKey: 'mobile',
                    color: DitherColor.pink,
                    variant: DitherVariant.hatched,
                  ),
                ],
                kind: DitherChartKind.line,
                height: height,
                labelKey: 'week',
                showAxes: false,
                animate: _animate,
                referenceLine: const DitherReferenceLine(value: 30),
                replayToken: _replayToken,
              ),
            ),
            _DemoTile(
              label: 'Stacked chart',
              child: (height) => DitherCartesianChart(
                data: const [
                  {'week': 'W1', 'build': 18, 'ship': 10},
                  {'week': 'W2', 'build': 25, 'ship': 17},
                  {'week': 'W3', 'build': 21, 'ship': 14},
                  {'week': 'W4', 'build': 32, 'ship': 20},
                ],
                series: const [
                  DitherSeries(dataKey: 'build', color: DitherColor.green),
                  DitherSeries(dataKey: 'ship', color: DitherColor.orange),
                ],
                kind: DitherChartKind.bar,
                stackType: DitherStackType.stacked,
                height: height,
                showAxes: false,
                animate: _animate,
                replayToken: _replayToken,
              ),
            ),
            _DemoTile(
              label: 'Dither primitives',
              child: (height) => SizedBox(
                height: height,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DitherGradient(
                        from: DitherColor.purple,
                        direction: DitherGradientDirection.up,
                        opacity: 0.55,
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const DitherAvatar(name: 'dither-kit', size: 76),
                          const SizedBox(width: 18),
                          DitherButton(
                            color: DitherColor.green,
                            onPressed: () {},
                            child: const Text('SAVE'),
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
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.label, required this.child});

  final String label;
  final Widget Function(double height) child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xff070707),
          border: Border.fromBorderSide(BorderSide(color: Color(0xff252525))),
        ),
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) => child(constraints.maxHeight),
          ),
        ),
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.scrubbedIndex, required this.onReplay});

  final int? scrubbedIndex;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Color(0xffdeded8),
      fontFamily: 'JetBrains Mono',
      fontSize: 13.75,
      height: 1.25,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xff0a0a0a),
        border: Border.fromBorderSide(BorderSide(color: Color(0xff454545))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DITHER KIT / FLUTTER',
              style: const TextStyle(
                color: Color(0xfff5f5f0),
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w700,
                fontSize: 16.25,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                scrubbedIndex == null
                    ? 'An ordered-dither chart kit for Flutter, ported from Boring Software’s dither-kit. Each tile is native canvas work: static when resting, interactive when you need to inspect a value.'
                    : 'Inspecting point ${scrubbedIndex! + 1}. Click a graph to lock it; the chart stays still until you interact.',
                style: textStyle,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                _HeroLink(label: 'REPLAY', onPressed: onReplay),
                _HeroLink(
                  label: 'PUB.DEV',
                  onPressed: () =>
                      _open('https://pub.dev/packages/ditherkit_flutter'),
                ),
                _HeroLink(
                  label: 'GITHUB',
                  onPressed: () =>
                      _open('https://github.com/undivisible/ditherkit_flutter'),
                ),
                _HeroLink(
                  label: 'UNDIVISIBLE.DEV',
                  onPressed: () => _open('https://undivisible.dev'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroLink extends StatelessWidget {
  const _HeroLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xffd8d8d2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13.75,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      child: Text(label),
    );
  }
}

Future<void> _open(String value) =>
    launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
