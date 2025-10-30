import 'package:flutter/widgets.dart';

/// Global navigator key used for showing SnackBars or navigating from
/// background tasks where the original BuildContext may no longer be valid.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
