import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/miscellaneous/interactive_viewport_controller.dart';

void main() {
  group('InteractiveViewportController Tests', () {
    test('Constructor initializes with default values', () {
      final controller = InteractiveViewportController();
      
      expect(controller.scale, 1.0);
      expect(controller.offset, Offset.zero);
    });

    test('Constructor respects initial values', () {
      final controller = InteractiveViewportController(
        initialScale: 1.5,
        initialOffset: const Offset(100, 200),
      );
      
      expect(controller.scale, 1.5);
      expect(controller.offset, const Offset(100, 200));
    });

    test('Constructor clamps initial scale to bounds', () {
      final controller = InteractiveViewportController(
        initialScale: 10.0,
        minScale: 0.5,
        maxScale: 3.0,
      );
      
      expect(controller.scale, 3.0); // Clamped to max
    });

    test('zoomIn increases scale by increment', () {
      final controller = InteractiveViewportController(initialScale: 1.0);
      
      controller.zoomIn(increment: 0.2);
      
      expect(controller.scale, 1.2);
    });

    test('zoomOut decreases scale by increment', () {
      final controller = InteractiveViewportController(initialScale: 1.5);
      
      controller.zoomOut(increment: 0.3);
      
      expect(controller.scale, 1.2);
    });

    test('zoomIn clamps to maxScale', () {
      final controller = InteractiveViewportController(
        initialScale: 2.9,
        maxScale: 3.0,
      );
      
      controller.zoomIn(increment: 0.5);
      
      expect(controller.scale, 3.0);
    });

    test('zoomOut clamps to minScale', () {
      final controller = InteractiveViewportController(
        initialScale: 0.6,
        minScale: 0.5,
      );
      
      controller.zoomOut(increment: 0.3);
      
      expect(controller.scale, 0.5);
    });

    test('setScale updates scale and clamps to bounds', () {
      final controller = InteractiveViewportController(
        minScale: 0.5,
        maxScale: 3.0,
      );
      
      controller.setScale(2.5);
      expect(controller.scale, 2.5);
      
      controller.setScale(5.0); // Above max
      expect(controller.scale, 3.0);
      
      controller.setScale(0.1); // Below min
      expect(controller.scale, 0.5);
    });

    test('resetToCenter resets offset to zero', () {
      final controller = InteractiveViewportController(
        initialOffset: const Offset(100, 200),
      );
      
      controller.resetToCenter();
      
      expect(controller.offset, Offset.zero);
    });

    test('resetToCenter can reset scale optionally', () {
      final controller = InteractiveViewportController(
        initialScale: 2.0,
        initialOffset: const Offset(100, 200),
      );
      
      controller.resetToCenter(resetScale: 1.0);
      
      expect(controller.offset, Offset.zero);
      expect(controller.scale, 1.0);
    });

    test('resetToCenter centers on grid when gridSize and plotSize provided', () {
      final controller = InteractiveViewportController();
      
      // 3x3 grid with 100x100 plots
      final gridSize = const Size(3, 3);
      final plotSize = const Size(100, 100);
      
      controller.resetToCenter(gridSize: gridSize, plotSize: plotSize);
      
      // Center of 3x3 grid with 100x100 plots is at (150, 150)
      // Offset should be negative to move grid center to viewport origin
      expect(controller.offset.dx, -150.0);
      expect(controller.offset.dy, -150.0);
    });

    test('resetToCenter centers on 4x4 grid correctly', () {
      final controller = InteractiveViewportController();
      
      // 4x4 grid with 80x80 plots
      final gridSize = const Size(4, 4);
      final plotSize = const Size(80, 80);
      
      controller.resetToCenter(gridSize: gridSize, plotSize: plotSize);
      
      // Center of 4x4 grid with 80x80 plots is at (160, 160)
      expect(controller.offset.dx, -160.0);
      expect(controller.offset.dy, -160.0);
    });

    test('updateOffset adds delta to current offset', () {
      final controller = InteractiveViewportController(
        initialOffset: const Offset(50, 75),
      );
      
      controller.updateOffset(const Offset(25, 35));
      
      expect(controller.offset, const Offset(75, 110));
    });

    test('updateOffset supports negative delta for drag/pan', () {
      final controller = InteractiveViewportController(
        initialOffset: const Offset(100, 150),
      );
      
      // Simulate dragging right (moves content left, negative offset change)
      controller.updateOffset(const Offset(-30, -40));
      
      expect(controller.offset, const Offset(70, 110));
    });

    test('setOffset directly sets offset', () {
      final controller = InteractiveViewportController();
      
      controller.setOffset(const Offset(123, 456));
      
      expect(controller.offset, const Offset(123, 456));
    });

    test('multiple updateOffset calls accumulate correctly', () {
      final controller = InteractiveViewportController();
      
      controller.updateOffset(const Offset(10, 20));
      controller.updateOffset(const Offset(15, 25));
      controller.updateOffset(const Offset(-5, -10));
      
      expect(controller.offset, const Offset(20, 35));
    });

    test('handleScroll zooms in with negative scroll delta', () {
      final controller = InteractiveViewportController(initialScale: 1.0);
      final event = PointerScrollEvent(
        scrollDelta: const Offset(0, -100), // Scroll up (zoom in)
      );
      final viewportSize = const Size(800, 600);
      
      controller.handleScroll(event, const Offset(400, 300), viewportSize);
      
      expect(controller.scale, greaterThan(1.0));
    });

    test('handleScroll zooms out with positive scroll delta', () {
      final controller = InteractiveViewportController(initialScale: 1.5);
      final event = PointerScrollEvent(
        scrollDelta: const Offset(0, 100), // Scroll down (zoom out)
      );
      final viewportSize = const Size(800, 600);
      
      controller.handleScroll(event, const Offset(400, 300), viewportSize);
      
      expect(controller.scale, lessThan(1.5));
    });

    test('handleScroll maintains focal point position during zoom', () {
      final controller = InteractiveViewportController(
        initialScale: 1.0,
        initialOffset: Offset.zero,
      );
      final focalPoint = const Offset(500, 350);
      final viewportSize = const Size(800, 600);
      final event = PointerScrollEvent(
        scrollDelta: const Offset(0, -100), // Zoom in
      );
      
      // Calculate content point at focal point before zoom
      final viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);
      final focalRelativeToCenter = focalPoint - viewportCenter;
      final contentPointBefore = (focalRelativeToCenter - controller.offset) / controller.scale;
      
      controller.handleScroll(event, focalPoint, viewportSize);
      
      // Calculate content point at focal point after zoom
      final contentPointAfter = (focalRelativeToCenter - controller.offset) / controller.scale;
      
      // Content point should remain approximately the same (within floating point error)
      expect((contentPointBefore - contentPointAfter).distance, lessThan(1.0));
    });

    test('handleScaleUpdate updates scale and offset for pinch gesture', () {
      final controller = InteractiveViewportController(
        initialScale: 1.0,
        initialOffset: Offset.zero,
      );
      final details = ScaleUpdateDetails(
        scale: 1.5,
        focalPoint: const Offset(200, 150),
        localFocalPoint: const Offset(200, 150),
      );
      
      controller.handleScaleUpdate(details, Offset.zero, 1.0);
      
      expect(controller.scale, 1.5);
    });

    test('handleScaleUpdate clamps scale to bounds', () {
      final controller = InteractiveViewportController(
        initialScale: 1.0,
        minScale: 0.5,
        maxScale: 2.0,
      );
      final details = ScaleUpdateDetails(
        scale: 5.0, // Way above max
        focalPoint: const Offset(200, 150),
        localFocalPoint: const Offset(200, 150),
      );
      
      controller.handleScaleUpdate(details, Offset.zero, 1.0);
      
      expect(controller.scale, 2.0);
    });

    test('getTransformMatrix returns identity matrix at default state', () {
      final controller = InteractiveViewportController();
      final matrix = controller.getTransformMatrix();
      
      expect(matrix, equals(Matrix4.identity()));
    });

    test('getTransformMatrix includes translation for non-zero offset', () {
      final controller = InteractiveViewportController(
        initialOffset: const Offset(100, 200),
      );
      final matrix = controller.getTransformMatrix();
      
      // Check translation components
      expect(matrix.getTranslation().x, 100.0);
      expect(matrix.getTranslation().y, 200.0);
    });

    test('getTransformMatrix includes scaling for non-default scale', () {
      final controller = InteractiveViewportController(initialScale: 2.0);
      final matrix = controller.getTransformMatrix();
      
      // Verify scaling is applied (Z-axis is also scaled)
      final expectedMatrix = Matrix4.identity()
        ..translate(0.0, 0.0)
        ..scale(2.0, 2.0, 2.0);
      
      expect(matrix.storage, expectedMatrix.storage);
    });

    test('controller notifies listeners on scale change', () {
      final controller = InteractiveViewportController();
      var notificationCount = 0;
      
      controller.addListener(() {
        notificationCount++;
      });
      
      controller.zoomIn();
      controller.zoomOut();
      controller.setScale(1.5);
      
      expect(notificationCount, 3);
    });

    test('controller notifies listeners on offset change', () {
      final controller = InteractiveViewportController();
      var notificationCount = 0;
      
      controller.addListener(() {
        notificationCount++;
      });
      
      controller.updateOffset(const Offset(10, 10));
      controller.setOffset(const Offset(50, 50));
      controller.resetToCenter();
      
      expect(notificationCount, 3);
    });

    test('controller disposes without errors', () {
      final controller = InteractiveViewportController();
      
      expect(() => controller.dispose(), returnsNormally);
    });

    test('controller respects min/max offset bounds when provided', () {
      final controller = InteractiveViewportController(
        minOffset: const Offset(-100, -100),
        maxOffset: const Offset(100, 100),
      );
      
      controller.setOffset(const Offset(200, 200)); // Beyond max
      expect(controller.offset.dx, lessThanOrEqualTo(100));
      expect(controller.offset.dy, lessThanOrEqualTo(100));
      
      controller.setOffset(const Offset(-200, -200)); // Beyond min
      expect(controller.offset.dx, greaterThanOrEqualTo(-100));
      expect(controller.offset.dy, greaterThanOrEqualTo(-100));
    });
  });

  group('InteractiveViewport Widget Tests', () {
    testWidgets('InteractiveViewport renders child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Multiple containers exist (scaffold + our blue container)
      expect(find.byType(Container), findsWidgets);
      
      // Verify our blue container specifically
      final blueContainer = tester.widget<Container>(
        find.byWidgetPredicate((widget) => 
          widget is Container && 
          widget.color == Colors.blue
        ),
      );
      expect(blueContainer.constraints, const BoxConstraints.tightFor(width: 100, height: 100));
    });

    testWidgets('InteractiveViewport creates controller when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveViewport), findsOneWidget);
    });

    testWidgets('InteractiveViewport uses provided controller', (WidgetTester tester) async {
      final controller = InteractiveViewportController(initialScale: 2.0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              controller: controller,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveViewport), findsOneWidget);
      expect(controller.scale, 2.0);
    });

    testWidgets('InteractiveViewport responds to mouse scroll events', (WidgetTester tester) async {
      final controller = InteractiveViewportController(initialScale: 1.0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              controller: controller,
              enableMouseScrollZoom: true,
              child: Container(
                width: 400,
                height: 400,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final initialScale = controller.scale;
      
      // Simulate scroll event
      final scrollEvent = PointerScrollEvent(
        position: const Offset(200, 200),
        scrollDelta: const Offset(0, -100), // Scroll up (zoom in)
      );
      
      await tester.sendEventToBinding(scrollEvent);
      await tester.pump();

      expect(controller.scale, greaterThan(initialScale));
    });

    testWidgets('InteractiveViewport handles scale gestures', (WidgetTester tester) async {
      final controller = InteractiveViewportController(initialScale: 1.0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              controller: controller,
              enablePinchZoom: true,
              child: Container(
                width: 400,
                height: 400,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Pinch gesture (scale) is complex to test with tester
      // Verify the widget builds correctly
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('InteractiveViewport contains ClipRect for overflow prevention', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ClipRect), findsOneWidget);
    });

    testWidgets('InteractiveViewport contains OverflowBox for infinite dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(OverflowBox), findsOneWidget);
    });

    testWidgets('InteractiveViewport applies transform from controller', (WidgetTester tester) async {
      final controller = InteractiveViewportController(
        initialScale: 2.0,
        initialOffset: const Offset(50, 50),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              controller: controller,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Transform widgets are used (multiple in widget tree)
      expect(find.byType(Transform), findsWidgets);
      
      // Verify controller state is applied
      expect(controller.scale, 2.0);
      expect(controller.offset, const Offset(50, 50));
    });

    testWidgets('InteractiveViewport can disable mouse scroll zoom', (WidgetTester tester) async {
      final controller = InteractiveViewportController(initialScale: 1.0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveViewport(
              controller: controller,
              enableMouseScrollZoom: false, // Disabled
              child: Container(
                width: 400,
                height: 400,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final initialScale = controller.scale;
      
      // Simulate scroll event
      final scrollEvent = PointerScrollEvent(
        position: const Offset(200, 200),
        scrollDelta: const Offset(0, -100),
      );
      
      await tester.sendEventToBinding(scrollEvent);
      await tester.pump();

      // Scale should not change when disabled
      expect(controller.scale, initialScale);
    });
  });

  group('Integration Tests', () {
    test('Multiple zoom operations work correctly', () {
      final controller = InteractiveViewportController(initialScale: 1.0);
      
      controller.zoomIn(increment: 0.5); // 1.5
      controller.zoomIn(increment: 0.5); // 2.0
      controller.zoomOut(increment: 0.3); // 1.7
      
      expect(controller.scale, closeTo(1.7, 0.01));
    });

    test('Zoom and pan operations work together', () {
      final controller = InteractiveViewportController(
        initialScale: 1.0,
        initialOffset: Offset.zero,
      );
      
      controller.zoomIn(increment: 0.5);
      controller.updateOffset(const Offset(100, 100));
      controller.zoomOut(increment: 0.2);
      controller.updateOffset(const Offset(50, 50));
      
      expect(controller.scale, 1.3);
      expect(controller.offset, const Offset(150, 150));
    });

    test('Reset after multiple operations returns to center', () {
      final controller = InteractiveViewportController(
        initialScale: 1.0,
        initialOffset: Offset.zero,
      );
      
      controller.zoomIn(increment: 1.0);
      controller.updateOffset(const Offset(200, 300));
      controller.setScale(2.5);
      controller.setOffset(const Offset(400, 500));
      
      controller.resetToCenter(resetScale: 1.0);
      
      expect(controller.scale, 1.0);
      expect(controller.offset, Offset.zero);
    });

    test('Reset to grid center after panning and zooming', () {
      final controller = InteractiveViewportController();
      
      // Simulate user panning and zooming around
      controller.updateOffset(const Offset(150, 200));
      controller.setScale(2.0);
      controller.updateOffset(const Offset(-50, 75));
      
      // Reset to 3x3 grid center
      controller.resetToCenter(
        gridSize: const Size(3, 3),
        plotSize: const Size(100, 100),
        resetScale: 1.0,
      );
      
      expect(controller.scale, 1.0);
      expect(controller.offset, const Offset(-150, -150));
    });

    test('Continuous zoom operations respect bounds', () {
      final controller = InteractiveViewportController(
        initialScale: 1.0,
        minScale: 0.5,
        maxScale: 3.0,
      );
      
      // Zoom in way past max
      for (int i = 0; i < 20; i++) {
        controller.zoomIn(increment: 0.5);
      }
      
      expect(controller.scale, 3.0);
      
      // Zoom out way past min
      for (int i = 0; i < 30; i++) {
        controller.zoomOut(increment: 0.5);
      }
      
      expect(controller.scale, 0.5);
    });

    test('Drag simulation with multiple small pan updates', () {
      final controller = InteractiveViewportController();
      
      // Simulate a drag gesture with small incremental updates
      for (int i = 0; i < 10; i++) {
        controller.updateOffset(const Offset(5, 3));
      }
      
      expect(controller.offset, const Offset(50, 30));
    });

    test('Zoom towards different focal points produces different offsets', () {
      final viewportSize = const Size(800, 600);
      
      // Controller 1: Zoom towards top-left
      final controller1 = InteractiveViewportController();
      final event1 = PointerScrollEvent(scrollDelta: const Offset(0, -100));
      controller1.handleScroll(event1, const Offset(100, 100), viewportSize);
      
      // Controller 2: Zoom towards bottom-right
      final controller2 = InteractiveViewportController();
      final event2 = PointerScrollEvent(scrollDelta: const Offset(0, -100));
      controller2.handleScroll(event2, const Offset(700, 500), viewportSize);
      
      // Both should have same scale
      expect(controller1.scale, controller2.scale);
      
      // But different offsets due to different focal points
      expect(controller1.offset, isNot(equals(controller2.offset)));
    });

    test('Pan then zoom maintains relative position', () {
      final controller = InteractiveViewportController();
      final viewportSize = const Size(800, 600);
      
      // Pan first
      controller.updateOffset(const Offset(100, 50));
      final offsetAfterPan = controller.offset;
      
      // Zoom at center
      final centerPoint = Offset(viewportSize.width / 2, viewportSize.height / 2);
      final zoomEvent = PointerScrollEvent(scrollDelta: const Offset(0, -100));
      controller.handleScroll(zoomEvent, centerPoint, viewportSize);
      
      // Offset should change due to zoom, but pan effect should still be present
      expect(controller.offset, isNot(equals(offsetAfterPan)));
      expect(controller.scale, greaterThan(1.0));
    });

    test('Multiple resets to different grid sizes work correctly', () {
      final controller = InteractiveViewportController();
      
      // Reset to 3x3 grid
      controller.resetToCenter(
        gridSize: const Size(3, 3),
        plotSize: const Size(100, 100),
      );
      expect(controller.offset, const Offset(-150, -150));
      
      // Pan away
      controller.updateOffset(const Offset(200, 200));
      expect(controller.offset, const Offset(50, 50));
      
      // Reset to 5x5 grid
      controller.resetToCenter(
        gridSize: const Size(5, 5),
        plotSize: const Size(80, 80),
      );
      expect(controller.offset, const Offset(-200, -200));
    });
  });
}
