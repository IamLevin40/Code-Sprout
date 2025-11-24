import 'package:flutter/material.dart';
import '../../models/farm_data.dart';
import '../../models/styles_schema.dart';

/// Widget to display a single farm plot
class FarmPlotWidget extends StatelessWidget {
  final FarmPlot plot;
  final bool hasDrone;
  final DroneState? droneState;

  const FarmPlotWidget({
    super.key,
    required this.plot,
    this.hasDrone = false,
    this.droneState,
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
          // Crop display
          if (plot.crop != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildCropWidget(styles),
              ),
            ),
          // Drone display
          if (hasDrone)
            Positioned(
              bottom: 16,
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
    final width = styles.getStyles('farm_page.farm_grid.crop_size.width') as double;
    final height = styles.getStyles('farm_page.farm_grid.crop_size.height') as double;
    final placeholderColor = styles.getStyles('farm_page.farm_grid.crop_placeholder.color') as Color;
    final placeholderFontSize = styles.getStyles('farm_page.farm_grid.crop_placeholder.font_size') as double;
    final placeholderFontWeight = styles.getStyles('farm_page.farm_grid.crop_placeholder.font_weight') as FontWeight;
    
    if (plot.crop == null) return const SizedBox.shrink();

    // Use current growth stage image from FarmDataSchema
    final imagePath = plot.crop!.currentStageImage;
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Placeholder: crop display name + stage index
        final cropName = plot.crop!.cropType.displayName;
        final stage = plot.crop!.currentStage;

        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: Text(
            '$cropName\nS$stage',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: placeholderFontSize,
              fontWeight: placeholderFontWeight,
              color: placeholderColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDroneWidget(AppStyles styles) {
    final width = styles.getStyles('farm_page.farm_grid.drone_size.width') as double;
    final height = styles.getStyles('farm_page.farm_grid.drone_size.height') as double;
    
    // Get drone state image paths
    final normalImage = styles.getStyles('farm_page.farm_grid.drone_states.normal') as String;
    final tillingImage = styles.getStyles('farm_page.farm_grid.drone_states.tilling') as String;
    final wateringImage = styles.getStyles('farm_page.farm_grid.drone_states.watering') as String;

    // Determine which image to show based on drone state
    final currentState = droneState ?? DroneState.normal;
    String droneImage;
    switch (currentState) {
      case DroneState.tilling:
        droneImage = tillingImage;
        break;
      case DroneState.watering:
        droneImage = wateringImage;
        break;
      default:
        droneImage = normalImage;
    }

    return Image.asset(
      droneImage,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image not found
        return Icon(
          Icons.agriculture,
          size: width,
          color: Colors.blue,
        );
      },
    );
  }
}
