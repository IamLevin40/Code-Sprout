import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/styles_schema.dart';

/// Enum for notification type
enum NotificationType {
  success,
  error,
}

/// Enum for notification display position
enum NotificationPosition {
  topToBottom,
  bottomToTop,
}

/// Single notification item data
class NotificationItem {
  final String id;
  final String message;
  final NotificationType type;
  final Duration duration;

  NotificationItem({
    required this.message,
    required this.type,
    Duration? duration,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       duration = duration ?? const Duration(seconds: 5);
}

/// Controller to manage notifications
class NotificationController extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  final Set<String> _pendingRemovals = {};
  
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  
  /// Show a success notification
  void showSuccess(String message, {Duration? duration}) {
    final notification = NotificationItem(
      message: message,
      type: NotificationType.success,
      duration: duration,
    );
    // Ensure we keep at most 3 visible notifications (excluding pending removals)
    while (_notifications.where((n) => !_pendingRemovals.contains(n.id)).length >= 3) {
      final oldest = _notifications.firstWhere((n) => !_pendingRemovals.contains(n.id));
      requestRemove(oldest.id);
    }

    _notifications.add(notification);
    notifyListeners();

    // Auto-remove after duration (start exit animation)
    Future.delayed(notification.duration, () {
      requestRemove(notification.id);
    });
  }
  
  /// Show an error notification
  void showError(String message, {Duration? duration}) {
    final notification = NotificationItem(
      message: message,
      type: NotificationType.error,
      duration: duration,
    );
    while (_notifications.where((n) => !_pendingRemovals.contains(n.id)).length >= 3) {
      final oldest = _notifications.firstWhere((n) => !_pendingRemovals.contains(n.id));
      requestRemove(oldest.id);
    }

    _notifications.add(notification);
    notifyListeners();

    // Auto-remove after duration (start exit animation)
    Future.delayed(notification.duration, () {
      requestRemove(notification.id);
    });
  }
  
  /// Request removal of a notification by ID
  void requestRemove(String id) {
    if (_pendingRemovals.add(id)) {
      notifyListeners();
    }
  }

  void remove(String id) => requestRemove(id);

  /// Finalize removal after exit animation completes.
  void finalizeRemove(String id) {
    _pendingRemovals.remove(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Check if a notification is pending removal
  bool isPendingRemoval(String id) => _pendingRemovals.contains(id);
  
  /// Clear all notifications
  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}

/// Notification display widget that shows stacked notifications
class NotificationDisplay extends StatelessWidget {
  final NotificationController controller;
  final NotificationPosition position;
  
  const NotificationDisplay({
    super.key,
    required this.controller,
    this.position = NotificationPosition.topToBottom,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final notifications = controller.notifications;
        
        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // For bottom-to-top, reverse the list so newest appears at bottom
        final displayList = position == NotificationPosition.bottomToTop
            ? notifications.reversed.toList()
            : notifications;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: displayList.map((notification) {
            return _NotificationCard(
              key: ValueKey(notification.id),
              controller: controller,
              notification: notification,
              onDismiss: () => controller.requestRemove(notification.id),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Single notification card with animation and progress bar
class _NotificationCard extends StatefulWidget {
  final NotificationController controller;
  final NotificationItem notification;
  final VoidCallback onDismiss;

  const _NotificationCard({
    super.key,
    required this.controller,
    required this.notification,
    required this.onDismiss,
  });
  
  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    final styles = AppStyles();
    final fadeMs = styles.getStyles('notification_display.fade_duration') as int;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: fadeMs),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();

    // Listen to controller for pending removal requests
    widget.controller.addListener(_onControllerChanged);

    // When animation reverses to dismissed, finalize removal
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.controller.finalizeRemove(widget.notification.id);
      }
    });
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // If this notification was requested to be removed, start exit animation
    if (widget.controller.isPendingRemoval(widget.notification.id)) {
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (_animationController.status == AnimationStatus.forward) {
        // If still animating in, schedule reverse when completed
        _animationController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _animationController.reverse();
          }
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    final spacing = styles.getStyles('notification_display.spacing') as double;
    final height = styles.getStyles('notification_display.notification.height') as double;
    final borderRadius = styles.getStyles('notification_display.notification.border_radius') as double;
    final paddingHorizontal = styles.getStyles('notification_display.notification.padding_horizontal') as double;
    
    final bgGradient = widget.notification.type == NotificationType.success
        ? styles.getStyles('notification_display.notification.success.background_color') as LinearGradient
        : styles.getStyles('notification_display.notification.error.background_color') as LinearGradient;
    
    final messageColor = widget.notification.type == NotificationType.success
        ? styles.getStyles('notification_display.notification.success.message_color') as Color
        : styles.getStyles('notification_display.notification.error.message_color') as Color;
    
    final messageFontSize = styles.getStyles('notification_display.notification.message.font_size') as double;
    final messageFontWeight = styles.getStyles('notification_display.notification.message.font_weight') as FontWeight;
    
    final progressColor = widget.notification.type == NotificationType.success
        ? styles.getStyles('notification_display.notification.success.progress_color') as Color
        : styles.getStyles('notification_display.notification.error.progress_color') as Color;
    
    final progressHeight = styles.getStyles('notification_display.notification.progress_height') as double;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: bgGradient,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Column(
                children: [
                  // Message content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.notification.message,
                          style: TextStyle(
                            color: messageColor,
                            fontSize: messageFontSize,
                            fontWeight: messageFontWeight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  // Progress bar at the bottom
                  _ProgressBar(
                    duration: widget.notification.duration,
                    color: progressColor,
                    height: progressHeight,
                    borderRadius: borderRadius,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress bar widget that animates from full to empty
class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  final double height;
  final double borderRadius;
  
  const _ProgressBar({
    required this.duration,
    required this.color,
    required this.height,
    required this.borderRadius,
  });
  
  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = constraints.maxWidth;
            double targetW = maxW - 2 * widget.borderRadius;
            if (targetW <= 0) targetW = maxW;

            return Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: SizedBox(
                  width: targetW,
                  child: LinearProgressIndicator(
                    value: 1.0 - _controller.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    minHeight: widget.height,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
