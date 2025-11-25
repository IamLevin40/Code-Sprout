import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handler for code editing operations in the code editor
/// Provides utilities for text manipulation, indentation, and key handling
class CodeEditingHandler {
  /// Handle executing line changes from external notifier
  static void onExecutingLineChanged({
    required ValueNotifier<int?> executingLineNotifier,
    required Function(int?) setHighlightLine,
  }) {
    final line = executingLineNotifier.value; // 1-based index or null
    setHighlightLine(line);
  }

  /// Handle error line changes from external notifier
  static void onErrorLineChanged({
    required ValueNotifier<int?> errorLineNotifier,
    required Function(int?) setErrorLine,
  }) {
    final line = errorLineNotifier.value; // 1-based index or null
    setErrorLine(line);
  }

  /// Insert text at current selection and place caret at optional caretOffset
  static void insertText({
    required TextEditingController controller,
    required String insert,
    int? caretOffsetFromStart,
  }) {
    final text = controller.text;
    final sel = controller.selection;
    final start = sel.start >= 0 ? sel.start : 0;
    final end = sel.end >= 0 ? sel.end : 0;
    final newText = text.replaceRange(start, end, insert);
    final caret = (caretOffsetFromStart != null)
        ? start + caretOffsetFromStart
        : start + insert.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// Handle key events for smart editing features
  static KeyEventResult handleKey({
    required FocusNode node,
    required KeyEvent event,
    required TextEditingController controller,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Enter / Return => smart auto-indent
    if (event.logicalKey == LogicalKeyboardKey.enter || 
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final sel = controller.selection;
      final pos = sel.start >= 0 ? sel.start : 0;
      final text = controller.text;

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
        final indent = baseIndent + '    ';
        final insert = '\n$indent\n$baseIndent';
        insertText(
          controller: controller,
          insert: insert,
          caretOffsetFromStart: 1 + indent.length,
        );
        return KeyEventResult.handled;
      }

      // Otherwise, carry indentation and increase if line ends with '{'
      String indent = baseIndent;
      if (linePrefix.trimRight().endsWith('{') || linePrefix.trimRight().endsWith(':')) {
        indent = '$baseIndent    ';
      }
      final insert = '\n$indent';
      insertText(
        controller: controller,
        insert: insert,
        caretOffsetFromStart: 1 + indent.length,
      );
      return KeyEventResult.handled;
    }

    // Shift+Tab => unindent
    if (event.logicalKey == LogicalKeyboardKey.tab && 
        HardwareKeyboard.instance.isShiftPressed) {
      CodeEditingHandler.unindentText(controller: controller);
      return KeyEventResult.handled;
    }

    // Tab insertion
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final sel = controller.selection;
      if (sel.start != sel.end) {
        CodeEditingHandler.indentText(controller: controller);
      } else {
        CodeEditingHandler.insertText(controller: controller, insert: '    ');
      }
      return KeyEventResult.handled;
    }

    // Use character if available
    final char = event.character;
    if (char == null || char.isEmpty) return KeyEventResult.ignored;

    // Auto-dedent when typing '}' at start of a line
    if (char == '}') {
      final sel = controller.selection;
      final pos = sel.start >= 0 ? sel.start : 0;
      final text = controller.text;
      final lastNl = pos > 0 ? text.lastIndexOf('\n', pos - 1) : -1;
      final lineStart = lastNl == -1 ? 0 : lastNl + 1;
      int leadingSpaces = 0;
      while (lineStart + leadingSpaces < text.length && 
             leadingSpaces < 4 && 
             text[lineStart + leadingSpaces] == ' ') {
        leadingSpaces++;
      }
      // If caret is at indentation position (right before non-space), dedent then insert '}'
      if (pos == lineStart + leadingSpaces) {
        if (leadingSpaces > 0) {
          final newText = text.replaceRange(lineStart, lineStart + leadingSpaces, '');
          final newPos = pos - leadingSpaces;
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newPos),
          );
          CodeEditingHandler.insertText(controller: controller, insert: '}');
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
      final sel = controller.selection;
      if (sel.start != sel.end) {
        final selected = controller.text.substring(sel.start, sel.end);
        CodeEditingHandler.insertText(
          controller: controller,
          insert: '$char$selected$close',
          caretOffsetFromStart: char.length + selected.length,
        );
      } else {
        CodeEditingHandler.insertText(controller: controller, insert: '$char$close', caretOffsetFromStart: 1);
      }
      return KeyEventResult.handled;
    }

    // If typed a closing char and next char equals it, skip over instead of inserting duplicate
    if (openToClose.containsValue(char)) {
      final sel = controller.selection;
      final pos = sel.start;
      final text = controller.text;
      if (pos < text.length && text[pos] == char) {
        controller.selection = TextSelection.collapsed(offset: pos + 1);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// Unindent selected text or current line
  static void unindentText({required TextEditingController controller}) {
    final sel = controller.selection;
    final text = controller.text;

    if (sel.start == sel.end) {
      // Single-line unindent (caret only)
      final pos = sel.start >= 0 ? sel.start : 0;
      final lastNl = pos > 0 ? text.lastIndexOf('\n', pos - 1) : -1;
      final lineStart = lastNl == -1 ? 0 : lastNl + 1;
      int removeCount = 0;
      for (int i = 0; i < 4 && lineStart + i < text.length; i++) {
        if (text[lineStart + i] == ' ') {
          removeCount++;
        } else {
          break;
        }
      }
      if (removeCount > 0) {
        final newText = text.replaceRange(lineStart, lineStart + removeCount, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pos - removeCount),
        );
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
        int removeCount = 0;
        for (int i = 0; i < 4 && i < line.length; i++) {
          if (line[i] == ' ') {
            removeCount++;
          } else {
            break;
          }
        }
        final newLine = line.substring(removeCount);

        // Check if selection start falls in this line
        if (newRelStart == null && accOld <= relativeSelStart && relativeSelStart < accOld + line.length + 1) {
          final offset = relativeSelStart - accOld;
          final newOffset = offset > removeCount ? offset - removeCount : 0;
          newRelStart = accNew + newOffset;
        }

        // Check if selection end falls in this line
        if (newRelEnd == null && accOld <= relativeSelEnd && relativeSelEnd < accOld + line.length + 1) {
          final offset = relativeSelEnd - accOld;
          final newOffset = offset > removeCount ? offset - removeCount : 0;
          newRelEnd = accNew + newOffset;
        }

        newLines.add(newLine);
        accOld += line.length + 1; // +1 for newline
        accNew += newLine.length + 1;
      }

      // If selection end falls exactly at end, and wasn't captured because of bounds, set to new block length
      final newBlock = newLines.join('\n');
      final newBlockLen = newBlock.length;
      newRelStart ??= 0;
      newRelEnd ??= newBlockLen;

      final newText = text.replaceRange(firstLineStart, lastLineEnd, newBlock);
      final newSelStart = firstLineStart + newRelStart;
      final newSelEnd = firstLineStart + newRelEnd;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(baseOffset: newSelStart, extentOffset: newSelEnd),
      );
    }
  }

  /// Indent selected text or insert tab at cursor
  static void indentText({required TextEditingController controller}) {
    final sel = controller.selection;
    final text = controller.text;

    // If no selection, behave like Tab insert
    if (sel.start == sel.end) {
      insertText(controller: controller, insert: '    ');
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
      final newLine = '    $line';

      // Check if selection start falls in this line
      if (newRelStart == null && accOld <= relativeSelStart && relativeSelStart < accOld + line.length + 1) {
        final offset = relativeSelStart - accOld;
        newRelStart = accNew + 4 + offset;
      }

      // Check if selection end falls in this line
      if (newRelEnd == null && accOld <= relativeSelEnd && relativeSelEnd < accOld + line.length + 1) {
        final offset = relativeSelEnd - accOld;
        newRelEnd = accNew + 4 + offset;
      }

      newLines.add(newLine);
      accOld += line.length + 1;
      accNew += newLine.length + 1;
    }

    final newBlock = newLines.join('\n');
    final newBlockLen = newBlock.length;
    newRelStart ??= 0;
    newRelEnd ??= newBlockLen;

    final newText = text.replaceRange(firstLineStart, lastLineEnd, newBlock);
    final newSelStart = firstLineStart + newRelStart;
    final newSelEnd = firstLineStart + newRelEnd;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newSelStart, extentOffset: newSelEnd),
    );
  }
}
