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

    // Use current growth stage image from FarmDataSchema
    final imagePath = plot.crop!.currentStageImage;

    // Show asset if available; if asset can't be loaded, display a simple
    // text placeholder showing crop name and stage to avoid runtime errors
    // when stage images are not present yet.
    return Image.asset(
      imagePath,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback placeholder: crop display name + stage index
        final cropName = plot.crop!.cropType.displayName;
        final stage = plot.crop!.currentStage;
        Color placeholderColor = Colors.black;
        try {
          if (styles.hasPath('farm_page.farm_grid.crop_placeholder_color')) {
            placeholderColor = styles.getStyles('farm_page.farm_grid.crop_placeholder_color') as Color;
          }
        } catch (_) {
          // ignore and use default
        }

        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Text(
            '$cropName\nS$stage',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: placeholderColor,
            ),
          ),
        );
      },
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
