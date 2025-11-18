import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Code editor widget for writing farm drone code
class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  final Function(String) onCodeChanged;
  final VoidCallback onClose;

  const CodeEditorWidget({
    super.key,
    required this.initialCode,
    required this.onCodeChanged,
    required this.onClose,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
    _controller.addListener(() {
      widget.onCodeChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final bgGradient = styles.getStyles('farm_page.code_editor.background_color') as LinearGradient;
    final borderRadius = styles.getStyles('farm_page.code_editor.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.code_editor.border_width') as double;
    final strokeGradient = styles.getStyles('farm_page.code_editor.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.code_editor.text_style.color') as Color;
    final fontSize = styles.getStyles('farm_page.code_editor.text_style.font_size') as double;
    final closeIcon = styles.getStyles('farm_page.code_editor.close_button.icon') as String;
    final closeSize = styles.getStyles('farm_page.code_editor.close_button.width') as double;

    return Container(
      width: double.infinity,
      height: 400,
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
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Code Editor',
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Image.asset(
                      closeIcon,
                      width: closeSize,
                      height: closeSize,
                    ),
                  ),
                ],
              ),
            ),
            // Code area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '// Write your code here...',
                    hintStyle: TextStyle(color: Colors.grey),
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
