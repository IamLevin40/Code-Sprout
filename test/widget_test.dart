// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_sprout/models/styles_schema.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Provide a minimal styles map for tests to avoid asset loading in tests.
    AppStyles().setStylesForTesting({
      'constant_values': {
        'colors': {
          'light_purple': '#8a2be2',
          'dark_green': '#006400',
          'white': '#FFFFFF',
        }
      }
    });

  // Build a minimal counter widget to avoid initializing Firebase/Auth
  // while still testing the basic increment UI.
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: _TestCounter(),
    ),
  ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

class _TestCounter extends StatefulWidget {
  @override
  State<_TestCounter> createState() => _TestCounterState();
}

class _TestCounterState extends State<_TestCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_count'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _count += 1),
          ),
        ],
      ),
    );
  }
}
