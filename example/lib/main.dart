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
