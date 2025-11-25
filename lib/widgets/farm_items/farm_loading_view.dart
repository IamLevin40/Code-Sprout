import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Enum to represent loading states
enum FarmLoadingState {
  loading,
  error,
  success,
}

/// Loading view widget for farm page with loading and error states
class FarmLoadingView extends StatelessWidget {
  final FarmLoadingState state;
  final String? errorMessage;
  final VoidCallback? onGoBack;
  final VoidCallback? onTryAgain;

  const FarmLoadingView({
    super.key,
    required this.state,
    this.errorMessage,
    this.onGoBack,
    this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    if (state == FarmLoadingState.success) {
      return const SizedBox.shrink();
    }

    final styles = AppStyles();
    final bgColor = styles.getStyles('farm_page.loading_view.background_color') as Color;

    return Container(
      color: bgColor,
      child: Center(
        child: state == FarmLoadingState.loading
            ? _buildLoadingState()
            : _buildErrorState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    final styles = AppStyles();
    final progressColor = styles.getStyles('farm_page.loading_view.loading_state.progress_indicator.color') as Color;
    final progressSize = styles.getStyles('farm_page.loading_view.loading_state.progress_indicator.size') as double;
    final progressStrokeWidth = styles.getStyles('farm_page.loading_view.loading_state.progress_indicator.stroke_width') as double;
    final textColor = styles.getStyles('farm_page.loading_view.loading_state.text.color') as Color;
    final textSize = styles.getStyles('farm_page.loading_view.loading_state.text.font_size') as double;
    final textWeight = styles.getStyles('farm_page.loading_view.loading_state.text.font_weight') as FontWeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: progressSize,
          height: progressSize,
          child: CircularProgressIndicator(
            color: progressColor,
            strokeWidth: progressStrokeWidth,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading your farm...',
          style: TextStyle(
            color: textColor,
            fontSize: textSize,
            fontWeight: textWeight,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final styles = AppStyles();
    final iconImage = styles.getStyles('farm_page.loading_view.error_state.icon.image') as String;
    final iconWidth = styles.getStyles('farm_page.loading_view.error_state.icon.width') as double;
    final iconHeight = styles.getStyles('farm_page.loading_view.error_state.icon.height') as double;
    final titleColor = styles.getStyles('farm_page.loading_view.error_state.title.color') as Color;
    final titleSize = styles.getStyles('farm_page.loading_view.error_state.title.font_size') as double;
    final titleWeight = styles.getStyles('farm_page.loading_view.error_state.title.font_weight') as FontWeight;
    final messageColor = styles.getStyles('farm_page.loading_view.error_state.message.color') as Color;
    final messageSize = styles.getStyles('farm_page.loading_view.error_state.message.font_size') as double;
    final messageWeight = styles.getStyles('farm_page.loading_view.error_state.message.font_weight') as FontWeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconImage,
          width: iconWidth,
          height: iconHeight,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.sentiment_very_dissatisfied,
              size: iconWidth,
              color: titleColor,
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Oops! Something went wrong',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: titleSize,
            fontWeight: titleWeight,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            errorMessage ?? 'Failed to load farm data. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: messageColor,
              fontSize: messageSize,
              fontWeight: messageWeight,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGoBackButton(),
            const SizedBox(width: 16),
            _buildTryAgainButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildGoBackButton() {
    final styles = AppStyles();
    final width = styles.getStyles('farm_page.loading_view.error_state.go_back_button.width') as double;
    final height = styles.getStyles('farm_page.loading_view.error_state.go_back_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.loading_view.error_state.go_back_button.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.loading_view.error_state.go_back_button.border_width') as double;
    final bgColor = styles.getStyles('farm_page.loading_view.error_state.go_back_button.background_color') as Color;
    final strokeGradient = styles.getStyles('farm_page.loading_view.error_state.go_back_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.loading_view.error_state.go_back_button.text.color') as Color;
    final textSize = styles.getStyles('farm_page.loading_view.error_state.go_back_button.text.font_size') as double;
    final textWeight = styles.getStyles('farm_page.loading_view.error_state.go_back_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onGoBack,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: strokeGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Center(
            child: Text(
              'Go Back',
              style: TextStyle(
                color: textColor,
                fontSize: textSize,
                fontWeight: textWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTryAgainButton() {
    final styles = AppStyles();
    final width = styles.getStyles('farm_page.loading_view.error_state.try_again_button.width') as double;
    final height = styles.getStyles('farm_page.loading_view.error_state.try_again_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.loading_view.error_state.try_again_button.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.loading_view.error_state.try_again_button.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.loading_view.error_state.try_again_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.loading_view.error_state.try_again_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.loading_view.error_state.try_again_button.text.color') as Color;
    final textSize = styles.getStyles('farm_page.loading_view.error_state.try_again_button.text.font_size') as double;
    final textWeight = styles.getStyles('farm_page.loading_view.error_state.try_again_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onTryAgain,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: strokeGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Center(
            child: Text(
              'Try Again',
              style: TextStyle(
                color: textColor,
                fontSize: textSize,
                fontWeight: textWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
