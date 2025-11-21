import 'package:flutter/material.dart';
import '../models/farm_data.dart';
import '../models/styles_schema.dart';
import '../models/language_code_files.dart';
import '../models/user_data.dart';
import '../models/sprout_data.dart';
import '../models/farm_data_schema.dart';
import '../widgets/farm_items/farm_grid_view.dart';
import '../widgets/farm_items/code_editor_widget.dart';
import '../compilers/base_interpreter.dart';
import '../compilers/cpp_interpreter.dart';
import '../compilers/csharp_interpreter.dart';
import '../compilers/java_interpreter.dart';
import '../compilers/python_interpreter.dart';
import '../compilers/javascript_interpreter.dart';
import '../services/local_storage_service.dart';
import '../services/code_files_service.dart';
import '../miscellaneous/glass_effect.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  late LanguageCodeFiles _codeFiles;
  int _selectedExecutionFileIndex = 0; // File selected in start button
  List<String> _executionLog = [];
  bool _isExecuting = false;
  final ValueNotifier<int?> _executingLineNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _errorLineNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<List<String>> _logNotifier = ValueNotifier<List<String>>([]);
  FarmCodeInterpreter? _currentInterpreter;
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _farmState = FarmState();
    _codeFiles = LanguageCodeFiles.createDefault(widget.languageId);
    _codeController = TextEditingController(text: _codeFiles.currentFile.content);
    _farmState.addListener(_onFarmStateChanged);
    // initialize farm state with cached user data and keep in sync
    try {
      final ud = LocalStorageService.instance.userDataNotifier.value;
      if (ud != null) _farmState.setUserData(ud);
      LocalStorageService.instance.userDataNotifier.addListener(() {
        _farmState.setUserData(LocalStorageService.instance.userDataNotifier.value);
      });
    } catch (_) {}
    
    // Load code files from Firestore
    _loadCodeFiles();
  }
  
  Future<void> _loadCodeFiles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      
      final loadedFiles = await CodeFilesService.loadOrCreateCodeFiles(
        userId: user.uid,
        languageId: widget.languageId,
      );
      
      if (mounted) {
        setState(() {
          _codeFiles = loadedFiles;
          _selectedExecutionFileIndex = _codeFiles.currentFileIndex;
          _codeController.text = _codeFiles.currentFile.content;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load code files: $e')),
        );
      }
    }
  }
  
  Future<void> _saveCodeFiles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Update current file content before saving
      _codeFiles.updateCurrentFileContent(_codeController.text);
      
      await CodeFilesService.saveCodeFiles(
        userId: user.uid,
        languageId: widget.languageId,
        codeFiles: _codeFiles,
      );
    } catch (e) {
      // Silent fail - don't interrupt user experience
    }
  }

  @override
  void dispose() {
    // Stop any running execution before disposal
    if (_isExecuting && _currentInterpreter != null) {
      _currentInterpreter!.stop();
    }
    _farmState.removeListener(_onFarmStateChanged);
    _farmState.dispose();
    _executingLineNotifier.dispose();
    _errorLineNotifier.dispose();
    _logNotifier.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onFarmStateChanged() {
    if (mounted) setState(() {});
  }

  FarmCodeInterpreter _getInterpreter() {
    switch (widget.languageId) {
      case 'cpp':
        return CppInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) _executingLineNotifier.value = line;
          },
          onLineError: (line, isError) {
            if (mounted) _errorLineNotifier.value = isError ? line : null;
          },
          onLogUpdate: (message) {
            if (mounted) {
              _logNotifier.value = List.from(_logNotifier.value)..add(message);
            }
          },
        );
      case 'csharp':
        return CSharpInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) _executingLineNotifier.value = line;
          },
          onLineError: (line, isError) {
            if (mounted) _errorLineNotifier.value = isError ? line : null;
          },
          onLogUpdate: (message) {
            if (mounted) {
              _logNotifier.value = List.from(_logNotifier.value)..add(message);
            }
          },
        );
      case 'java':
        return JavaInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) _executingLineNotifier.value = line;
          },
          onLineError: (line, isError) {
            if (mounted) _errorLineNotifier.value = isError ? line : null;
          },
          onLogUpdate: (message) {
            if (mounted) {
              _logNotifier.value = List.from(_logNotifier.value)..add(message);
            }
          },
        );
      case 'python':
        return PythonInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) _executingLineNotifier.value = line;
          },
          onLineError: (line, isError) {
            if (mounted) _errorLineNotifier.value = isError ? line : null;
          },
          onLogUpdate: (message) {
            if (mounted) {
              _logNotifier.value = List.from(_logNotifier.value)..add(message);
            }
          },
        );
      case 'javascript':
        return JavaScriptInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) _executingLineNotifier.value = line;
          },
          onLineError: (line, isError) {
            if (mounted) _errorLineNotifier.value = isError ? line : null;
          },
          onLogUpdate: (message) {
            if (mounted) {
              _logNotifier.value = List.from(_logNotifier.value)..add(message);
            }
          },
        );
      default:
        return CppInterpreter(
          farmState: _farmState,
          onCropHarvested: _onCropHarvested,
          onLineExecuting: (line) {
            if (mounted) _executingLineNotifier.value = line;
          },
          onLineError: (line, isError) {
            if (mounted) _errorLineNotifier.value = isError ? line : null;
          },
          onLogUpdate: (message) {
            if (mounted) {
              _logNotifier.value = List.from(_logNotifier.value)..add(message);
            }
          },
        );
    }
  }

  Future<void> _onCropHarvested(CropType cropType) async {
    // Persistence is handled by FarmState; ensure local notifier is in sync.
    try {
      final ud = LocalStorageService.instance.userDataNotifier.value;
      if (ud != null) _farmState.setUserData(ud);
    } catch (_) {}
  }

  Future<void> _startExecution() async {
    if (_isExecuting) return;
    
    if (!mounted) return;
    
    setState(() {
      _isExecuting = true;
      _executionLog.clear();
      _logNotifier.value = [];
      _executingLineNotifier.value = null;
      _errorLineNotifier.value = null;
      _farmState.setExecuting(true);
    });

    final interpreter = _getInterpreter();
    _currentInterpreter = interpreter;
    
    try {
      // Get code from selected execution file
      final codeToExecute = _codeFiles.files[_selectedExecutionFileIndex].content;
      
      // Pre-validate code for errors
      final validationResult = await interpreter.preValidate(codeToExecute);
      
      // Check if stopped during validation
      if (!mounted || interpreter.shouldStop) {
        _cleanupExecution();
        return;
      }
      
      if (validationResult != null && !validationResult.success) {
        // Validation failed - show error and stop
        if (mounted) {
          setState(() {
            _isExecuting = false;
            _executionLog = validationResult.executionLog;
            _logNotifier.value = List.from(validationResult.executionLog);
            _farmState.setExecuting(false);
            if (validationResult.errorLine != null) {
              _errorLineNotifier.value = validationResult.errorLine;
            }
          });
          
          if (validationResult.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(validationResult.errorMessage!)),
            );
          }
        }
        _currentInterpreter = null;
        return;
      }

      // Execute code
      final result = await interpreter.execute(codeToExecute);

      // Check if stopped or widget disposed during execution
      if (!mounted || interpreter.shouldStop) {
        _cleanupExecution();
        return;
      }

      if (mounted) {
        setState(() {
          _isExecuting = false;
          _executionLog = result.executionLog;
          _logNotifier.value = List.from(result.executionLog);
          _farmState.setExecuting(false);
          _executingLineNotifier.value = null; // Clear line highlighting
          if (result.errorLine != null) {
            _errorLineNotifier.value = result.errorLine;
          }
        });

        if (!result.success && result.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage!)),
          );
        }
      }
    } catch (e) {
      // Handle any unexpected errors during execution
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _farmState.setExecuting(false);
          _executingLineNotifier.value = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Execution error: $e')),
        );
      }
    } finally {
      _currentInterpreter = null;
    }
  }
  
  void _cleanupExecution() {
    if (mounted) {
      setState(() {
        _isExecuting = false;
        _farmState.setExecuting(false);
        _executingLineNotifier.value = null;
      });
    }
    _currentInterpreter = null;
  }

  void _stopExecution() {
    if (_currentInterpreter != null) {
      _currentInterpreter!.stop();
    }
    
    // Use a small delay to allow async operations to complete
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _farmState.setExecuting(false);
          _executingLineNotifier.value = null;
        });
      }
    });
  }
  
  // File navigation methods for code editor
  void _nextEditorFile() {
    if (_isExecuting) return;
    
    // Save current file content before switching
    _codeFiles.updateCurrentFileContent(_codeController.text);
    
    _codeFiles.nextFile();
    _codeController.text = _codeFiles.currentFile.content;
    setState(() {});
    
    _saveCodeFiles();
  }
  
  void _previousEditorFile() {
    if (_isExecuting) return;
    
    // Save current file content before switching
    _codeFiles.updateCurrentFileContent(_codeController.text);
    
    _codeFiles.previousFile();
    _codeController.text = _codeFiles.currentFile.content;
    setState(() {});
    
    _saveCodeFiles();
  }
  
  // File navigation methods for execution file selector
  void _nextExecutionFile() {
    setState(() {
      _selectedExecutionFileIndex = (_selectedExecutionFileIndex + 1) % _codeFiles.files.length;
    });
  }
  
  void _previousExecutionFile() {
    setState(() {
      _selectedExecutionFileIndex = (_selectedExecutionFileIndex - 1 + _codeFiles.files.length) % _codeFiles.files.length;
    });
  }
  
  // Add new file
  void _showAddFileDialog() {
    if (_isExecuting) return;
    
    final TextEditingController fileNameController = TextEditingController();
    final extension = LanguageCodeFiles.getFileExtension(widget.languageId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New File'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: fileNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter file name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (_) => _createFile(fileNameController.text + extension, context),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              extension,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createFile(fileNameController.text + extension, context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _createFile(String fileName, BuildContext dialogContext) {
    final error = _codeFiles.addFile(fileName);
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.pop(dialogContext);
      _codeController.text = _codeFiles.currentFile.content;
      setState(() {});
      _saveCodeFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File "$fileName" created')),
      );
    }
  }
  
  // Delete current file
  void _deleteCurrentFile() {
    if (_isExecuting) return;
    
    if (_codeFiles.files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only file')),
      );
      return;
    }
    
    final fileName = _codeFiles.currentFileName;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              final success = _codeFiles.deleteCurrentFile();
              
              if (success) {
                // Adjust execution file index if needed
                if (_selectedExecutionFileIndex >= _codeFiles.files.length) {
                  _selectedExecutionFileIndex = _codeFiles.files.length - 1;
                }
                
                _codeController.text = _codeFiles.currentFile.content;
                setState(() {});
                _saveCodeFiles();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File "$fileName" deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  // Handle code changes
  void _onCodeChanged(String code) {
    _codeFiles.updateCurrentFileContent(code);
    // Auto-save periodically (debounced in real implementation)
    _saveCodeFiles();
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final bgGradient = styles.getStyles('farm_page.background_color') as LinearGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Layer 1: Farm Grid View (Bottom Layer - Centered)
              _buildFarmGridLayer(styles),
              
              // Layer 2: Top Bar and Control Buttons
              _buildControlLayer(styles),
              
              // Layer 3: Execution Log Overlay (Only shown when executing)
              if (_isExecuting) _buildExecutionLogOverlay(styles),
              
              // Layer 4: Code Editor Overlay (Only shown when code button pressed)
              if (_showCodeEditor) _buildCodeEditorOverlay(styles),
            ],
          ),
        ),
      ),
    );
  }
  
  // Layer 1: Centered Farm Grid
  Widget _buildFarmGridLayer(AppStyles styles) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
          child: FarmGridView(farmState: _farmState),
        ),
      ),
    );
  }
  
  // Layer 2: Top Bar and Control Buttons
  Widget _buildControlLayer(AppStyles styles) {
    return Padding(
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
          
          const Spacer(),
          
          // Top control: Start button with file selector
          if (!_isExecuting) _buildStartButtonWithFileSelector(styles),
          if (_isExecuting) _buildStopButton(styles),
          
          const SizedBox(height: 8),
          
          // Bottom controls: Code, Inventory, Research buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildCodeButton(styles)),
              const SizedBox(width: 8),
              Expanded(child: _buildInventoryButton(styles)),
              const SizedBox(width: 8),
              Expanded(child: _buildResearchButton(styles)),
            ],
          ),
        ],
      ),
    );
  }
  
  // Layer 3: Execution Log Overlay
  Widget _buildExecutionLogOverlay(AppStyles styles) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      height: 200,
      child: _buildExecutionLog(styles),
    );
  }
  
  // Layer 4: Code Editor Overlay
  Widget _buildCodeEditorOverlay(AppStyles styles) {
    return Positioned(
      left: 16,
      right: 16,
      top: 64,
      bottom: 16,
      child: _buildCodeEditorWithFileSelector(styles),
    );
  }

  Widget _buildBackButton(AppStyles styles) {
    final icon = styles.getStyles('farm_page.back_button.icon') as String;
    final size = styles.getStyles('farm_page.back_button.width') as double;
    final bgColor = styles.getStyles('farm_page.back_button.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.back_button.border_radius') as double;

    return GestureDetector(
      onTap: () {
        // Stop execution if running before navigating back
        if (_isExecuting && _currentInterpreter != null) {
          _currentInterpreter!.stop();
          _farmState.setExecuting(false);
        }
        Navigator.of(context).pop();
      },
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
      label: 'Drone Code',
      styleKey: 'farm_page.control_buttons.code_button',
      icon: Icons.code,
      onTap: () {
        setState(() => _showCodeEditor = !_showCodeEditor);
      },
    );
  }
  
  Widget _buildInventoryButton(AppStyles styles) {
    return _buildControlButton(
      styles: styles,
      label: 'Inventory',
      styleKey: 'farm_page.control_buttons.start_button', // Reuse start button style
      icon: Icons.inventory_2,
      onTap: _showInventoryPopup,
    );
  }
  
  Widget _buildResearchButton(AppStyles styles) {
    return _buildControlButton(
      styles: styles,
      label: 'Research',
      styleKey: 'farm_page.control_buttons.code_button', // Reuse code button style
      icon: Icons.menu_book,
      onTap: () {
        // TODO: Navigate to research page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Research page coming soon!')),
        );
      },
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
    IconData? icon,
  }) {
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
          child: icon != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor, size: fontSize * 1.5),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(color: textColor, fontSize: fontSize * 0.8, fontWeight: fontWeight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
                ),
        ),
      ),
    );
  }

  void _showInventoryPopup() {
    showDialog(
      context: context,
      builder: (context) => _InventoryPopupDialog(userData: LocalStorageService.instance.userDataNotifier.value),
    );
  }

  Widget _buildStartButtonWithFileSelector(AppStyles styles) {
    return Column(
      children: [
        // File selector for execution
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left, color: Colors.black),
              onPressed: _previousExecutionFile,
              iconSize: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 102, 87, 87).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _codeFiles.files[_selectedExecutionFileIndex].fileName,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, color: Colors.black),
              onPressed: _nextExecutionFile,
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildControlButton(
          styles: styles,
          label: 'Start',
          styleKey: 'farm_page.control_buttons.start_button',
          onTap: _startExecution,
        ),
      ],
    );
  }

  Widget _buildCodeEditorWithFileSelector(AppStyles styles) {
    return Column(
      children: [
        // File management toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 102, 87, 87).withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              // Add file button
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: _showAddFileDialog,
                iconSize: 20,
                tooltip: 'Add File',
              ),
              // Delete file button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.black),
                onPressed: _codeFiles.files.length > 1 ? _deleteCurrentFile : null,
                iconSize: 20,
                tooltip: 'Delete File',
              ),
              const SizedBox(width: 8),
              // File selector
              IconButton(
                icon: const Icon(Icons.arrow_left, color: Colors.black),
                onPressed: _previousEditorFile,
                iconSize: 20,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 102, 87, 87).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _codeFiles.currentFileName,
                    style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, color: Colors.black),
                onPressed: _nextEditorFile,
                iconSize: 20,
              ),
            ],
          ),
        ),
        // Code editor
        Expanded(
          child: CodeEditorWidget(
            initialCode: _codeFiles.currentFile.content,
            onCodeChanged: _onCodeChanged,
            onClose: () {
              setState(() => _showCodeEditor = false);
            },
            controller: _codeController,
            executingLineNotifier: _executingLineNotifier,
            errorLineNotifier: _errorLineNotifier,
            isReadOnly: _isExecuting,
          ),
        ),
      ],
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
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _logNotifier,
                builder: (context, logs, _) {
                  return SingleChildScrollView(
                    child: Text(
                      logs.isEmpty ? 'No execution yet...' : logs.join('\n'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inventory Popup Dialog Widget
class _InventoryPopupDialog extends StatefulWidget {
  final UserData? userData;

  const _InventoryPopupDialog({required this.userData});

  @override
  State<_InventoryPopupDialog> createState() => _InventoryPopupDialogState();
}

class _InventoryPopupDialogState extends State<_InventoryPopupDialog> {
  List<InventoryItem> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final items = await SproutDataHelpers.getInventoryItemsForUser(widget.userData);
    if (mounted) {
      setState(() => _inventoryItems = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final pickerHeight = styles.getStyles('sprout_page.language_selection.height') as double;
    final pickerRadius = styles.getStyles('sprout_page.language_selection.border_radius') as double;
    final pickerBg = styles.getStyles('sprout_page.language_selection.background_color') as Color;

    final titleColor = styles.getStyles('sprout_page.language_selection.title.color') as Color;
    final titleSize = styles.getStyles('sprout_page.language_selection.title.font_size') as double;
    final titleWeight = styles.getStyles('sprout_page.language_selection.title.font_weight') as FontWeight;

    final closeIcon = styles.getStyles('sprout_page.language_selection.close_button.icon') as String;
    final closeW = styles.getStyles('sprout_page.language_selection.close_button.width') as double;
    final closeH = styles.getStyles('sprout_page.language_selection.close_button.height') as double;

    final farmSchema = FarmDataSchema();
    final lockedIconImage = styles.getStyles('sprout_researches.locked_overlay.icon.image') as String;

    final cardHeight = styles.getStyles('sprout_page.inventory.card.height') as double;
    final cardBorderRadius = styles.getStyles('sprout_page.inventory.card.border_radius') as double;
    final cardBorderWidth = styles.getStyles('sprout_page.inventory.card.border_width') as double;
    final cardBg = styles.getStyles('sprout_page.inventory.card.background_color') as LinearGradient;
    final cardStroke = styles.getStyles('sprout_page.inventory.card.stroke_color') as LinearGradient;

    final iconWidth = styles.getStyles('sprout_page.inventory.card.icon.width') as double;
    final iconHeight = styles.getStyles('sprout_page.inventory.card.icon.height') as double;

    final cropLabelColor = styles.getStyles('sprout_page.inventory.card.crop_label.color') as Color;
    final cropLabelSize = styles.getStyles('sprout_page.inventory.card.crop_label.font_size') as double;
    final cropLabelWeight = styles.getStyles('sprout_page.inventory.card.crop_label.font_weight') as FontWeight;

    final quantityColor = styles.getStyles('sprout_page.inventory.card.quantity_label.color') as Color;
    final quantitySize = styles.getStyles('sprout_page.inventory.card.quantity_label.font_size') as double;
    final quantityWeight = styles.getStyles('sprout_page.inventory.card.quantity_label.font_weight') as FontWeight;

    final lockedBgColor = styles.getStyles('sprout_page.inventory.card.locked_overlay.background.color') as Color;
    final lockedBgOpacity = styles.getStyles('sprout_page.inventory.card.locked_overlay.background.opacity') as double;
    final lockedBgBlur = styles.getStyles('sprout_page.inventory.card.locked_overlay.background.blur_sigma') as double;
    final lockedStrokeGradient = styles.getStyles('sprout_page.inventory.card.locked_overlay.stroke_color') as LinearGradient;
    final lockedStrokeThickness = styles.getStyles('sprout_page.inventory.card.locked_overlay.stroke_thickness') as double;
    final lockedLabelColor = styles.getStyles('sprout_page.inventory.card.locked_overlay.locked_label.color') as Color;
    final lockedLabelSize = styles.getStyles('sprout_page.inventory.card.locked_overlay.locked_label.font_size') as double;
    final lockedLabelWeight = styles.getStyles('sprout_page.inventory.card.locked_overlay.locked_label.font_weight') as FontWeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: pickerHeight,
        decoration: BoxDecoration(
          color: pickerBg,
          borderRadius: BorderRadius.circular(pickerRadius),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inventory',
                  style: TextStyle(color: titleColor, fontSize: titleSize, fontWeight: titleWeight),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(closeIcon, width: closeW, height: closeH),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inventory grid (3 columns)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxWidth = constraints.maxWidth;
                  const int columns = 3;
                  const double spacing = 8.0;
                  final double itemWidth = (maxWidth - (columns - 1) * spacing) / columns;

                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _inventoryItems.map((item) {
                        // Determine if it's a seed or crop to get the correct icon
                        String imagePath;
                        if (item.id.endsWith('Seeds')) {
                          final cropId = item.id.replaceAll('Seeds', '').toLowerCase();
                          final formattedCropId = cropId[0].toLowerCase() + cropId.substring(1);
                          imagePath = farmSchema.getSeedIcon(formattedCropId);
                        } else {
                          imagePath = farmSchema.getItemIcon(item.id);
                        }

                        return SizedBox(
                          width: itemWidth,
                          child: Stack(
                            children: [
                              // Card
                              Container(
                                height: cardHeight,
                                decoration: BoxDecoration(
                                  gradient: cardStroke,
                                  borderRadius: BorderRadius.circular(cardBorderRadius),
                                ),
                                padding: EdgeInsets.all(cardBorderWidth),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: cardBg,
                                    borderRadius: BorderRadius.circular(cardBorderRadius - cardBorderWidth),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Row(
                                      children: [
                                        // Left: icon
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Image.asset(imagePath, width: iconWidth, height: iconHeight, fit: BoxFit.contain),
                                          ),
                                        ),

                                        // Right: texts
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: cropLabelSize * 1.3,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    item.displayName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.visible,
                                                    style: TextStyle(color: cropLabelColor, fontSize: cropLabelSize, fontWeight: cropLabelWeight),
                                                  ),
                                                ),
                                              ),
                                              Text('x${item.quantity}', style: TextStyle(color: quantityColor, fontSize: quantitySize, fontWeight: quantityWeight)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Locked overlay if locked
                              if (item.isLocked)
                                Positioned.fill(
                                  child: GlassEffect(
                                    background: lockedBgColor,
                                    opacity: lockedBgOpacity,
                                    blurSigma: lockedBgBlur,
                                    strokeGradient: lockedStrokeGradient,
                                    strokeThickness: lockedStrokeThickness,
                                    borderRadius: cardBorderRadius,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Left: icon
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Image.asset(lockedIconImage, width: iconWidth, height: iconHeight),
                                            ),
                                          ),

                                          // Right: "Locked" label
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Locked', style: TextStyle(color: lockedLabelColor, fontSize: lockedLabelSize, fontWeight: lockedLabelWeight)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
