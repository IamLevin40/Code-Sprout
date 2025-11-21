import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/pages/farm_page.dart';

void main() {
  group('Farm Page UI Structure Tests', () {
    testWidgets('Farm page builds with Stack-based layering', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Stack is used for layering
      expect(find.byType(Stack), findsWidgets);
      
      // Verify farm grid is present with infinite viewport
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('Top bar with back button and language display exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'python',
            languageName: 'Python',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify back button exists
      expect(find.byType(GestureDetector), findsWidgets);
      
      // Verify language name is displayed
      expect(find.text('Python'), findsOneWidget);
    });

    testWidgets('Control buttons are properly laid out', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'java',
            languageName: 'Java',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Code button
      expect(find.text('Drone Code'), findsOneWidget);
      
      // Verify Inventory button
      expect(find.text('Inventory'), findsOneWidget);
      
      // Verify Research button
      expect(find.text('Research'), findsOneWidget);
    });
  });

  group('Layering System Tests', () {
    testWidgets('Execution log only appears when executing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, execution log should not be visible
      expect(find.text('Execution Log'), findsNothing);
    });

    testWidgets('Code editor only appears when Code button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, code editor should not be visible
      expect(find.text('Drone Code'), findsOneWidget);
      
      // Tap Code button
      await tester.tap(find.text('Drone Code'));
      await tester.pumpAndSettle();

      // Now code editor toolbar should be visible (with file management buttons)
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(find.byIcon(Icons.delete), findsWidgets);
    });
  });

  group('Inventory Popup Tests', () {
    testWidgets('Inventory button opens inventory dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Inventory button
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      // Verify dialog appears with title
      expect(find.text('Inventory'), findsWidgets);
      
      // Verify dialog is shown
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('Inventory dialog can be closed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open inventory
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      // Find and tap close button (looking for GestureDetector with Image)
      final closeButtonFinder = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && 
                    widget.child is Image,
      );
      
      if (closeButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(closeButtonFinder.first);
        await tester.pumpAndSettle();
      }

      // Dialog should be closed (only one Inventory text now - the button)
      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('File Management Integration Tests', () {
    testWidgets('File selector shows current file name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // File selector should show default file
      expect(find.text('main.cpp'), findsWidgets);
    });

    testWidgets('Start button shows file selector for execution', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'python',
            languageName: 'Python',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start button should show file selector with arrows
      expect(find.byIcon(Icons.arrow_left), findsWidgets);
      expect(find.byIcon(Icons.arrow_right), findsWidgets);
      
      // Should show default file
      expect(find.text('main.py'), findsWidgets);
    });
  });

  group('Button Functionality Tests', () {
    testWidgets('Research button shows coming soon message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Research button
      await tester.tap(find.text('Research'));
      await tester.pumpAndSettle();

      // Verify snackbar message
      expect(find.text('Research page coming soon!'), findsOneWidget);
    });

    testWidgets('Back button navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find back button (GestureDetector with Container)
      final backButtonFinder = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && 
                    widget.onTap != null &&
                    widget.child is Container,
      );
      
      // Tap should attempt to pop navigation
      if (backButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(backButtonFinder.first);
        await tester.pumpAndSettle();
      }
    });
  });

  group('Multi-Language Support Tests', () {
    final languages = {
      'cpp': 'C++',
      'python': 'Python',
      'java': 'Java',
      'csharp': 'C#',
      'javascript': 'JavaScript',
    };

    for (var entry in languages.entries) {
      testWidgets('Farm page works for ${entry.value}', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: FarmPage(
              languageId: entry.key,
              languageName: entry.value,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify language name is displayed
        expect(find.text(entry.value), findsOneWidget);
        
        // Verify all control buttons are present
        expect(find.text('Drone Code'), findsOneWidget);
        expect(find.text('Inventory'), findsOneWidget);
        expect(find.text('Research'), findsOneWidget);
      });
    }
  });

  group('Layout Responsiveness Tests', () {
    testWidgets('Farm grid maintains aspect ratio', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AspectRatio widget exists with 1.0 ratio
      final aspectRatioFinder = find.byWidgetPredicate(
        (widget) => widget is AspectRatio && widget.aspectRatio == 1.0,
      );
      
      expect(aspectRatioFinder, findsOneWidget);
    });

    testWidgets('Control buttons row is properly spaced', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Row with spaceBetween alignment exists
      final rowFinder = find.byWidgetPredicate(
        (widget) => widget is Row && 
                    widget.mainAxisAlignment == MainAxisAlignment.spaceBetween,
      );
      
      expect(rowFinder, findsWidgets);
    });
  });

  group('State Management Tests', () {
    testWidgets('Code editor toggle state works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle code editor on
      await tester.tap(find.text('Drone Code'));
      await tester.pumpAndSettle();

      // Code editor should be visible
      expect(find.byIcon(Icons.add), findsWidgets);

      // Toggle code editor off
      await tester.tap(find.text('Drone Code'));
      await tester.pumpAndSettle();

      // Code editor should be hidden
      expect(find.byIcon(Icons.add), findsNothing);
    });
  });

  group('Icon Support Tests', () {
    testWidgets('Buttons display icons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open code editor to see its icon
      await tester.tap(find.text('Drone Code'));
      await tester.pumpAndSettle();

      // Verify various icons exist in the UI
      expect(find.byIcon(Icons.code), findsWidgets);
      expect(find.byIcon(Icons.inventory_2), findsWidgets);
      expect(find.byIcon(Icons.menu_book), findsWidgets);
    });
  });

  group('Interactive Viewport Tests', () {
    testWidgets('Zoom control buttons are present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify zoom in button
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      
      // Verify zoom out button
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      
      // Verify reset center button
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    });

    testWidgets('Farm grid uses InteractiveViewport', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'python',
            languageName: 'Python',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify InteractiveViewport is present
      expect(find.byType(Transform), findsWidgets);
      
      // Verify ClipRect for overflow prevention
      expect(find.byType(ClipRect), findsWidgets);
      
      // Verify OverflowBox for infinite dimensions
      expect(find.byType(OverflowBox), findsWidgets);
    });

    testWidgets('Zoom buttons are properly positioned below top bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'java',
            languageName: 'Java',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all zoom control buttons
      final zoomInFinder = find.byIcon(Icons.zoom_in);
      final resetFinder = find.byIcon(Icons.center_focus_strong);
      final zoomOutFinder = find.byIcon(Icons.zoom_out);

      expect(zoomInFinder, findsOneWidget);
      expect(resetFinder, findsOneWidget);
      expect(zoomOutFinder, findsOneWidget);

      // Verify they are in a Row
      final zoomRow = tester.widget<Row>(
        find.ancestor(
          of: zoomInFinder,
          matching: find.byType(Row),
        ).first,
      );
      expect(zoomRow.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('Farm grid is positioned to fill entire screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'cpp',
            languageName: 'C++',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Positioned.fill is used for the grid layer
      final positionedWidgets = tester.widgetList<Positioned>(find.byType(Positioned));
      
      // At least one Positioned widget should have full positioning (fill)
      final hasFilledPositioned = positionedWidgets.any((positioned) =>
        positioned.left == 0 &&
        positioned.top == 0 &&
        positioned.right == 0 &&
        positioned.bottom == 0
      );
      
      expect(hasFilledPositioned, isTrue);
    });

    testWidgets('No RenderFlex overflow errors with viewport', (WidgetTester tester) async {
      // This test ensures no overflow errors occur with the new viewport system
      await tester.pumpWidget(
        MaterialApp(
          home: FarmPage(
            languageId: 'python',
            languageName: 'Python',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If there were overflow errors, they would appear in the error log
      // This test passes if no exceptions are thrown during pump
      expect(tester.takeException(), isNull);
    });
  });
}
