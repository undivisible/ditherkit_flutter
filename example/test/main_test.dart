import 'package:ditherkit_flutter_example/main.dart';
import 'package:ditherkit_flutter/ditherkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
