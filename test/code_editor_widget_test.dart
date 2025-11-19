import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:code_sprout/widgets/farm_items/code_editor_widget.dart';

void main() {
  testWidgets('Enter creates indented line after brace and colon', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'if (x) {');
    final widget = MaterialApp(
      home: Scaffold(
        body: CodeEditorWidget(
          initialCode: '',
          onCodeChanged: (_) {},
          onClose: () {},
          controller: controller,
        ),
      ),
    );

    await tester.pumpWidget(widget);
    // tap to focus textfield
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // place caret at end
    controller.selection = TextSelection.collapsed(offset: controller.text.length);

    // send Enter key
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(controller.text.contains('\n    '), isTrue);

    // Test colon-based indent (python style)
    controller.text = 'def foo():';
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.text.contains('\n    '), isTrue);
  });

  testWidgets('Indent and unindent buttons', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'line');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CodeEditorWidget(
          initialCode: '',
          onCodeChanged: (_) {},
          onClose: () {},
          controller: controller,
        ),
      ),
    ));

    // Tap indent button
    await tester.tap(find.byIcon(Icons.format_indent_increase));
    await tester.pumpAndSettle();
    expect(controller.text.contains('    '), isTrue);

    // Tap unindent button
    await tester.tap(find.byIcon(Icons.format_indent_decrease));
    await tester.pumpAndSettle();
    // after unindent the four spaces should be removed
    expect(controller.text.contains('    '), isFalse);
  });

  testWidgets('Multi-line unindent preserves selection offsets', (WidgetTester tester) async {
    final controller = TextEditingController(text: '    line1\n    line2\n    line3');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CodeEditorWidget(
          initialCode: '',
          onCodeChanged: (_) {},
          onClose: () {},
          controller: controller,
        ),
      ),
    ));

    // select entire block
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

    // tap unindent button
    await tester.tap(find.byIcon(Icons.format_indent_decrease));
    await tester.pumpAndSettle();

    // verify that leading spaces removed
    expect(controller.text.startsWith('line1'), isTrue);
    // selection should still cover the block (length reduced by 3*4 = 12 characters in this test)
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, controller.text.length);
  });

  testWidgets('Executing line notifier shows overlay Positioned when set', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'a\nb\nc\nd');
    final notifier = ValueNotifier<int?>(null);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CodeEditorWidget(
          initialCode: '',
          onCodeChanged: (_) {},
          onClose: () {},
          controller: controller,
          executingLineNotifier: notifier,
        ),
      ),
    ));

    // initially no Positioned overlay
    expect(find.byType(Positioned), findsNothing);

    // set executing line
    notifier.value = 2;
    await tester.pumpAndSettle();

    // overlay should appear
    expect(find.byType(Positioned), findsWidgets);
  });
}
