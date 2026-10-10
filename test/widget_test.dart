import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_26_clock/stopwatch_screen.dart';

void main() {
  testWidgets('stopwatch starts and updates its controls', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: StopwatchScreen(),
      ),
    );

    expect(find.text('00:00.00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Lap'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
  });
}
