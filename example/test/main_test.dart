import 'package:ditherkit_flutter_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scrolls through the dither kit grid', (tester) async {
    await tester.pumpWidget(const DitherKitExampleApp());

    expect(find.text('DITHER KIT'), findsOneWidget);
    expect(find.text('Weekly activity'), findsOneWidget);
    expect(find.text('Release cadence'), findsOneWidget);

    expect(find.text('Live signal'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Build mix'), 500);
    expect(find.text('Build mix'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Primitives'), 500);
    expect(find.text('Primitives'), findsOneWidget);
  });
}
