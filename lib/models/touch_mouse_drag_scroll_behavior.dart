import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

/// ScrollBehavior that enables dragging with both touch and mouse (and stylus).
class TouchMouseDragScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
