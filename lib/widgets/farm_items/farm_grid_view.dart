import 'package:flutter/material.dart';
import '../../models/farm_data.dart';
import '../../models/styles_schema.dart';
import 'farm_plot_widget.dart';

/// Interactive farm grid with zoom and pan capabilities
class FarmGridView extends StatefulWidget {
  final FarmState farmState;

  const FarmGridView({
    super.key,
    required this.farmState,
  });

  @override
  State<FarmGridView> createState() => _FarmGridViewState();
}

class _FarmGridViewState extends State<FarmGridView> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final double spacing = styles.getStyles('farm_page.farm_grid.plot_spacing') as double;

    return GestureDetector(
      onScaleStart: (details) {
        _startFocalPoint = details.focalPoint;
        _initialOffset = _offset;
        _initialScale = _scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Handle zoom: use initial scale so updates don't multiply repeatedly
          _scale = (_initialScale * details.scale).clamp(0.5, 3.0);

          // Handle pan
          final delta = details.focalPoint - _startFocalPoint;
          _offset = _initialOffset + delta;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_offset.dx, _offset.dy)
              ..scale(_scale),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.farmState.gridHeight,
                (y) {
                  // Reverse Y to make (0,0) bottom-left
                  final displayY = widget.farmState.gridHeight - 1 - y;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.farmState.gridWidth,
                      (x) {
                        final plot = widget.farmState.getPlot(x, displayY);
                        if (plot == null) return const SizedBox.shrink();

                        final hasDrone = widget.farmState.dronePosition.x == x &&
                            widget.farmState.dronePosition.y == displayY;

                        return Padding(
                          padding: EdgeInsets.all(spacing / 2),
                          child: FarmPlotWidget(
                            plot: plot,
                            hasDrone: hasDrone,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
