import 'package:flutter/material.dart';
import '../models/farm_data.dart';
import '../models/styles_schema.dart';
import '../widgets/farm_items/farm_grid_view.dart';
import '../widgets/farm_items/code_editor_widget.dart';
import '../compilers/base_interpreter.dart';
import '../compilers/cpp_interpreter.dart';
import '../compilers/csharp_interpreter.dart';
import '../compilers/java_interpreter.dart';
import '../compilers/python_interpreter.dart';
import '../compilers/javascript_interpreter.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class FarmPage extends StatefulWidget {
  final String languageId;
  final String languageName;

  const FarmPage({
    super.key,
    required this.languageId,
    required this.languageName,
  });

  @override
  State<FarmPage> createState() => _FarmPageState();
}

class _FarmPageState extends State<FarmPage> {
  late FarmState _farmState;
  bool _showCodeEditor = false;
  String _userCode = '';
  List<String> _executionLog = [];
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _farmState = FarmState();
    _userCode = _getDefaultCode();
    _farmState.addListener(_onFarmStateChanged);
  }

  @override
  void dispose() {
    _farmState.removeListener(_onFarmStateChanged);
    _farmState.dispose();
    super.dispose();
  }

  void _onFarmStateChanged() {
    if (mounted) setState(() {});
  }

  String _getDefaultCode() {
    switch (widget.languageId) {
      case 'cpp':
        return '// C++ Farm Drone Code\n'
            '#include <iostream>\n\n'
            'int main() {\n'
            '    // Example: Move and till\n'
            '    move(Direction::East);\n'
            '    till();\n'
            '    water();\n'
            '    plant(Crop::Wheat);\n'
            '    harvest();\n\n'
            '    return 0;\n'
            '}';
      case 'csharp':
        return '// C# Farm Drone Code\n'
            'using System;\n\n'
            'class Program {\n'
            '    static void Main() {\n'
            '        // Example: Move and till\n'
            '        move(Direction.East);\n'
            '        till();\n'
            '        water();\n'
            '        plant(Crop.Wheat);\n'
            '        harvest();\n'
            '    }\n'
            '}';
      case 'java':
        return '// Java Farm Drone Code\n'
            'public class Main {\n'
            '    public static void main(String[] args) {\n'
            '        // Example: Move and till\n'
            '        move(Direction.EAST);\n'
            '        till();\n'
            '        water();\n'
            '        plant(Crop.WHEAT);\n'
            '        harvest();\n'
            '    }\n'
            '}';
      case 'python':
        return '# Python Farm Drone Code\n'
            '# Example: Move and till\n'
            'move(Direction.East)\n'
            'till()\n'
            'water()\n'
            'plant(Crop.Wheat)\n'
            'harvest()';
      case 'javascript':
        return '// JavaScript Farm Drone Code\n'
            '// Example: Move and till\n'
            'move(Direction.East);\n'
            'till();\n'
            'water();\n'
            'plant(Crop.Wheat);\n'
            'harvest();';
      default:
        return '// Write your code here';
    }
  }

  FarmCodeInterpreter _getInterpreter() {
    switch (widget.languageId) {
      case 'cpp':
        return CppInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
        );
      case 'csharp':
        return CSharpInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
        );
      case 'java':
        return JavaInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
        );
      case 'python':
        return PythonInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
        );
      case 'javascript':
        return JavaScriptInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
        );
      default:
        return CppInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
        );
    }
  }

  Future<void> _onCropHarvested(CropType cropType) async {
    // Update user data with harvested crop
    try {
      final auth = AuthService();
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        final userData = await FirestoreService.getUserData(currentUser.uid);
        if (userData != null) {
          final currentQty = userData.get('sproutProgress.cropItems.${cropType.id}.quantity') as int? ?? 0;
          await userData.updateField('sproutProgress.cropItems.${cropType.id}.quantity', currentQty + 1);
        }
      }
    } catch (e) {
      debugPrint('Error updating crop quantity: $e');
    }
  }

  Future<void> _startExecution() async {
    setState(() {
      _isExecuting = true;
      _executionLog.clear();
      _farmState.setExecuting(true);
    });

    final interpreter = _getInterpreter();
    final result = await interpreter.execute(_userCode);

    setState(() {
      _isExecuting = false;
      _executionLog = result.executionLog;
      _farmState.setExecuting(false);
    });

    if (!result.success && result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
    }
  }

  void _stopExecution() {
    setState(() {
      _isExecuting = false;
      _farmState.setExecuting(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final bgGradient = styles.getStyles('farm_page.background_color') as LinearGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top bar with back button and language display
                Row(
                  children: [
                    _buildBackButton(styles),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLanguageDisplay(styles)),
                  ],
                ),
                const SizedBox(height: 16),

                // Farm grid view
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FarmGridView(farmState: _farmState),
                  ),
                ),
                const SizedBox(height: 16),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCodeButton(styles),
                    if (!_isExecuting) _buildStartButton(styles),
                    if (_isExecuting) _buildStopButton(styles),
                  ],
                ),
                const SizedBox(height: 16),

                // Code editor or execution log
                Expanded(
                  flex: 2,
                  child: _showCodeEditor
                      ? CodeEditorWidget(
                          initialCode: _userCode,
                          onCodeChanged: (code) {
                            _userCode = code;
                          },
                          onClose: () {
                            setState(() => _showCodeEditor = false);
                          },
                        )
                      : _buildExecutionLog(styles),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(AppStyles styles) {
    final icon = styles.getStyles('farm_page.back_button.icon') as String;
    final size = styles.getStyles('farm_page.back_button.width') as double;
    final bgColor = styles.getStyles('farm_page.back_button.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.back_button.border_radius') as double;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Image.asset(icon, width: size * 0.6, height: size * 0.6),
        ),
      ),
    );
  }

  Widget _buildLanguageDisplay(AppStyles styles) {
    final height = styles.getStyles('farm_page.language_display.height') as double;
    final borderRadius = styles.getStyles('farm_page.language_display.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.language_display.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.language_display.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.language_display.stroke_color') as LinearGradient;
    final iconSize = styles.getStyles('farm_page.language_display.language_icon.width') as double;
    final iconBorderRadius = styles.getStyles('farm_page.language_display.language_icon.border_radius') as double;
    final iconBgGradient = styles.getStyles('farm_page.language_display.language_icon.background_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.language_display.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.language_display.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.language_display.text.font_weight') as FontWeight;

    final languageIcons = styles.getStyles('course_cards.style_coding.${widget.languageId}.icon') as String;

    return Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: iconBgGradient,
                borderRadius: BorderRadius.circular(iconBorderRadius),
              ),
              child: Center(
                child: Image.asset(languageIcons, width: iconSize * 0.7, height: iconSize * 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.languageName,
              style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeButton(AppStyles styles) {
    return _buildControlButton(
      styles: styles,
      label: 'Code',
      styleKey: 'farm_page.control_buttons.code_button',
      onTap: () {
        setState(() => _showCodeEditor = !_showCodeEditor);
      },
    );
  }

  Widget _buildStartButton(AppStyles styles) {
    return _buildControlButton(
      styles: styles,
      label: 'Start',
      styleKey: 'farm_page.control_buttons.start_button',
      onTap: _startExecution,
    );
  }

  Widget _buildStopButton(AppStyles styles) {
    return _buildControlButton(
      styles: styles,
      label: 'Stop',
      styleKey: 'farm_page.control_buttons.stop_button',
      onTap: _stopExecution,
    );
  }

  Widget _buildControlButton({
    required AppStyles styles,
    required String label,
    required String styleKey,
    required VoidCallback onTap,
  }) {
    final width = styles.getStyles('$styleKey.width') as double;
    final height = styles.getStyles('$styleKey.height') as double;
    final borderRadius = styles.getStyles('$styleKey.border_radius') as double;
    final borderWidth = styles.getStyles('$styleKey.border_width') as double;
    final bgGradient = styles.getStyles('$styleKey.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('$styleKey.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('$styleKey.text.color') as Color;
    final fontSize = styles.getStyles('$styleKey.text.font_size') as double;
    final fontWeight = styles.getStyles('$styleKey.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onTap,
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
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
          ),
        ),
      ),
    );
  }

  Widget _buildExecutionLog(AppStyles styles) {
    final bgGradient = styles.getStyles('farm_page.execution_log.background_color') as LinearGradient;
    final borderRadius = styles.getStyles('farm_page.execution_log.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.execution_log.border_width') as double;
    final strokeGradient = styles.getStyles('farm_page.execution_log.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.execution_log.text_color') as Color;
    final fontSize = styles.getStyles('farm_page.execution_log.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.execution_log.font_weight') as FontWeight;

    return Container(
      width: double.infinity,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execution Log',
              style: TextStyle(
                color: textColor,
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _executionLog.isEmpty ? 'No execution yet...' : _executionLog.join('\n'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
