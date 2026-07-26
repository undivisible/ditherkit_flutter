import 'package:ditherkit_flutter_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every animated dither chart', (tester) async {
    await tester.pumpWidget(const DitherKitExampleApp());

    expect(find.text('DITHER KIT'), findsOneWidget);
    expect(find.text('Weekly activity'), findsOneWidget);
    expect(find.text('Release cadence'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Live signal'), 400);
    expect(find.text('Live signal'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Polar charts'), 500);
    expect(find.text('Polar charts'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Standalone primitives'), 500);
    expect(find.text('Standalone primitives'), findsOneWidget);
  });
}
