import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/terms_and_conditions_schema.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

/// Overlay widget displaying Terms and Conditions that must be accepted
/// before using the application
class TermsAndConditionsDisplay extends StatefulWidget {
  final VoidCallback onAccepted;
  
  const TermsAndConditionsDisplay({
    super.key,
    required this.onAccepted,
  });

  @override
  State<TermsAndConditionsDisplay> createState() => _TermsAndConditionsDisplayState();
}

class _TermsAndConditionsDisplayState extends State<TermsAndConditionsDisplay> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isProcessing = false;
  List<TermsSection> _sections = [];
  
  @override
  void initState() {
    super.initState();
    _loadTerms();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTerms() async {
    try {
      final schema = TermsAndConditionsSchema.instance;
      if (!schema.isLoaded()) {
        await schema.loadSchema();
      }
      
      setState(() {
        _sections = schema.getSections();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading terms: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleDecline() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Log out the user
      final authService = AuthService();
      await authService.signOut();
      
      // Clear local storage
      await LocalStorageService.instance.clearUserData();
      
      if (mounted) {
        // Navigate back to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Error during decline: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  Future<void> _handleAccept() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Get current user data
      final userData = await LocalStorageService.instance.getUserData();
      
      if (userData != null) {
        // Update the hasCheckedTermsAndConditions flag
        await userData.updateField('interaction.hasCheckedTermsAndConditions', true);
        
        // Notify that terms were accepted
        widget.onAccepted();
      }
    } catch (e) {
      debugPrint('Error during accept: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    final borderRadius = styles.getStyles('terms_and_conditions_display.border_radius') as double;
    final borderWidth = styles.getStyles('terms_and_conditions_display.border_width') as double;
    final backgroundColor = styles.getStyles('terms_and_conditions_display.background_color') as Color;
    final strokeGradient = styles.getStyles('terms_and_conditions_display.stroke_color') as LinearGradient;
    
    final iconImage = styles.getStyles('terms_and_conditions_display.icon.image') as String;
    final iconWidth = styles.getStyles('terms_and_conditions_display.icon.width') as double;
    final iconHeight = styles.getStyles('terms_and_conditions_display.icon.height') as double;
    
    final titleColor = styles.getStyles('terms_and_conditions_display.title.color') as Color;
    final titleSize = styles.getStyles('terms_and_conditions_display.title.font_size') as double;
    final titleWeight = styles.getStyles('terms_and_conditions_display.title.font_weight') as FontWeight;
    
    final sectionTitleColor = styles.getStyles('terms_and_conditions_display.section_title_text.color') as Color;
    final sectionTitleSize = styles.getStyles('terms_and_conditions_display.section_title_text.font_size') as double;
    final sectionTitleWeight = styles.getStyles('terms_and_conditions_display.section_title_text.font_weight') as FontWeight;
    
    final contentColor = styles.getStyles('terms_and_conditions_display.content_text.color') as Color;
    final contentSize = styles.getStyles('terms_and_conditions_display.content_text.font_size') as double;
    final contentWeight = styles.getStyles('terms_and_conditions_display.content_text.font_weight') as FontWeight;
    
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              gradient: strokeGradient,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.all(borderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Image.asset(
                      iconImage,
                      width: iconWidth,
                      height: iconHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Title
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _sections.map((section) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Section title
                                          Text(
                                            section.title,
                                            style: TextStyle(
                                              color: sectionTitleColor,
                                              fontSize: sectionTitleSize,
                                              fontWeight: sectionTitleWeight,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Section content
                                          ...section.content.map((line) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                line,
                                                style: TextStyle(
                                                  color: contentColor,
                                                  fontSize: contentSize,
                                                  fontWeight: contentWeight,
                                                  height: 1.5,
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decline button
                        _buildDeclineButton(styles),
                        const SizedBox(width: 16),
                        // Accept button
                        _buildAcceptButton(styles),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeclineButton(AppStyles styles) {
    final buttonWidth = styles.getStyles('terms_and_conditions_display.decline_button.width') as double;
    final buttonHeight = styles.getStyles('terms_and_conditions_display.decline_button.height') as double;
    final borderRadius = styles.getStyles('terms_and_conditions_display.decline_button.border_radius') as double;
    final borderWidth = styles.getStyles('terms_and_conditions_display.decline_button.border_width') as double;
    final backgroundColor = styles.getStyles('terms_and_conditions_display.decline_button.background_color') as Color;
    final strokeGradient = styles.getStyles('terms_and_conditions_display.decline_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('terms_and_conditions_display.decline_button.text.color') as Color;
    final textSize = styles.getStyles('terms_and_conditions_display.decline_button.text.font_size') as double;
    final textWeight = styles.getStyles('terms_and_conditions_display.decline_button.text.font_weight') as FontWeight;
    
    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: strokeGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: TextButton(
          onPressed: _isProcessing ? null : _handleDecline,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Center(
            child: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Text(
                    'Decline',
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
  
  Widget _buildAcceptButton(AppStyles styles) {
    final buttonWidth = styles.getStyles('terms_and_conditions_display.accept_button.width') as double;
    final buttonHeight = styles.getStyles('terms_and_conditions_display.accept_button.height') as double;
    final borderRadius = styles.getStyles('terms_and_conditions_display.accept_button.border_radius') as double;
    final borderWidth = styles.getStyles('terms_and_conditions_display.accept_button.border_width') as double;
    final backgroundGradient = styles.getStyles('terms_and_conditions_display.accept_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('terms_and_conditions_display.accept_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('terms_and_conditions_display.accept_button.text.color') as Color;
    final textSize = styles.getStyles('terms_and_conditions_display.accept_button.text.font_size') as double;
    final textWeight = styles.getStyles('terms_and_conditions_display.accept_button.text.font_weight') as FontWeight;
    
    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: strokeGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: TextButton(
          onPressed: _isProcessing ? null : _handleAccept,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Center(
            child: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Text(
                    'Accept',
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
