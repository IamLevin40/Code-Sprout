import '../models/farm_data.dart';
import '../models/research_data.dart';
import '../compilers/base_interpreter.dart';
import '../compilers/cpp_interpreter.dart';
import '../compilers/csharp_interpreter.dart';
import '../compilers/java_interpreter.dart';
import '../compilers/python_interpreter.dart';
import '../compilers/javascript_interpreter.dart';

/// Factory for creating language-specific code interpreters
class InterpreterFactory {
  /// Get the appropriate interpreter for the given language
  static FarmCodeInterpreter getInterpreter({
    required String languageId,
    required FarmState farmState,
    required ResearchState researchState,
    required Future<void> Function(CropType) onCropHarvested,
    required void Function(int?) onLineExecuting,
    required void Function(int?, bool) onLineError,
    required void Function(String) onLogUpdate,
    required bool mounted,
  }) {
    switch (languageId) {
      case 'cpp':
        return CppInterpreter(
          farmState: farmState,
          onCropHarvested: onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) onLineExecuting(line);
          },
          onLineError: (line, isError) {
            if (mounted) onLineError(line, isError);
          },
          onLogUpdate: (message) {
            if (mounted) onLogUpdate(message);
          },
          researchState: researchState,
        );
      case 'csharp':
        return CSharpInterpreter(
          farmState: farmState,
          onCropHarvested: onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) onLineExecuting(line);
          },
          onLineError: (line, isError) {
            if (mounted) onLineError(line, isError);
          },
          onLogUpdate: (message) {
            if (mounted) onLogUpdate(message);
          },
          researchState: researchState,
        );
      case 'java':
        return JavaInterpreter(
          farmState: farmState,
          onCropHarvested: onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) onLineExecuting(line);
          },
          onLineError: (line, isError) {
            if (mounted) onLineError(line, isError);
          },
          onLogUpdate: (message) {
            if (mounted) onLogUpdate(message);
          },
          researchState: researchState,
        );
      case 'python':
        return PythonInterpreter(
          farmState: farmState,
          onCropHarvested: onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) onLineExecuting(line);
          },
          onLineError: (line, isError) {
            if (mounted) onLineError(line, isError);
          },
          onLogUpdate: (message) {
            if (mounted) onLogUpdate(message);
          },
          researchState: researchState,
        );
      case 'javascript':
        return JavaScriptInterpreter(
          farmState: farmState,
          onCropHarvested: onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) onLineExecuting(line);
          },
          onLineError: (line, isError) {
            if (mounted) onLineError(line, isError);
          },
          onLogUpdate: (message) {
            if (mounted) onLogUpdate(message);
          },
          researchState: researchState,
        );
      default:
        return CppInterpreter(
          farmState: farmState,
          onCropHarvested: onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) onLineExecuting(line);
          },
          onLineError: (line, isError) {
            if (mounted) onLineError(line, isError);
          },
          onLogUpdate: (message) {
            if (mounted) onLogUpdate(message);
          },
        );
    }
  }
}
