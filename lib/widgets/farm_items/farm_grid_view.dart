import 'package:flutter/material.dart';
import '../../models/farm_data.dart';
import '../../models/styles_schema.dart';
import '../../miscellaneous/interactive_viewport_controller.dart';
import 'farm_plot_widget.dart';

/// Interactive farm grid with infinite viewport, zoom and pan capabilities
/// Works like a game camera - freely viewable in all directions
class FarmGridView extends StatelessWidget {
  final FarmState farmState;
  final InteractiveViewportController? controller;

  const FarmGridView({
    super.key,
    required this.farmState,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final double spacing = styles.getStyles('farm_page.farm_grid.plot_spacing') as double;

    return InteractiveViewport(
      controller: controller,
      enableMouseScrollZoom: true,
      enablePinchZoom: true,
      enablePan: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          farmState.gridHeight,
          (y) {
            // Reverse Y to make (0,0) bottom-left
            final displayY = farmState.gridHeight - 1 - y;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                farmState.gridWidth,
                (x) {
                  final plot = farmState.getPlot(x, displayY);
                  if (plot == null) return const SizedBox.shrink();

                  final hasDrone = farmState.dronePosition.x == x &&
                      farmState.dronePosition.y == displayY;

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
    );
  }
}
