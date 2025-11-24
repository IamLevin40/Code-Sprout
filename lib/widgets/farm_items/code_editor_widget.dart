import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../miscellaneous/handle_code_editing.dart';

/// Code editor widget - Complete redesign with new layout structure
/// Features: Background layer + Code button on top + Text editor + File toolbar
/// Mobile-friendly with horizontal/vertical scrollbars for infinite extension
class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  final Function(String) onCodeChanged;
  final VoidCallback onClose;
  final ValueNotifier<int?>? executingLineNotifier;
  final ValueNotifier<int?>? errorLineNotifier;
  final TextEditingController? controller;
  final bool isReadOnly;
  
  // File management options
  final String? currentFileName;
  final VoidCallback? onAddFile;
  final VoidCallback? onDeleteFile;
  final VoidCallback? onNextFile;
  final VoidCallback? onPreviousFile;
  final bool canDeleteFile;

  const CodeEditorWidget({
    super.key,
    required this.initialCode,
    required this.onCodeChanged,
    required this.onClose,
    this.executingLineNotifier,
    this.errorLineNotifier,
    this.controller,
    this.isReadOnly = false,
    this.currentFileName,
    this.onAddFile,
    this.onDeleteFile,
    this.onNextFile,
    this.onPreviousFile,
    this.canDeleteFile = true,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;
  late bool _ownsController;
  late FocusNode _focusNode;
  int? _highlightLine;
  int? _errorLine;
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      // ensure initial text
      if (_controller.text.isEmpty) _controller.text = widget.initialCode;
    } else {
      _controller = TextEditingController(text: widget.initialCode);
      _ownsController = true;
    }
    _focusNode = FocusNode();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _controller.addListener(() {
      widget.onCodeChanged(_controller.text);
    });

    // Listen for external executing line changes if provided
    widget.executingLineNotifier?.addListener(_onExecutingLineChanged);
    widget.errorLineNotifier?.addListener(_onErrorLineChanged);
  }

  @override
  void dispose() {
    widget.executingLineNotifier?.removeListener(_onExecutingLineChanged);
    widget.errorLineNotifier?.removeListener(_onErrorLineChanged);
    _focusNode.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onExecutingLineChanged() {
    CodeEditingHandler.onExecutingLineChanged(
      executingLineNotifier: widget.executingLineNotifier!,
      setHighlightLine: (line) => setState(() => _highlightLine = line),
    );
  }

  void _onErrorLineChanged() {
    CodeEditingHandler.onErrorLineChanged(
      errorLineNotifier: widget.errorLineNotifier!,
      setErrorLine: (line) => setState(() => _errorLine = line),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    return CodeEditingHandler.handleKey(
      node: node,
      event: event,
      controller: _controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    // Load all styling from farm_page.code_editor path
    final editorBorderRadius = styles.getStyles('farm_page.code_editor.border_radius') as double;
    final editorBgColor = styles.getStyles('farm_page.code_editor.background_color') as Color;
    
    final textEditorBorderRadius = styles.getStyles('farm_page.code_editor.text_editor.border_radius') as double;
    final textEditorBgColor = styles.getStyles('farm_page.code_editor.text_editor.background_color') as Color;
    final codeTextColor = styles.getStyles('farm_page.code_editor.text_editor.code_text.color') as Color;
    final codeTextFontSize = styles.getStyles('farm_page.code_editor.text_editor.code_text.font_size') as double;
    final codeTextFontWeight = styles.getStyles('farm_page.code_editor.text_editor.code_text.font_weight') as FontWeight;
    final scrollBarHandleColor = styles.getStyles('farm_page.code_editor.text_editor.scroll_bar.handle_color') as Color;
    final scrollBarBgColor = styles.getStyles('farm_page.code_editor.text_editor.scroll_bar.background_color') as Color;
    final scrollBarBorderRadius = styles.getStyles('farm_page.code_editor.text_editor.scroll_bar.border_radius') as double;
    final scrollBarThickness = styles.getStyles('farm_page.code_editor.text_editor.scroll_bar.thickness') as double;
    
    final backIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.back.icon.image') as String;
    final backIconWidth = styles.getStyles('farm_page.code_editor.file_toolbar.back.icon.width') as double;
    final backIconHeight = styles.getStyles('farm_page.code_editor.file_toolbar.back.icon.height') as double;
    final backBgColor = styles.getStyles('farm_page.code_editor.file_toolbar.back.background_color') as Color;
    final backBorderRadius = styles.getStyles('farm_page.code_editor.file_toolbar.back.border_radius') as double;
    final backWidth = styles.getStyles('farm_page.code_editor.file_toolbar.back.width') as double;
    final backHeight = styles.getStyles('farm_page.code_editor.file_toolbar.back.height') as double;
    
    final tabOptionsWidth = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.width') as double;
    final tabOptionsHeight = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.height') as double;
    final tabOptionsBorderRadius = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.border_radius') as double;
    final tabOptionsBgColor = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.background_color') as Color;
    final fileNameColor = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.file_name.color') as Color;
    final fileNameFontSize = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.file_name.font_size') as double;
    final fileNameFontWeight = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.file_name.font_weight') as FontWeight;
    
    final tabButtonWidth = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.width') as double;
    final tabButtonHeight = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.height') as double;
    final tabButtonBorderRadius = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.border_radius') as double;
    final tabButtonBgColor = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.background_color') as Color;
    final previousIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.icons.previous') as String;
    final nextIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.icons.next') as String;
    final addIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.icons.add') as String;
    final deleteIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.icons.delete') as String;
    final indentIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.icons.indent') as String;
    final dedentIconPath = styles.getStyles('farm_page.code_editor.file_toolbar.tab_options.tab_buttons.icons.dedent') as String;

    return Container(
      decoration: BoxDecoration(
        color: editorBgColor,
        borderRadius: BorderRadius.circular(editorBorderRadius),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Text editor with scrollbars
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: textEditorBgColor,
                borderRadius: BorderRadius.circular(textEditorBorderRadius),
              ),
              padding: const EdgeInsets.all(12),
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(scrollBarHandleColor),
                  trackColor: WidgetStateProperty.all(scrollBarBgColor),
                  thickness: WidgetStateProperty.all(scrollBarThickness),
                  radius: Radius.circular(scrollBarBorderRadius),
                ),
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      scrollDirection: Axis.vertical,
                      child: Focus(
                        onKeyEvent: _handleKey,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: IntrinsicWidth(
                            stepWidth: 960,
                            child: Padding(
                              // leave space for scrollbars so they don't overlap content
                              padding: EdgeInsets.only(right: scrollBarThickness, bottom: scrollBarThickness + 8),
                              child: Stack(
                                alignment: Alignment.topLeft,
                                children: [
                                  // Background highlighted lines (transparent text so only backgrounds show)
                                  SelectableText.rich(
                                    _buildHighlightedText(_controller.text, codeTextColor, codeTextFontSize, codeTextFontWeight),
                                    style: TextStyle(
                                      color: Colors.transparent,
                                      fontSize: codeTextFontSize,
                                      fontWeight: codeTextFontWeight,
                                    ),
                                  ),
                                  // Foreground editable text
                                  TextField(
                                    controller: _controller,
                                    readOnly: widget.isReadOnly,
                                    maxLines: null,
                                    style: TextStyle(
                                      color: codeTextColor,
                                      fontSize: codeTextFontSize,
                                      fontWeight: codeTextFontWeight,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '// Write your code here...',
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // File toolbar at bottom (centered)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back button (left)
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: backWidth,
                  height: backHeight,
                  decoration: BoxDecoration(
                    color: backBgColor,
                    borderRadius: BorderRadius.circular(backBorderRadius),
                  ),
                  child: Center(
                    child: Image.asset(
                      backIconPath,
                      width: backIconWidth,
                      height: backIconHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tab options container (right)
              Container(
                width: tabOptionsWidth,
                height: tabOptionsHeight,
                decoration: BoxDecoration(
                  color: tabOptionsBgColor,
                  borderRadius: BorderRadius.circular(tabOptionsBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    _buildTabButton(previousIconPath, widget.onPreviousFile, tabButtonWidth, tabButtonHeight, tabButtonBorderRadius, tabButtonBgColor),
                    // File name
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          widget.currentFileName ?? 'Untitled',
                          style: TextStyle(
                            color: fileNameColor,
                            fontSize: fileNameFontSize,
                            fontWeight: fileNameFontWeight,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Next button
                    _buildTabButton(nextIconPath, widget.onNextFile, tabButtonWidth, tabButtonHeight, tabButtonBorderRadius, tabButtonBgColor),
                    const SizedBox(width: 4),
                    // Add button
                    _buildTabButton(addIconPath, widget.onAddFile, tabButtonWidth, tabButtonHeight, tabButtonBorderRadius, tabButtonBgColor),
                    const SizedBox(width: 4),
                    // Delete button
                    _buildTabButton(deleteIconPath, widget.canDeleteFile ? widget.onDeleteFile : null, tabButtonWidth, tabButtonHeight, tabButtonBorderRadius, tabButtonBgColor),
                    const SizedBox(width: 4),
                    // Indent button
                    _buildTabButton(indentIconPath, () => CodeEditingHandler.indentText(controller: _controller), tabButtonWidth, tabButtonHeight, tabButtonBorderRadius, tabButtonBgColor),
                    const SizedBox(width: 4),
                    // Dedent button
                    _buildTabButton(dedentIconPath, () => CodeEditingHandler.unindentText(controller: _controller), tabButtonWidth, tabButtonHeight, tabButtonBorderRadius, tabButtonBgColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String iconPath, VoidCallback? onTap, double width, double height, double borderRadius, Color bgColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: width * 0.6,
            height: height * 0.6,
          ),
        ),
      ),
    );
  }

  // Build a TextSpan used by a background SelectableText.rich to render
  // highlighted line backgrounds (text rendered transparent so only backgrounds show).
  TextSpan _buildHighlightedText(String text, Color textColor, double fontSize, FontWeight fontWeight) {
    final styles = AppStyles();
    final validColor = styles.getStyles('farm_page.code_editor.text_editor.highlight.valid_color') as Color;
    final errorColor = styles.getStyles('farm_page.code_editor.text_editor.highlight.error_color') as Color;
    
    final lines = text.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      final isExec = _highlightLine == lineNumber;
      final isErr = _errorLine == lineNumber;

      Color? bg;
      if (isErr) {
        bg = errorColor;
      } else if (isExec) {
        bg = validColor;
      }

      spans.add(TextSpan(
        text: lines[i] + (i < lines.length - 1 ? '\n' : ''),
        style: TextStyle(
          backgroundColor: bg,
        ),
      ));
    }

    return TextSpan(children: spans);
  }
}
