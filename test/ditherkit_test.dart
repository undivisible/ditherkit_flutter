import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseSparklineValues accepts comma and space separated lists', () {
    expect(parseSparklineValues('1,2,3'), [1, 2, 3]);
    expect(parseSparklineValues('1 2 3 4'), [1, 2, 3, 4]);
    expect(parseSparklineValues('[10,20,30]'), [10, 20, 30]);
  });

  test('ditherColorFromName maps aliases', () {
    expect(ditherColorFromName('green'), DitherColor.green);
    expect(ditherColorFromName('gray'), DitherColor.grey);
    expect(ditherColorFromName(null), DitherColor.blue);
  });

  test('resampleSeries interpolates length', () {
    final out = resampleSeries([0, 10], 5);
    expect(out.length, 5);
    expect(out.first, 0);
    expect(out.last, 10);
  });

  testWidgets('DitherSparkline paints without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DitherSparkline(
            values: [2, 4, 3, 8, 6, 9],
            color: DitherColor.green,
          ),
        ),
      ),
    );
    expect(find.byType(DitherSparkline), findsOneWidget);
  });

  testWidgets('DitherBarChart paints without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DitherBarChart(values: [1, 3, 2, 5, 4])),
      ),
    );
    expect(find.byType(DitherBarChart), findsOneWidget);
  });

  testWidgets('DitherAreaChart paints without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DitherAreaChart(values: [1, 3, 2, 5, 4])),
      ),
    );
    expect(find.byType(DitherAreaChart), findsOneWidget);
  });

  testWidgets('DitherBarChart runs its own staggered entrance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DitherBarChart(values: [1, 3, 2, 5, 4])),
      ),
    );
    final startingPainter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherBarChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherBarPainter;
    expect(startingPainter.reveal, lessThan(1));

    await tester.pump(const Duration(seconds: 1));
    final completePainter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherBarChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherBarPainter;
    expect(completePainter.reveal, 1);
  });

  testWidgets('DitherAreaChart disables motion when requested', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const MaterialApp(
          home: Scaffold(body: DitherAreaChart(values: [1, 3, 2, 5, 4])),
        ),
      ),
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(painter.reveal, 1);
    expect(painter.idlePhase, isNull);
  });
}
