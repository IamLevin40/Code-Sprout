import 'package:flutter/material.dart';
import '../models/farm_data.dart';
import '../models/styles_schema.dart';
import '../models/language_code_files.dart';
import '../widgets/farm_items/farm_grid_view.dart';
import '../widgets/farm_items/code_editor_widget.dart';
import '../widgets/farm_items/code_execution_log_widget.dart';
import '../widgets/farm_items/inventory_popup_display.dart';
import '../compilers/base_interpreter.dart';
import '../compilers/cpp_interpreter.dart';
import '../compilers/csharp_interpreter.dart';
import '../compilers/java_interpreter.dart';
import '../compilers/python_interpreter.dart';
import '../compilers/javascript_interpreter.dart';
import '../services/local_storage_service.dart';
import '../services/code_files_service.dart';
import '../miscellaneous/interactive_viewport_controller.dart';
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
  late InteractiveViewportController _viewportController;
  bool _centeredOnce = false;
  bool _showExecutionLog = false;
  late ScrollController _logScrollController;
  bool _autoScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _farmState = FarmState();
    _codeFiles = LanguageCodeFiles.createDefault(widget.languageId);
    _codeController = TextEditingController(text: _codeFiles.currentFile.content);
    _viewportController = InteractiveViewportController(
      initialScale: 1.0,
      minScale: 0.5,
      maxScale: 3.0,
      scrollZoomSpeed: 0.15,
    );
    _logScrollController = ScrollController();
    _logScrollController.addListener(_onLogScroll);
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

    // Ensure viewport centers once after the first frame (styles and layout available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_centeredOnce) {
        try {
          final styles = AppStyles();
          final double plotSize = styles.getStyles('farm_page.farm_grid.plot_size') as double;
          final double spacing = styles.getStyles('farm_page.farm_grid.plot_spacing') as double;
          final double totalPlotSize = plotSize + spacing;

          _viewportController.resetToCenter(
            gridSize: Size(_farmState.gridWidth.toDouble(), _farmState.gridHeight.toDouble()),
            plotSize: Size(totalPlotSize, totalPlotSize),
          );
          _centeredOnce = true;
        } catch (_) {}
      }
    });
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
    _viewportController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _onLogScroll() {
    if (!_logScrollController.hasClients) return;
    
    // Check if user is at the bottom (within 50 pixels)
    final maxScroll = _logScrollController.position.maxScrollExtent;
    final currentScroll = _logScrollController.position.pixels;
    final isAtBottom = maxScroll - currentScroll < 50;
    
    // Enable auto-scroll when at bottom, disable when scrolling up
    if (isAtBottom && !_autoScrollEnabled) {
      setState(() {
        _autoScrollEnabled = true;
      });
    } else if (!isAtBottom && _autoScrollEnabled) {
      setState(() {
        _autoScrollEnabled = false;
      });
    }
  }

  void _onFarmStateChanged() {
    if (mounted) {
      setState(() {});

      // If the farm state updated asynchronously (e.g. loaded from storage), ensure we center once
      if (!_centeredOnce) {
        try {
          final styles = AppStyles();
          final double plotSize = styles.getStyles('farm_page.farm_grid.plot_size') as double;
          final double spacing = styles.getStyles('farm_page.farm_grid.plot_spacing') as double;
          final double totalPlotSize = plotSize + spacing;

          _viewportController.resetToCenter(
            gridSize: Size(_farmState.gridWidth.toDouble(), _farmState.gridHeight.toDouble()),
            plotSize: Size(totalPlotSize, totalPlotSize),
          );
          _centeredOnce = true;
        } catch (_) {}
      }
    }
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

  Future<void> _runExecution() async {
    if (_isExecuting) return;
    
    if (!mounted) return;
    
    setState(() {
      _isExecuting = true;
      _executionLog.clear();
      _logNotifier.value = [];
      _executingLineNotifier.value = null;
      _errorLineNotifier.value = null;
      _farmState.setExecuting(true);
      _autoScrollEnabled = true; // Reset auto-scroll to enabled
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
          _showExecutionLog = false; // Hide log when execution fails
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
          _showExecutionLog = false; // Hide log when execution completes
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
          _showExecutionLog = false; // Hide log when execution errors
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
        _showExecutionLog = false; // Hide log on cleanup
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
          _showExecutionLog = false; // Hide log when execution stops
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
              
              // Layer 3: Execution Log Overlay (Only shown when log button pressed)
              if (_showExecutionLog) _buildExecutionLogOverlay(styles),
              
              // Layer 4: Code Editor Overlay (Only shown when code button pressed)
              if (_showCodeEditor) _buildCodeEditorOverlay(styles),
            ],
          ),
        ),
      ),
    );
  }
  
  // Layer 1: Farm Grid with Infinite Viewport
  Widget _buildFarmGridLayer(AppStyles styles) {
    return Positioned.fill(
      child: FarmGridView(
        farmState: _farmState,
        controller: _viewportController,
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
          
          const SizedBox(height: 8),
          
          // Zoom control buttons
          _buildZoomControls(styles),
          
          const Spacer(),
          
          // Top control: Run button when not executing, Stop and Log buttons when executing
          if (!_isExecuting) _buildRunButtonWithFileSelector(styles),
          if (_isExecuting) _buildStopAndLogButtons(styles),
          
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
      bottom: 64,
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

  Widget _buildStopAndLogButtons(AppStyles styles) {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            styles: styles,
            label: 'Stop',
            styleKey: 'farm_page.control_buttons.stop_button',
            onTap: _stopExecution,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildControlButton(
            styles: styles,
            label: 'Log',
            styleKey: 'farm_page.control_buttons.code_button',
            icon: Icons.receipt_long,
            onTap: () {
              setState(() {
                _showExecutionLog = !_showExecutionLog;
              });
            },
          ),
        ),
      ],
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

  Widget _buildZoomControls(AppStyles styles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildZoomButton(styles, Icons.zoom_in, () => _viewportController.zoomIn()),
        const SizedBox(width: 8),
        _buildZoomButton(styles, Icons.center_focus_strong, () {
          // Calculate grid center based on farm dimensions
          final double plotSize = styles.getStyles('farm_page.farm_grid.plot_size') as double;
          final double spacing = styles.getStyles('farm_page.farm_grid.plot_spacing') as double;
          final double totalPlotSize = plotSize + spacing; // Plot + spacing around it
          
          _viewportController.resetToCenter(
            gridSize: Size(
              _farmState.gridWidth.toDouble(),
              _farmState.gridHeight.toDouble(),
            ),
            plotSize: Size(totalPlotSize, totalPlotSize),
          );
        }),
        const SizedBox(width: 8),
        _buildZoomButton(styles, Icons.zoom_out, () => _viewportController.zoomOut()),
      ],
    );
  }

  Widget _buildZoomButton(AppStyles styles, IconData icon, VoidCallback onTap) {
    final size = styles.getStyles('farm_page.back_button.width') as double;
    final bgColor = styles.getStyles('farm_page.back_button.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.back_button.border_radius') as double;
    final iconColor = styles.getStyles('farm_page.language_display.text.color') as Color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size * 0.8,
        height: size * 0.8,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: size * 0.4),
        ),
      ),
    );
  }

  void _showInventoryPopup() {
    showInventoryPopup(context, LocalStorageService.instance.userDataNotifier.value);
  }

  Widget _buildRunButtonWithFileSelector(AppStyles styles) {
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
          label: 'Run',
          styleKey: 'farm_page.control_buttons.start_button',
          onTap: _runExecution,
        ),
      ],
    );
  }

  Widget _buildCodeEditorWithFileSelector(AppStyles styles) {
    return CodeEditorWidget(
      initialCode: _codeFiles.currentFile.content,
      onCodeChanged: _onCodeChanged,
      onClose: () {
        setState(() => _showCodeEditor = false);
      },
      controller: _codeController,
      executingLineNotifier: _executingLineNotifier,
      errorLineNotifier: _errorLineNotifier,
      isReadOnly: _isExecuting,
      showFileToolbar: true,
      currentFileName: _codeFiles.currentFileName,
      canDeleteFile: _codeFiles.files.length > 1,
      onAddFile: _showAddFileDialog,
      onDeleteFile: _deleteCurrentFile,
      onNextFile: _nextEditorFile,
      onPreviousFile: _previousEditorFile,
    );
  }

  Widget _buildExecutionLog(AppStyles styles) {
    return CodeExecutionLogWidget(
      logNotifier: _logNotifier,
      scrollController: _logScrollController,
      autoScrollEnabled: _autoScrollEnabled,
      onClose: () {
        setState(() {
          _showExecutionLog = false;
        });
      },
    );
  }
}

