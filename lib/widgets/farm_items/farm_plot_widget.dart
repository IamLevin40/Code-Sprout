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
    
    // Image paths for plot states (strict tokens)
    final normalPlotImage = styles.getStyles('farm_page.farm_grid.plot_states.normal') as String;
    final tilledPlotImage = styles.getStyles('farm_page.farm_grid.plot_states.tilled') as String;
    final wateredPlotImage = styles.getStyles('farm_page.farm_grid.plot_states.watered') as String;

    String plotImage;
    switch (plot.state) {
      case PlotState.tilled:
        plotImage = tilledPlotImage;
        break;
      case PlotState.watered:
        plotImage = wateredPlotImage;
        break;
      default:
        plotImage = normalPlotImage;
    }

    return Container(
      width: plotSize,
      height: plotSize,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(plotImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Crop display (offset from top)
          if (plot.crop != null)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildCropWidget(styles),
              ),
            ),
          // Drone display (offset from top)
          if (hasDrone)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildDroneWidget(styles),
              ),
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
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Placeholder: crop display name + stage index
        final cropName = plot.crop!.cropType.displayName;
        final stage = plot.crop!.currentStage;
        final placeholderColor = styles.getStyles('farm_page.farm_grid.crop_placeholder_color') as Color;

        return Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Text(
            '$cropName\nS$stage',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
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
