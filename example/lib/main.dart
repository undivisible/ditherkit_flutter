import 'package:flutter/material.dart';
import 'package:ditherkit_flutter/ditherkit_flutter.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff8b5cf6),
          brightness: Brightness.dark,
        ),
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
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                Text(
                  'DitherKit for Flutter',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Ordered-dither charts and sparklines rendered with CustomPaint.',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 32),
                _ChartCard(
                  title: 'Weekly activity',
                  subtitle: 'DitherAreaChart',
                  child: DitherAreaChart(
                    values: [18, 32, 26, 49, 38, 64, 58, 74, 66, 92],
                    color: DitherColor.purple,
                    variant: DitherVariant.gradient,
                    height: 180,
                    intensity: 0.35,
                  ),
                ),
                SizedBox(height: 20),
                _ChartCard(
                  title: 'Release cadence',
                  subtitle: 'DitherBarChart',
                  child: DitherBarChart(
                    values: [4, 8, 5, 12, 9, 15, 11],
                    color: DitherColor.orange,
                    variant: DitherVariant.hatched,
                    height: 180,
                    intensity: 0.2,
                  ),
                ),
                SizedBox(height: 20),
                _ChartCard(
                  title: 'Live signal',
                  subtitle: 'DitherSparkline',
                  child: DitherSparkline(
                    values: [5, 8, 6, 13, 10, 18, 15, 24, 19, 30],
                    color: DitherColor.green,
                    variant: DitherVariant.dotted,
                    height: 96,
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
