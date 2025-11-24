import 'package:flutter/material.dart';
import '../models/farm_data.dart';
import '../models/language_code_files.dart';
import '../compilers/base_interpreter.dart';

/// Handles code execution operations and related UI state
class CodeExecutionHandler {
  /// Run code execution
  static Future<void> runExecution({
    required BuildContext context,
    required bool isExecuting,
    required bool mounted,
    required FarmState farmState,
    required LanguageCodeFiles codeFiles,
    required int selectedExecutionFileIndex,
    required FarmCodeInterpreter interpreter,
    required ValueNotifier<int?> executingLineNotifier,
    required ValueNotifier<int?> errorLineNotifier,
    required ValueNotifier<List<String>> logNotifier,
    required Function(bool) setIsExecuting,
    required Function(bool) setAutoScrollEnabled,
    required Function(bool) setShowExecutionLog,
    required Function(List<String>) setExecutionLog,
    required Function(FarmCodeInterpreter?) setCurrentInterpreter,
  }) async {
    if (isExecuting) return;
    
    if (!mounted) return;
    
    setIsExecuting(true);
    setExecutionLog([]);
    logNotifier.value = [];
    executingLineNotifier.value = null;
    errorLineNotifier.value = null;
    farmState.setExecuting(true);
    setAutoScrollEnabled(true); // Reset auto-scroll to enabled

    setCurrentInterpreter(interpreter);
    
    try {
      // Get code from selected execution file
      final codeToExecute = codeFiles.files[selectedExecutionFileIndex].content;
      
      // Pre-validate code for errors
      final validationResult = await interpreter.preValidate(codeToExecute);
      
      // Check if stopped during validation
      if (!mounted || interpreter.shouldStop) {
        cleanupExecution(
          mounted: mounted,
          setIsExecuting: setIsExecuting,
          farmState: farmState,
          setShowExecutionLog: setShowExecutionLog,
          executingLineNotifier: executingLineNotifier,
          setCurrentInterpreter: setCurrentInterpreter,
        );
        return;
      }
      
      if (validationResult != null && !validationResult.success) {
        // Validation failed - show error and stop
        if (mounted) {
          setIsExecuting(false);
          setExecutionLog(validationResult.executionLog);
          logNotifier.value = List.from(validationResult.executionLog);
          farmState.setExecuting(false);
          // REMOVED: setShowExecutionLog(false) - Keep log visible on validation failure
          if (validationResult.errorLine != null) {
            errorLineNotifier.value = validationResult.errorLine;
          }
          
          if (validationResult.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(validationResult.errorMessage!)),
            );
          }
        }
        setCurrentInterpreter(null);
        return;
      }

      // Execute code
      final result = await interpreter.execute(codeToExecute);

      // Check if stopped or widget disposed during execution
      if (!mounted || interpreter.shouldStop) {
        cleanupExecution(
          mounted: mounted,
          setIsExecuting: setIsExecuting,
          farmState: farmState,
          setShowExecutionLog: setShowExecutionLog,
          executingLineNotifier: executingLineNotifier,
          setCurrentInterpreter: setCurrentInterpreter,
        );
        return;
      }

      if (mounted) {
        setIsExecuting(false);
        setExecutionLog(result.executionLog);
        logNotifier.value = List.from(result.executionLog);
        farmState.setExecuting(false);
        // REMOVED: setShowExecutionLog(false) - Keep log visible after execution
        executingLineNotifier.value = null; // Clear line highlighting
        if (result.errorLine != null) {
          errorLineNotifier.value = result.errorLine;
        }

        if (!result.success && result.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage!)),
          );
        }
      }
    } catch (e) {
      // Handle any unexpected errors during execution
      if (mounted) {
        setIsExecuting(false);
        farmState.setExecuting(false);
        // REMOVED: setShowExecutionLog(false) - Keep log visible on error
        executingLineNotifier.value = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Execution error: $e')),
        );
      }
    } finally {
      setCurrentInterpreter(null);
    }
  }
  
  /// Cleanup execution state
  static void cleanupExecution({
    required bool mounted,
    required Function(bool) setIsExecuting,
    required FarmState farmState,
    required Function(bool) setShowExecutionLog,
    required ValueNotifier<int?> executingLineNotifier,
    required Function(FarmCodeInterpreter?) setCurrentInterpreter,
  }) {
    if (mounted) {
      setIsExecuting(false);
      farmState.setExecuting(false);
      // REMOVED: setShowExecutionLog(false) - Keep log visible on cleanup
      executingLineNotifier.value = null;
    }
    setCurrentInterpreter(null);
  }

  /// Stop code execution
  /// NOTE: Log visibility is NOT changed here - log stays open if user had it open
  /// Log is only cleared when starting a new execution
  static void stopExecution({
    required FarmCodeInterpreter? currentInterpreter,
    required bool mounted,
    required Function(bool) setIsExecuting,
    required FarmState farmState,
    required ValueNotifier<int?> executingLineNotifier,
    required Function(bool) setShowExecutionLog,
  }) {
    if (currentInterpreter != null) {
      currentInterpreter.stop();
    }
    
    // Use a small delay to allow async operations to complete
    Future.microtask(() {
      if (mounted) {
        setIsExecuting(false);
        farmState.setExecuting(false);
        executingLineNotifier.value = null;
        // REMOVED: setShowExecutionLog(false) - Keep log visible after stop
      }
    });
  }

  /// Navigate to next execution file
  static void nextExecutionFile({
    required int currentIndex,
    required LanguageCodeFiles codeFiles,
    required Function(int) setSelectedExecutionFileIndex,
  }) {
    setSelectedExecutionFileIndex((currentIndex + 1) % codeFiles.files.length);
  }
  
  /// Navigate to previous execution file
  static void previousExecutionFile({
    required int currentIndex,
    required LanguageCodeFiles codeFiles,
    required Function(int) setSelectedExecutionFileIndex,
  }) {
    setSelectedExecutionFileIndex((currentIndex - 1 + codeFiles.files.length) % codeFiles.files.length);
  }

  /// Handle log scroll to manage auto-scroll behavior
  static void onLogScroll({
    required ScrollController logScrollController,
    required bool autoScrollEnabled,
    required Function(bool) setAutoScrollEnabled,
  }) {
    if (!logScrollController.hasClients) return;
    
    // Check if user is at the bottom (within 50 pixels)
    final maxScroll = logScrollController.position.maxScrollExtent;
    final currentScroll = logScrollController.position.pixels;
    final isAtBottom = maxScroll - currentScroll < 50;
    
    // Enable auto-scroll when at bottom, disable when scrolling up
    if (isAtBottom && !autoScrollEnabled) {
      setAutoScrollEnabled(true);
    } else if (!isAtBottom && autoScrollEnabled) {
      setAutoScrollEnabled(false);
    }
  }
}
