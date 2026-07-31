import 'dart:io';

import 'package:ditherkit_flutter_example/main.dart';
import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web shell caches versioned application assets', () {
    final headers = File('web/_headers').readAsStringSync();
    final index = File('web/index.html').readAsStringSync();
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(File('web/flutter_service_worker.js').existsSync(), isFalse);
    expect(index, contains('flutter_bootstrap.js?shell=5'));
    expect(bootstrap, contains("mainWasmPath += '?shell=5'"));
    for (final path in ['/main.dart.js', '/main.dart.mjs', '/main.dart.wasm']) {
      expect(
        headers,
        contains('$path\n  Cache-Control: public, max-age=31536000, immutable'),
      );
    }
    expect(headers, isNot(contains('Cache-Control: no-store')));
  });

  testWidgets('renders a static dither kit grid', (tester) async {
    await tester.pumpWidget(const DitherKitExampleApp());

    expect(find.text('DITHER KIT / FLUTTER'), findsOneWidget);
    final hero = tester.widget<Text>(find.text('DITHER KIT / FLUTTER'));
    expect(hero.style?.fontFamily, 'JetBrains Mono');
    expect(hero.style?.fontSize, 16.25);
    expect(
      Theme.of(
        tester.element(find.byType(Scaffold)),
      ).textTheme.bodyMedium?.fontFamily,
      'JetBrains Mono',
    );
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(DitherCartesianChart), findsNWidgets(2));
    final still =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is DitherAreaPainter,
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
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is DitherAreaPainter,
                  ),
                )
                .painter
            as DitherAreaPainter;
    expect(replaying.reveal, lessThan(1));
  });
}
