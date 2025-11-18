import 'package:flutter/material.dart';
import '../../models/farm_data.dart';
import '../../models/styles_schema.dart';

/// Widget to display a single farm plot
class FarmPlotWidget extends StatelessWidget {
  final FarmPlot plot;
  final bool hasDrone;

  const FarmPlotWidget({
    super.key,
    required this.plot,
    this.hasDrone = false,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final double plotSize = styles.getStyles('farm_page.farm_grid.plot_size') as double;
    final double borderWidth = styles.getStyles('farm_page.farm_grid.plot_border_width') as double;
    final double borderRadius = styles.getStyles('farm_page.farm_grid.plot_border_radius') as double;

    Color plotColor;
    switch (plot.state) {
      case PlotState.tilled:
        plotColor = styles.getStyles('farm_page.farm_grid.tilled_plot_color') as Color;
        break;
      case PlotState.watered:
        plotColor = styles.getStyles('farm_page.farm_grid.watered_plot_color') as Color;
        break;
      default:
        plotColor = styles.getStyles('farm_page.farm_grid.normal_plot_color') as Color;
    }

    final borderColor = styles.getStyles('farm_page.farm_grid.plot_border_color') as Color;

    return Container(
      width: plotSize,
      height: plotSize,
      decoration: BoxDecoration(
        color: plotColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          // Crop display
          if (plot.crop != null)
            Center(
              child: _buildCropWidget(styles),
            ),
          // Drone display
          if (hasDrone)
            Center(
              child: _buildDroneWidget(styles),
            ),
        ],
      ),
    );
  }

  Widget _buildCropWidget(AppStyles styles) {
    if (plot.crop == null) return const SizedBox.shrink();

    final cropImages = styles.getStyles('sprout_researches.crop_items') as Map<String, dynamic>;
    final cropId = plot.crop!.cropType.id;
    final imagePath = cropImages[cropId] as String;

    return Image.asset(
      imagePath,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
    );
  }

  Widget _buildDroneWidget(AppStyles styles) {
    final droneSize = styles.getStyles('farm_page.farm_grid.drone_size') as double;
    final droneColor = styles.getStyles('farm_page.farm_grid.drone_color') as Color;

    return Icon(
      Icons.agriculture,
      size: droneSize,
      color: droneColor,
    );
  }
}
