import 'dart:ui' show PointerDeviceKind;

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

  testWidgets('simple charts scrub, lock, and replay natively', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DitherAreaChart(values: [1, 3, 2, 5, 4], replayToken: 1),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(0, 0));
    await gesture.moveTo(const Offset(220, 60));
    await tester.pump();

    final hovered =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(hovered.markerIndex, isNotNull);

    await tester.tapAt(const Offset(220, 60));
    await gesture.removePointer();
    await tester.pump();

    final locked =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(locked.markerIndex, equals(hovered.markerIndex));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DitherAreaChart(values: [1, 3, 2, 5, 4], replayToken: 2),
        ),
      ),
    );
    final replaying =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(replaying.reveal, lessThan(1));
  });

  testWidgets('hover-state rebuild inputs do not replay entrances', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DitherAreaChart(values: [1, 3, 2, 5, 4])),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DitherAreaChart(values: [1, 3, 2, 5, 4])),
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
  });

  testWidgets('area charts idle only while hovered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DitherAreaChart(values: [1, 3, 2, 5, 4])),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final resting =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(resting.idlePhase, isNull);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(0, 0));
    await gesture.moveTo(const Offset(220, 60));
    await tester.pump();
    final active =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(active.idlePhase, isNotNull);
  });

  testWidgets('TickerMode pauses an inactive dither chart', (tester) async {
    await tester.pumpWidget(
      const TickerMode(
        enabled: false,
        child: MaterialApp(
          home: Scaffold(body: DitherAreaChart(values: [1, 3, 2, 5, 4])),
        ),
      ),
    );
    final before =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    await tester.pump(const Duration(seconds: 2));
    final after =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(after.reveal, before.reveal);
    expect(after.idlePhase, before.idlePhase);
  });

  testWidgets('composable chart responds to a desktop hover', (tester) async {
    int? hovered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DitherCartesianChart(
            data: const [
              {'label': 'A', 'value': 2},
              {'label': 'B', 'value': 5},
            ],
            series: const [
              DitherSeries(dataKey: 'value', color: DitherColor.blue),
            ],
            labelKey: 'label',
            onHoverChange: (index) => hovered = index,
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(0, 0));
    await gesture.moveTo(const Offset(180, 100));
    await tester.pump();
    expect(hovered, isNotNull);
  });

  testWidgets('full chart family and standalone primitives paint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              DitherCartesianChart(
                data: [
                  {'label': 'A', 'a': 2, 'b': 4},
                  {'label': 'B', 'a': 5, 'b': 3},
                ],
                series: [
                  DitherSeries(dataKey: 'a', color: DitherColor.blue),
                  DitherSeries(dataKey: 'b', color: DitherColor.pink),
                ],
                kind: DitherChartKind.line,
              ),
              DitherPieChart(
                data: [
                  DitherPieSlice(name: 'A', value: 2, color: DitherColor.green),
                  DitherPieSlice(
                    name: 'B',
                    value: 3,
                    color: DitherColor.orange,
                  ),
                ],
              ),
              DitherRadarChart(
                nameKey: 'label',
                data: [
                  {'label': 'A', 'a': 2, 'b': 4},
                  {'label': 'B', 'a': 5, 'b': 3},
                  {'label': 'C', 'a': 3, 'b': 6},
                ],
                series: [
                  DitherSeries(dataKey: 'a', color: DitherColor.blue),
                  DitherSeries(dataKey: 'b', color: DitherColor.pink),
                ],
              ),
              DitherAvatar(name: 'test'),
              DitherButton(onPressed: null, child: Text('Disabled')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(DitherPieChart), findsOneWidget);
    expect(find.byType(DitherRadarChart), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(DitherAvatar), 200);
    expect(find.byType(DitherAvatar), findsOneWidget);
    expect(find.byType(DitherButton), findsOneWidget);
  });
}
