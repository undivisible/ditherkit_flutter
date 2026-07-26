import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
        colorScheme: const ColorScheme.dark(surface: Color(0xff0a0a0a)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          Text(
                            _scrubbedIndex == null
                                ? 'Hover a graph to scrub its crosshair. Click to lock a marker. Entrances replay only here.'
                                : 'Scrubbing data point ${_scrubbedIndex! + 1}. Click the graph to lock its marker.',
                            style: const TextStyle(
                              color: Color(0xffa1a1a1),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DitherButton(
                            color: DitherColor.purple,
                            onPressed: () => setState(() => _replayToken++),
                            child: const Text('Replay entrance'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _DemoGrid(
                children: [
                  _DemoPanel(
                    title: 'Weekly activity',
                    kind: 'AREA / GRADIENT',
                    child: DitherAreaChart(
                      values: _areaValues,
                      color: DitherColor.purple,
                      variant: DitherVariant.gradient,
                      height: 220,
                      intensity: 0.35,
                      replayToken: _replayToken,
                      onHoverChange: (index) =>
                          setState(() => _scrubbedIndex = index),
                    ),
                  ),
                  _DemoPanel(
                    title: 'Release cadence',
                    kind: 'BAR / HATCHED',
                    child: DitherBarChart(
                      values: _barValues,
                      color: DitherColor.orange,
                      variant: DitherVariant.hatched,
                      height: 220,
                      intensity: 0.2,
                      replayToken: _replayToken,
                    ),
                  ),
                  _DemoPanel(
                    title: 'Live signal',
                    kind: 'SPARKLINE / DOTTED',
                    child: DitherSparkline(
                      values: _sparkValues,
                      color: DitherColor.green,
                      variant: DitherVariant.dotted,
                      height: 220,
                      animate: true,
                      interactive: true,
                      replayToken: _replayToken,
                    ),
                  ),
                  _DemoPanel(
                    title: 'Line comparison',
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
                      height: 188,
                      labelKey: 'week',
                      showLegend: true,
                      bloom: DitherBloom.low,
                      referenceLine: const DitherReferenceLine(value: 30),
                      replayToken: _replayToken,
                    ),
                  ),
                ],
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverToBoxAdapter(child: _MiddleExplanation()),
              ),
              _DemoGrid(
                children: [
                  _DemoPanel(
                    title: 'Build mix',
                    kind: 'PIE / DONUT',
                    child: DitherPieChart(
                      height: 220,
                      innerRadius: 0.52,
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
                  _DemoPanel(
                    title: 'Team shape',
                    kind: 'RADAR / HATCHED',
                    child: DitherRadarChart(
                      height: 220,
                      nameKey: 'skill',
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
                  _DemoPanel(
                    title: 'Primitives',
                    kind: 'AVATAR / BUTTON / GRADIENT',
                    child: SizedBox(
                      height: 220,
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
                                const DitherAvatar(
                                  name: 'dither-kit',
                                  size: 76,
                                ),
                                const SizedBox(width: 18),
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
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoGrid extends StatelessWidget {
  const _DemoGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) => SliverGrid(
          delegate: SliverChildListDelegate(children),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.crossAxisExtent >= 780 ? 2 : 1,
            mainAxisExtent: 308,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
        ),
      ),
    );
  }
}

class _MiddleExplanation extends StatelessWidget {
  const _MiddleExplanation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 52),
          child: Text(
            'DitherKit is a native Flutter canvas kit for ordered-dither data views. Its motion stays inside each graph: reveal once, then scrub, focus, and lock without restarting the chart.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xffb7b7b3),
              fontSize: 18,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({
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
              const SizedBox(height: 12),
              Expanded(child: _ViewportTickerMode(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewportTickerMode extends StatefulWidget {
  const _ViewportTickerMode({required this.child});

  final Widget child;

  @override
  State<_ViewportTickerMode> createState() => _ViewportTickerModeState();
}

class _ViewportTickerModeState extends State<_ViewportTickerMode> {
  ScrollPosition? _position;
  var _visible = true;
  var _hovered = false;
  var _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.of(context).position;
    if (_position == position) return;
    _position?.removeListener(_scheduleVisibilityCheck);
    _position = position;
    _position?.addListener(_scheduleVisibilityCheck);
    _scheduleVisibilityCheck();
  }

  void _scheduleVisibilityCheck() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final next =
          top < MediaQuery.sizeOf(context).height && top + box.size.height > 0;
      if (next != _visible) setState(() => _visible = next);
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleVisibilityCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TickerMode(enabled: _visible || _hovered, child: widget.child),
    );
  }
}
