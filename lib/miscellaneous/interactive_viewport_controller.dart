import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Controller for managing interactive viewport with zoom and pan capabilities
/// Similar to game camera controls - supports mouse scroll zoom, touch pinch, and drag pan
class InteractiveViewportController extends ChangeNotifier {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  
  // Zoom constraints
  final double minScale;
  final double maxScale;
  final double scrollZoomSpeed;
  
  // Pan constraints (optional bounds)
  final Offset? minOffset;
  final Offset? maxOffset;
  
  InteractiveViewportController({
    double initialScale = 1.0,
    Offset initialOffset = Offset.zero,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.scrollZoomSpeed = 0.1,
    this.minOffset,
    this.maxOffset,
  })  : _scale = initialScale.clamp(minScale, maxScale),
        _offset = initialOffset;
  
  double get scale => _scale;
  Offset get offset => _offset;
  
  /// Zoom in by fixed increment
  void zoomIn({double increment = 0.2}) {
    setScale(_scale + increment);
  }
  
  /// Zoom out by fixed increment
  void zoomOut({double increment = 0.2}) {
    setScale(_scale - increment);
  }
  
  /// Set scale to specific value
  void setScale(double newScale) {
    final clampedScale = newScale.clamp(minScale, maxScale);
    if (_scale != clampedScale) {
      _scale = clampedScale;
      notifyListeners();
    }
  }
  
  /// Reset to center position and default scale
  /// If gridSize is provided, centers on the grid; otherwise centers on origin
  void resetToCenter({
    double? resetScale,
    Size? gridSize,
    Size? plotSize,
  }) {
    final double targetScale = (resetScale ?? 1.0).clamp(minScale, maxScale);

    if (gridSize != null && plotSize != null) {
      final double gridCenterY = (gridSize.height * plotSize.height) / 2;
      _offset = Offset(0, gridCenterY * targetScale);
    } else {
      _offset = Offset.zero;
    }

    _scale = targetScale;
    notifyListeners();
  }
  
  /// Update offset (pan)
  void updateOffset(Offset delta) {
    _offset = _constrainOffset(_offset + delta);
    notifyListeners();
  }
  
  /// Set offset directly
  void setOffset(Offset newOffset) {
    _offset = _constrainOffset(newOffset);
    notifyListeners();
  }
  
  /// Handle mouse scroll for zoom
  void handleScroll(PointerScrollEvent event, Offset focalPoint, Size viewportSize) {
    // Calculate zoom delta based on scroll direction
    final double zoomDelta = event.scrollDelta.dy > 0 ? -scrollZoomSpeed : scrollZoomSpeed;
    final double newScale = (_scale + zoomDelta).clamp(minScale, maxScale);
    
    if (newScale != _scale) {
      // Calculate the focal point relative to viewport center
      final Offset viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);
      final Offset focalRelativeToCenter = focalPoint - viewportCenter;
      
      // Content point that should stay fixed at focal point
      final Offset contentPoint = (focalRelativeToCenter - _offset) / _scale;
      
      // Update scale
      _scale = newScale;
      
      // Adjust offset so content point stays at focal point
      _offset = focalRelativeToCenter - contentPoint * _scale;
      _offset = _constrainOffset(_offset);
      notifyListeners();
    }
  }
  
  /// Handle pinch/scale gestures
  void handleScaleUpdate(ScaleUpdateDetails details, Offset initialOffset, double initialScale) {
    // Update scale
    final double newScale = (initialScale * details.scale).clamp(minScale, maxScale);
    _scale = newScale;
    
    // Update offset for pan
    final delta = details.focalPoint - details.localFocalPoint;
    _offset = _constrainOffset(initialOffset + delta);
    
    notifyListeners();
  }
  
  /// Constrain offset to bounds if set
  Offset _constrainOffset(Offset offset) {
    if (minOffset == null || maxOffset == null) return offset;
    
    return Offset(
      offset.dx.clamp(minOffset!.dx, maxOffset!.dx),
      offset.dy.clamp(minOffset!.dy, maxOffset!.dy),
    );
  }
  
  /// Get transformation matrix for the current state
  Matrix4 getTransformMatrix() {
    return Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
  }
}

/// Widget wrapper that provides interactive viewport with zoom and pan
class InteractiveViewport extends StatefulWidget {
  final Widget child;
  final InteractiveViewportController? controller;
  final bool enableMouseScrollZoom;
  final bool enablePinchZoom;
  final bool enablePan;
  
  const InteractiveViewport({
    super.key,
    required this.child,
    this.controller,
    this.enableMouseScrollZoom = true,
    this.enablePinchZoom = true,
    this.enablePan = true,
  });
  
  @override
  State<InteractiveViewport> createState() => _InteractiveViewportState();
}

class _InteractiveViewportState extends State<InteractiveViewport> {
  late InteractiveViewportController _controller;
  bool _isOwnController = false;
  
  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;
  
  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = InteractiveViewportController();
      _isOwnController = true;
    } else {
      _controller = widget.controller!;
    }
    _controller.addListener(_onControllerUpdate);
  }
  
  @override
  void didUpdateWidget(InteractiveViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerUpdate);
      if (_isOwnController) {
        _controller.dispose();
      }
      
      if (widget.controller == null) {
        _controller = InteractiveViewportController();
        _isOwnController = true;
      } else {
        _controller = widget.controller!;
        _isOwnController = false;
      }
      _controller.addListener(_onControllerUpdate);
    }
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_isOwnController) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Listener(
          // Handle mouse scroll for zoom
          onPointerSignal: (event) {
            if (widget.enableMouseScrollZoom && event is PointerScrollEvent) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final Offset localPosition = renderBox.globalToLocal(event.position);
              _controller.handleScroll(event, localPosition, viewportSize);
            }
          },
          child: GestureDetector(
            // Handle both pan (drag) and pinch zoom through scale gestures
            // Scale gesture detector handles both pan (when scale=1.0) and pinch (when scale!=1.0)
            onScaleStart: (widget.enablePan || widget.enablePinchZoom)
                ? (details) {
                    _initialOffset = _controller.offset;
                    _initialScale = _controller.scale;
                  }
                : null,
            onScaleUpdate: (widget.enablePan || widget.enablePinchZoom)
                ? (details) {
                    if (details.scale != 1.0 && widget.enablePinchZoom) {
                      // Pinch zoom gesture
                      _controller.handleScaleUpdate(details, _initialOffset, _initialScale);
                    } else if (details.scale == 1.0 && widget.enablePan) {
                      // Pan/drag gesture (scale is 1.0, so it's just movement)
                      _controller.updateOffset(details.focalPointDelta);
                    }
                  }
                : null,
            child: Container(
              color: Colors.transparent,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Transform(
                    transform: _controller.getTransformMatrix(),
                    alignment: Alignment.center,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
