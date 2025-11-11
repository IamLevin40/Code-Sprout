import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

/// ScrollBehavior that enables dragging with both touch and mouse (and stylus).
class TouchMouseDragScrollBehavior extends ScrollBehavior {
  const TouchMouseDragScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  // Prevent the framework from inserting a default scrollbar on desktop/web.
  // Return the child unchanged so no visible Scrollbar is shown.
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
