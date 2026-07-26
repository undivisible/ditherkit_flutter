import 'package:ditherkit_flutter_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every dither chart', (tester) async {
    await tester.pumpWidget(const DitherKitExampleApp());

    expect(find.text('DitherKit for Flutter'), findsOneWidget);
    expect(find.text('DitherAreaChart'), findsOneWidget);
    expect(find.text('DitherBarChart'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('DitherSparkline'), 400);
    expect(find.text('DitherSparkline'), findsOneWidget);
  });
}
