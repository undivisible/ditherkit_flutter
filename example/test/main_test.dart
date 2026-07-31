import 'dart:io';

import 'package:ditherkit_flutter_example/main.dart';
import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web shell clears stale workers without reloading clients', () {
    final worker = File('web/flutter_service_worker.js').readAsStringSync();
    final headers = File('web/_headers').readAsStringSync();

    expect(worker, contains('self.registration.unregister()'));
    expect(worker, isNot(contains('client.navigate')));
    for (final path in [
      '/',
      '/index.html',
      '/flutter_bootstrap.js',
      '/flutter_service_worker.js',
      '/main.dart.js',
    ]) {
      expect(headers, contains('$path\n  Cache-Control: no-store'));
    }
  });

  testWidgets('renders a static dither kit grid', (tester) async {
    await tester.pumpWidget(const DitherKitExampleApp());

    expect(find.text('DITHER KIT / FLUTTER'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(DitherCartesianChart), findsNWidgets(2));
    final still =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(DitherAreaChart),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(still.reveal, 1);

    await tester.tap(find.widgetWithText(TextButton, 'REPLAY'));
    await tester.pump();
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
}
