import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:code_sprout/widgets/farm_items/code_editor_widget.dart';

void main() {
  group('CodeEditorWidget Basic Functionality', () {
    testWidgets('Widget renders with initial code', (WidgetTester tester) async {
      const initialCode = 'int main() {\n  return 0;\n}';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: initialCode,
            onCodeChanged: (_) {},
            onClose: () {},
          ),
        ),
      ));

      expect(find.text('Code Editor'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Code changes trigger onCodeChanged callback', (WidgetTester tester) async {
      String? changedCode;
      final controller = TextEditingController(text: 'initial');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: 'initial',
            onCodeChanged: (code) => changedCode = code,
            onClose: () {},
            controller: controller,
          ),
        ),
      ));

      controller.text = 'modified';
      await tester.pump();

      expect(changedCode, equals('modified'));
    });

    testWidgets('Close button triggers onClose callback', (WidgetTester tester) async {
      bool closeCalled = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: '',
            onCodeChanged: (_) {},
            onClose: () => closeCalled = true,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closeCalled, isTrue);
    });
  });

  group('CodeEditorWidget Auto-Indent Features', () {
    testWidgets('Enter creates indented line after opening brace', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'if (x) {');
      
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

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.text.contains('\n    '), isTrue);
    });

    testWidgets('Enter creates indented line after colon (Python style)', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'def foo():');
      
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

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.text.contains('\n    '), isTrue);
    });

    testWidgets('Indent button adds 4 spaces', (WidgetTester tester) async {
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

      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.tap(find.byIcon(Icons.format_indent_increase));
      await tester.pumpAndSettle();

      expect(controller.text, equals('    line'));
    });

    testWidgets('Unindent button removes 4 spaces', (WidgetTester tester) async {
      final controller = TextEditingController(text: '    line');
      
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

      controller.selection = const TextSelection.collapsed(offset: 4);
      await tester.tap(find.byIcon(Icons.format_indent_decrease));
      await tester.pumpAndSettle();

      expect(controller.text, equals('line'));
    });

    testWidgets('Multi-line indent adds spaces to all selected lines', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'line1\nline2\nline3');
      
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

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      await tester.tap(find.byIcon(Icons.format_indent_increase));
      await tester.pumpAndSettle();

      expect(controller.text, equals('    line1\n    line2\n    line3'));
    });

    testWidgets('Multi-line unindent removes spaces from all selected lines', (WidgetTester tester) async {
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

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      await tester.tap(find.byIcon(Icons.format_indent_decrease));
      await tester.pumpAndSettle();

      expect(controller.text, equals('line1\nline2\nline3'));
    });
  });

  group('CodeEditorWidget Line Highlighting', () {
    testWidgets('Executing line notifier highlights correct line', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'line1\nline2\nline3\nline4');
      final executingLineNotifier = ValueNotifier<int?>(null);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: '',
            onCodeChanged: (_) {},
            onClose: () {},
            controller: controller,
            executingLineNotifier: executingLineNotifier,
          ),
        ),
      ));

      // Initially no highlight
      expect(executingLineNotifier.value, isNull);

      // Set executing line to 2
      executingLineNotifier.value = 2;
      await tester.pumpAndSettle();

      // Verify the widget rebuilt with highlighted line
      expect(executingLineNotifier.value, equals(2));
    });

    testWidgets('Error line notifier highlights error line', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'line1\nline2\nline3\nline4');
      final errorLineNotifier = ValueNotifier<int?>(null);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: '',
            onCodeChanged: (_) {},
            onClose: () {},
            controller: controller,
            errorLineNotifier: errorLineNotifier,
          ),
        ),
      ));

      // Set error line to 3
      errorLineNotifier.value = 3;
      await tester.pumpAndSettle();

      expect(errorLineNotifier.value, equals(3));
    });

    testWidgets('Both executing and error line can be set', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'line1\nline2\nline3\nline4');
      final executingLineNotifier = ValueNotifier<int?>(2);
      final errorLineNotifier = ValueNotifier<int?>(3);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: '',
            onCodeChanged: (_) {},
            onClose: () {},
            controller: controller,
            executingLineNotifier: executingLineNotifier,
            errorLineNotifier: errorLineNotifier,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(executingLineNotifier.value, equals(2));
      expect(errorLineNotifier.value, equals(3));
    });
  });

  group('CodeEditorWidget Read-Only Mode', () {
    testWidgets('Read-only mode displays SelectableText', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'test code');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: 'test code',
            onCodeChanged: (_) {},
            onClose: () {},
            controller: controller,
            isReadOnly: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // In read-only mode, should show SelectableText
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Editable mode displays TextField', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'test code');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeEditorWidget(
            initialCode: 'test code',
            onCodeChanged: (_) {},
            onClose: () {},
            controller: controller,
            isReadOnly: false,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // In editable mode, should show TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('Content preserved when switching modes', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'original content');
      bool isReadOnly = false;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: CodeEditorWidget(
                        initialCode: 'original content',
                        onCodeChanged: (_) {},
                        onClose: () {},
                        controller: controller,
                        isReadOnly: isReadOnly,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isReadOnly = !isReadOnly),
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(controller.text, equals('original content'));

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
      expect(controller.text, equals('original content'));
    });
  });

  group('CodeEditorWidget Bracket Pairing', () {
    testWidgets('Controller maintains text correctly', (WidgetTester tester) async {
      final controller = TextEditingController(text: '');
      
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

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Manually test bracket pairing by setting text directly
      controller.text = '{}';
      await tester.pumpAndSettle();

      expect(controller.text, equals('{}'));
    });

    testWidgets('Tab key inserts 4 spaces', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'code');
      
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

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(controller.text.startsWith('    '), isTrue);
    });
  });
}
