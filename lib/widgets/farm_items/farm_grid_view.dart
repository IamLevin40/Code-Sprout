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
    final double plotSize = styles.getStyles('farm_page.farm_grid.plot_size') as double;

    return InteractiveViewport(
      controller: controller,
      enableMouseScrollZoom: true,
      enablePinchZoom: true,
      enablePan: true,
      child: Stack(
        children: [
          // Grid of plots
          Column(
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

                      return Padding(
                        padding: EdgeInsets.all(spacing / 2),
                        child: FarmPlotWidget(
                          plot: plot,
                          hasDrone: false, // Drone is rendered separately now
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Animated drone overlay
          _buildAnimatedDrone(styles, plotSize, spacing),
        ],
      ),
    );
  }

  /// Build the animated drone that floats above the grid
  Widget _buildAnimatedDrone(AppStyles styles, double plotSize, double spacing) {
    // Convert grid coordinates to display coordinates (reverse Y)
    final displayY = farmState.gridHeight - 1 - farmState.dronePosition.animatedY;
    final displayX = farmState.dronePosition.animatedX;

    // Calculate pixel position based on animated coordinates
    final cellSize = plotSize + spacing;
    final left = displayX * cellSize + spacing / 2;
    final top = displayY * cellSize + spacing / 2;

    // Get drone state images
    final normalImage = styles.getStyles('farm_page.farm_grid.drone_states.normal') as String;
    final tillingImage = styles.getStyles('farm_page.farm_grid.drone_states.tilling') as String;
    final wateringImage = styles.getStyles('farm_page.farm_grid.drone_states.watering') as String;
    final plantingImage = styles.getStyles('farm_page.farm_grid.drone_states.planting') as String;
    final harvestingImage = styles.getStyles('farm_page.farm_grid.drone_states.harvesting') as String;

    String droneImage;
    switch (farmState.dronePosition.state) {
      case DroneState.tilling:
        droneImage = tillingImage;
        break;
      case DroneState.watering:
        droneImage = wateringImage;
        break;
      case DroneState.planting:
        droneImage = plantingImage;
        break;
      case DroneState.harvesting:
        droneImage = harvestingImage;
        break;
      default:
        droneImage = normalImage;
    }

    final droneWidth = styles.getStyles('farm_page.farm_grid.drone_size.width') as double;
    final droneHeight = styles.getStyles('farm_page.farm_grid.drone_size.height') as double;

    final leftPos = left + (plotSize - droneWidth) / 2;
    final topPos = top + (plotSize - droneHeight) - 32;

    return Positioned(
      left: leftPos,
      top: topPos,
      child: Image.asset(
        droneImage,
        width: droneWidth,
        height: droneHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image not found
          return Icon(
            Icons.agriculture,
            size: droneWidth,
            color: Colors.blue,
          );
        },
      ),
    );
  }
}
