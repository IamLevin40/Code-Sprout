import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/styles_schema.dart';

/// Code editor widget for writing farm drone code
class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  final Function(String) onCodeChanged;
  final VoidCallback onClose;
  final ValueNotifier<int?>? executingLineNotifier;
  final TextEditingController? controller;

  const CodeEditorWidget({
    super.key,
    required this.initialCode,
    required this.onCodeChanged,
    required this.onClose,
    this.executingLineNotifier,
    this.controller,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;
  late bool _ownsController;
  late FocusNode _focusNode;
  int? _highlightLine;
  late ScrollController _scrollController;
  
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
    _scrollController = ScrollController();
    _controller.addListener(() {
      widget.onCodeChanged(_controller.text);
    });

    // Listen for external executing line changes if provided
    widget.executingLineNotifier?.addListener(_onExecutingLineChanged);
  }

  @override
  void dispose() {
    widget.executingLineNotifier?.removeListener(_onExecutingLineChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onExecutingLineChanged() {
    final notifier = widget.executingLineNotifier!;
    final line = notifier.value; // 1-based index or null
    setState(() {
      _highlightLine = line;
    });
  }

  // Insert text at current selection and place caret at optional caretOffset
  void _insertText(String insert, {int? caretOffsetFromStart}) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start >= 0 ? sel.start : 0;
    final end = sel.end >= 0 ? sel.end : 0;
    final newText = text.replaceRange(start, end, insert);
    final caret = (caretOffsetFromStart != null)
        ? start + caretOffsetFromStart
        : start + insert.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  KeyEventResult _handleKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    // Enter / Return => smart auto-indent
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final sel = _controller.selection;
      final pos = sel.start >= 0 ? sel.start : 0;
      final text = _controller.text;

      // find start of current line
      final lastNl = pos > 0 ? text.lastIndexOf('\n', pos - 1) : -1;
      final lineStart = lastNl == -1 ? 0 : lastNl + 1;
      final linePrefix = text.substring(lineStart, pos);

      final baseIndentMatch = RegExp(r'^[ \t]*').firstMatch(linePrefix);
      final baseIndent = baseIndentMatch?.group(0) ?? '';

      // If caret is between an auto-paired brace pair like '{|}', create a new indented block
      final prevChar = pos > 0 ? text[pos - 1] : null;
      final nextChar = pos < text.length ? text[pos] : null;
      if (prevChar == '{' && nextChar == '}') {
        final innerIndent = baseIndent + '    ';
        final insert = '\n' + innerIndent + '\n' + baseIndent;
        // place caret after first newline + innerIndent
        _insertText(insert, caretOffsetFromStart: 1 + innerIndent.length);
        return KeyEventResult.handled;
      }

      // Otherwise, carry indentation and increase if line ends with '{'
      String indent = baseIndent;
      if (linePrefix.trimRight().endsWith('{') || linePrefix.trimRight().endsWith(':')) {
        indent = baseIndent + '    ';
      }
      final insert = '\n' + indent;
      _insertText(insert, caretOffsetFromStart: 1 + indent.length);
      return KeyEventResult.handled;
    }

    // Shift+Tab => unindent
    if (event.logicalKey == LogicalKeyboardKey.tab && event.isShiftPressed) {
      _unindentText();
      return KeyEventResult.handled;
    }

    // Tab insertion
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final sel = _controller.selection;
      if (sel.start != sel.end) {
        _indentText();
      } else {
        _insertText('    ');
      }
      return KeyEventResult.handled;
    }

    // Use character if available
    final char = event.character;
    if (char == null || char.isEmpty) return KeyEventResult.ignored;

    // Auto-dedent when typing '}' at start of a line
    if (char == '}') {
      final sel = _controller.selection;
      final pos = sel.start >= 0 ? sel.start : 0;
      final text = _controller.text;
      final lastNl = pos > 0 ? text.lastIndexOf('\n', pos - 1) : -1;
      final lineStart = lastNl == -1 ? 0 : lastNl + 1;
      int leadingSpaces = 0;
      while (lineStart + leadingSpaces < text.length && leadingSpaces < 4 && text[lineStart + leadingSpaces] == ' ') {
        leadingSpaces++;
      }
      // If caret is at indentation position (right before non-space), dedent then insert '}'
      if (pos == lineStart + leadingSpaces) {
        if (leadingSpaces > 0) {
          final newText = text.replaceRange(lineStart, lineStart + leadingSpaces, '');
          final newPos = (pos - leadingSpaces).clamp(0, newText.length);
          _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newPos));
          _insertText('}');
          return KeyEventResult.handled;
        } else {
          _insertText('}');
          return KeyEventResult.handled;
        }
      }
      // otherwise fallthrough to normal closing char behavior
    }

    const openToClose = {
      '{': '}',
      '[': ']',
      '(': ')',
      '"': '"',
      "'": "'",
    };

    // If typed an opening char, auto-insert pair and place caret between
    if (openToClose.containsKey(char)) {
      final close = openToClose[char]!;
      // If there's a selection, wrap selection with pair
      final sel = _controller.selection;
      if (sel.start != sel.end) {
        final selected = _controller.text.substring(sel.start, sel.end);
        _insertText('$char$selected$close', caretOffsetFromStart: char.length + selected.length);
      } else {
        _insertText('$char$close', caretOffsetFromStart: 1);
      }
      return KeyEventResult.handled;
    }

    // If typed a closing char and next char equals it, skip over instead of inserting duplicate
    if (openToClose.containsValue(char)) {
      final sel = _controller.selection;
      final pos = sel.start;
      final text = _controller.text;
      if (pos < text.length && text[pos] == char) {
        // Move caret forward
        _controller.selection = TextSelection.collapsed(offset: pos + 1);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _unindentText() {
    final sel = _controller.selection;
    final text = _controller.text;

    if (sel.start == sel.end) {
      // Single-line unindent (caret only)
      final pos = sel.start >= 0 ? sel.start : 0;
      final lastNl = pos > 0 ? text.lastIndexOf('\n', pos - 1) : -1;
      final lineStart = lastNl == -1 ? 0 : lastNl + 1;
      int removeCount = 0;
      for (int i = 0; i < 4 && lineStart + i < text.length; i++) {
        if (text[lineStart + i] == ' ') removeCount++; else break;
      }
      if (removeCount > 0) {
        final newText = text.replaceRange(lineStart, lineStart + removeCount, '');
        final newPos = (pos - removeCount).clamp(0, newText.length);
        _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newPos));
      }
    } else {
      // Multi-line unindent for selected block
      int selStart = sel.start;
      int selEnd = sel.end;
      final firstLineStart = selStart > 0 ? text.lastIndexOf('\n', selStart - 1) + 1 : 0;
      final lastLineEndIdx = text.indexOf('\n', selEnd);
      final lastLineEnd = lastLineEndIdx == -1 ? text.length : lastLineEndIdx;

      final block = text.substring(firstLineStart, lastLineEnd);
      final lines = block.split('\n');
      final newLines = <String>[];

      // We'll compute new selection offsets precisely by mapping old offsets to new offsets
      final relativeSelStart = selStart - firstLineStart;
      final relativeSelEnd = selEnd - firstLineStart;
      int accOld = 0; // position within old block
      int accNew = 0; // position within new block
      int? newRelStart;
      int? newRelEnd;

      for (final line in lines) {
        int removed = 0;
        for (int i = 0; i < 4 && i < line.length; i++) {
          if (line[i] == ' ') removed++; else break;
        }
        final newLine = line.substring(removed);
        newLines.add(newLine);

        final oldLineLen = line.length;
        final newLineLen = newLine.length;

        // Check if relativeSelStart lies within this old line
        if (newRelStart == null) {
          if (relativeSelStart <= accOld + oldLineLen) {
            final offsetInLine = (relativeSelStart - accOld).clamp(0, oldLineLen);
            final adjusted = (offsetInLine - removed).clamp(0, newLineLen);
            newRelStart = accNew + adjusted;
          }
        }

        // Check if relativeSelEnd lies within this old line
        if (newRelEnd == null) {
          if (relativeSelEnd <= accOld + oldLineLen) {
            final offsetInLine = (relativeSelEnd - accOld).clamp(0, oldLineLen);
            final adjusted = (offsetInLine - removed).clamp(0, newLineLen);
            newRelEnd = accNew + adjusted;
          }
        }

        // advance accumulators (+1 for newline except maybe after last line)
        accOld += oldLineLen + 1;
        accNew += newLineLen + 1;
      }

      // If selection end falls exactly at end, and wasn't captured because of bounds, set to new block length
      final newBlock = newLines.join('\n');
      final newBlockLen = newBlock.length;
      newRelStart ??= 0;
      newRelEnd ??= newBlockLen;

      final newText = text.replaceRange(firstLineStart, lastLineEnd, newBlock);
      final newSelStart = firstLineStart + newRelStart;
      final newSelEnd = firstLineStart + newRelEnd;
      _controller.value = TextEditingValue(text: newText, selection: TextSelection(baseOffset: newSelStart, extentOffset: newSelEnd));
    }
  }

  void _indentText() {
    final sel = _controller.selection;
    final text = _controller.text;

    // If no selection, behave like Tab insert
    if (sel.start == sel.end) {
      _insertText('    ');
      return;
    }

    final selStart = sel.start;
    final selEnd = sel.end;
    final firstLineStart = selStart > 0 ? text.lastIndexOf('\n', selStart - 1) + 1 : 0;
    final lastLineEndIdx = text.indexOf('\n', selEnd);
    final lastLineEnd = lastLineEndIdx == -1 ? text.length : lastLineEndIdx;

    final block = text.substring(firstLineStart, lastLineEnd);
    final lines = block.split('\n');
    final newLines = <String>[];

    // Compute selection mapping from old block -> new block by accumulating
    final relativeSelStart = selStart - firstLineStart;
    final relativeSelEnd = selEnd - firstLineStart;
    int accOld = 0;
    int accNew = 0;
    int? newRelStart;
    int? newRelEnd;

    for (final line in lines) {
      final newLine = '    ' + line;
      newLines.add(newLine);

      final oldLineLen = line.length;
      final newLineLen = oldLineLen + 4;

      if (newRelStart == null) {
        if (relativeSelStart <= accOld + oldLineLen) {
          final offsetInLine = (relativeSelStart - accOld).clamp(0, oldLineLen);
          final adjusted = (offsetInLine + 4).clamp(0, newLineLen);
          newRelStart = accNew + adjusted;
        }
      }

      if (newRelEnd == null) {
        if (relativeSelEnd <= accOld + oldLineLen) {
          final offsetInLine = (relativeSelEnd - accOld).clamp(0, oldLineLen);
          final adjusted = (offsetInLine + 4).clamp(0, newLineLen);
          newRelEnd = accNew + adjusted;
        }
      }

      accOld += oldLineLen + 1;
      accNew += newLineLen + 1;
    }

    final newBlock = newLines.join('\n');
    final newBlockLen = newBlock.length;
    newRelStart ??= 0;
    newRelEnd ??= newBlockLen;

    final newText = text.replaceRange(firstLineStart, lastLineEnd, newBlock);
    final newSelStart = firstLineStart + newRelStart;
    final newSelEnd = firstLineStart + newRelEnd;
    _controller.value = TextEditingValue(text: newText, selection: TextSelection(baseOffset: newSelStart, extentOffset: newSelEnd));
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    // Try to read theme styles; tests may run without styles loaded, so provide
    // sensible default fallbacks to avoid throwing in widget tests.
    late final LinearGradient bgGradient;
    late final double borderRadius;
    late final double borderWidth;
    late final LinearGradient strokeGradient;
    late final Color textColor;
    late final double fontSize;
    String? closeIcon;
    late final double closeSize;
    late final Color highlightColor;
    try {
      bgGradient = styles.getStyles('farm_page.code_editor.background_color') as LinearGradient;
      borderRadius = styles.getStyles('farm_page.code_editor.border_radius') as double;
      borderWidth = styles.getStyles('farm_page.code_editor.border_width') as double;
      strokeGradient = styles.getStyles('farm_page.code_editor.stroke_color') as LinearGradient;
      textColor = styles.getStyles('farm_page.code_editor.text_style.color') as Color;
      fontSize = styles.getStyles('farm_page.code_editor.text_style.font_size') as double;
      closeIcon = styles.getStyles('farm_page.code_editor.close_button.icon') as String;
      closeSize = styles.getStyles('farm_page.code_editor.close_button.width') as double;
      highlightColor = styles.getStyles('farm_page.code_editor.highlight_line_color') as Color;
    } catch (_) {
      bgGradient = LinearGradient(colors: [Colors.white, Colors.white]);
      borderRadius = 8.0;
      borderWidth = 2.0;
      strokeGradient = LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]);
      textColor = Colors.black;
      fontSize = 14.0;
      closeIcon = null;
      closeSize = 24.0;
      highlightColor = Colors.yellow;
    }

    return Container(
      width: double.infinity,
      height: 500,
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
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Code Editor',
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Mobile/toolbar indent button - inserts 4 spaces at caret
                      IconButton(
                        icon: const Icon(Icons.format_indent_increase),
                        color: textColor,
                        onPressed: _indentText,
                        tooltip: 'Indent (Tab)',
                      ),
                      // Unindent button
                      IconButton(
                        icon: const Icon(Icons.format_indent_decrease),
                        color: textColor,
                        onPressed: _unindentText,
                        tooltip: 'Unindent (Shift+Tab)',
                      ),
                      // Close button: use asset if provided, otherwise fallback to an IconButton
                      if (closeIcon != null && closeIcon.isNotEmpty)
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Image.asset(
                            closeIcon,
                            width: closeSize,
                            height: closeSize,
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: textColor,
                          onPressed: widget.onClose,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Code area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: LayoutBuilder(builder: (context, constraints) {
                  final textStyle = TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                  );
                  final tp = TextPainter(
                    text: TextSpan(text: 'M', style: textStyle),
                    textDirection: TextDirection.ltr,
                  )..layout();
                  final lineHeight = tp.height;

                  return Stack(
                    children: [
                      if (_highlightLine != null) ...[
                        // compute top offset inside the padded area
                        Positioned(
                          top: ((_highlightLine! - 1) * lineHeight) -
                              (_scrollController.hasClients ? _scrollController.offset : 0.0),
                          left: 0,
                          right: 0,
                          height: lineHeight,
                          child: IgnorePointer(
                            child: Container(
                              color: highlightColor.withOpacity(0.18),
                            ),
                          ),
                        ),
                      ],
                      Focus(
                        onKey: _handleKey,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              selectionColor: highlightColor,
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            scrollController: _scrollController,
                            maxLines: null,
                            expands: true,
                            style: textStyle,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '// Write your code here...',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
