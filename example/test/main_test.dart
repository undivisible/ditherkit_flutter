import 'package:ditherkit_flutter_example/main.dart';
import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scrolls through the dither kit grid', (tester) async {
    await tester.pumpWidget(const DitherKitExampleApp());

    expect(find.text('DITHER KIT'), findsOneWidget);
    expect(find.text('Weekly activity'), findsOneWidget);
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

    await tester.tap(find.text('Replay entrance'));
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

    await tester.scrollUntilVisible(find.text('Release cadence'), 500);
    expect(find.text('Release cadence'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Live signal'), 500);
    expect(find.text('Live signal'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Build mix'), 500);
    expect(find.text('Build mix'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Primitives'), 500);
    expect(find.text('Primitives'), findsOneWidget);
  });
}
