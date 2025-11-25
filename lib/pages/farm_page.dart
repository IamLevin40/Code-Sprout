import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../models/farm_data.dart';
import '../models/styles_schema.dart';
import '../models/language_code_files.dart';
import '../models/research_data.dart';
import '../models/user_data.dart';
import '../widgets/farm_items/farm_grid_view.dart';
import '../widgets/farm_items/code_editor_widget.dart';
import '../widgets/farm_items/code_execution_log_widget.dart';
import '../widgets/farm_items/inventory_popup_display.dart';
import '../widgets/farm_items/farm_top_controls.dart';
import '../widgets/farm_items/farm_bottom_controls.dart';
import '../widgets/farm_items/research_lab_display.dart';
import '../widgets/farm_items/clear_farm_dialog.dart';
import '../widgets/farm_items/add_file_dialog.dart';
import '../widgets/farm_items/farm_loading_view.dart';
import '../widgets/farm_items/notification_display.dart';
import '../compilers/base_interpreter.dart';
import '../services/local_storage_service.dart';
import '../miscellaneous/interactive_viewport_controller.dart';
import '../miscellaneous/number_utils.dart';
import '../miscellaneous/handle_code_files.dart';
import '../miscellaneous/handle_farm_progress.dart';
import '../miscellaneous/handle_research_progress.dart';
import '../miscellaneous/get_interpreter.dart';
import '../miscellaneous/handle_code_execution.dart';
import '../miscellaneous/handle_research_completed.dart';

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
  late ResearchState _researchState;
  bool _showCodeEditor = false;
  bool _showResearchLab = false;
  late LanguageCodeFiles _codeFiles;
  int _selectedExecutionFileIndex = 0; // File selected in start button
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
  
  // Loading state management
  FarmLoadingState _loadingState = FarmLoadingState.loading;
  String? _loadingErrorMessage;
  bool _isDataLoaded = false;
  // Network / auto-save helpers
  Timer? _connectivityTimer;
  bool _pendingRemoteSave = false;
  
  // Notification controller
  late NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController = NotificationController();
    _researchState = ResearchState();
    _farmState = FarmState(researchState: _researchState);
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
    
    // initialize farm state with cached user data and keep in sync
    try {
      final ud = LocalStorageService.instance.userDataNotifier.value;
      if (ud != null) _farmState.setUserData(ud);
      LocalStorageService.instance.userDataNotifier.addListener(() {
        _farmState.setUserData(LocalStorageService.instance.userDataNotifier.value);
      });
    } catch (_) {}
    
    // Start loading all required data
    _initializeFarmData();

    // Start lightweight periodic connectivity checks to flush pending remote saves.
    // Uses a simple DNS lookup to avoid adding external dependencies.
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final hasNet = await _hasNetworkConnection();
        if (hasNet) {
          if (_loadingState == FarmLoadingState.error) {
            // If initial loading previously failed due to connectivity, try again when network returns.
            _initializeFarmData();
          }

          if (_pendingRemoteSave && _isDataLoaded) {
            _performPendingSaves();
          }
        }
      } catch (_) {}
    });
  }

  /// Lightweight network check. Returns true when a DNS lookup succeeds.
  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Attempt to perform any pending remote saves and clear the pending flag on success.
  Future<void> _performPendingSaves() async {
    if (!_isDataLoaded) return;
    bool anyFailed = false;
    // Try farm progress
    try {
      await FarmProgressHandler.saveFarmProgress(farmState: _farmState);
    } catch (_) {
      anyFailed = true;
    }

    // Try research progress
    try {
      await ResearchProgressHandler.saveResearchProgress(researchState: _researchState);
    } catch (_) {
      anyFailed = true;
    }

    // Try code files
    try {
      await CodeFilesHandler.saveCodeFiles(
        languageId: widget.languageId,
        codeFiles: _codeFiles,
        codeController: _codeController,
        notificationController: _notificationController,
      );
    } catch (_) {
      anyFailed = true;
    }

    _pendingRemoteSave = anyFailed;
  }
  
  /// Initialize farm data by loading all required resources
  Future<void> _initializeFarmData() async {
    setState(() {
      _loadingState = FarmLoadingState.loading;
      _loadingErrorMessage = null;
      _isDataLoaded = false;
    });
    
    try {
      // Load all data in parallel for better performance
      final results = await Future.wait([
        _loadCodeFiles(),
        _loadFarmProgress(),
        _loadResearchProgress(),
      ], eagerError: true);
      
      // Check if all loads were successful
      final allSuccess = results.every((result) => result == true);
      
      if (allSuccess && mounted) {
        setState(() {
          _loadingState = FarmLoadingState.success;
          _isDataLoaded = true;
        });
        
        // Ensure viewport centers after successful load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_centeredOnce && mounted) {
            if (_resetViewportToCenter()) {
              _centeredOnce = true;
            }
          }
        });
      } else {
        throw Exception('Some data failed to load');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = FarmLoadingState.error;
          _loadingErrorMessage = 'Failed to load farm data. ${e.toString()}';
        });
      }
    }
  }
  
  Future<bool> _loadCodeFiles() async {
    try {
      final loadedFiles = await CodeFilesHandler.loadCodeFiles(
        context: context,
        languageId: widget.languageId,
        notificationController: _notificationController,
      );
      
      if (loadedFiles != null && mounted) {
        setState(() {
          _codeFiles = loadedFiles;
          _selectedExecutionFileIndex = _codeFiles.currentFileIndex;
          _codeController.text = _codeFiles.currentFile.content;
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _saveCodeFiles() async {
    if (!_isDataLoaded) return; // Only save if data is loaded
    try {
      await CodeFilesHandler.saveCodeFiles(
        languageId: widget.languageId,
        codeFiles: _codeFiles,
        codeController: _codeController,
        notificationController: _notificationController,
      );
    } catch (e) {
      // Mark that a remote save is pending; a periodic connectivity check
      // will attempt to flush pending saves when network returns.
      _pendingRemoteSave = true;
    }
  }

  /// Load farm progress from Firestore and apply to farm state
  Future<bool> _loadFarmProgress() async {
    try {
      await FarmProgressHandler.loadFarmProgress(
        farmState: _farmState,
        onFarmStateChanged: _onFarmStateChanged,
      );
      if (mounted) setState(() {});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load research progress from Firestore
  Future<bool> _loadResearchProgress() async {
    try {
      await ResearchProgressHandler.loadResearchProgress(
        researchState: _researchState,
        farmState: _farmState,
        onResearchStateChanged: _onResearchStateChanged,
      );
      if (mounted) setState(() {});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save farm progress to Firestore
  Future<void> _saveFarmProgress() async {
    if (!_isDataLoaded) return; // Only save if data is loaded
    try {
      await FarmProgressHandler.saveFarmProgress(farmState: _farmState);
    } catch (e) {
      _pendingRemoteSave = true;
    }
  }

  /// Save research progress to Firestore
  Future<void> _saveResearchProgress() async {
    if (!_isDataLoaded) return; // Only save if data is loaded
    try {
      await ResearchProgressHandler.saveResearchProgress(researchState: _researchState);
    } catch (e) {
      _pendingRemoteSave = true;
    }
  }

  @override
  void dispose() {
    // Stop any running execution before disposal
    if (_isExecuting && _currentInterpreter != null) {
      _currentInterpreter!.stop();
    }
    
    // Save progress when leaving page (attempt, will mark pending if offline)
    _saveFarmProgress();
    _saveResearchProgress();
    
    _farmState.removeListener(_onFarmStateChanged);
    _researchState.removeListener(_onResearchStateChanged);
    _farmState.dispose();
    _researchState.dispose();
    _executingLineNotifier.dispose();
    _errorLineNotifier.dispose();
    _logNotifier.dispose();
    _codeController.dispose();
    _viewportController.dispose();
    _logScrollController.dispose();
    _connectivityTimer?.cancel();
    _notificationController.dispose();
    super.dispose();
  }

  void _onLogScroll() {
    CodeExecutionHandler.onLogScroll(
      logScrollController: _logScrollController,
      autoScrollEnabled: _autoScrollEnabled,
      setAutoScrollEnabled: (value) => setState(() => _autoScrollEnabled = value),
    );
  }

  void _onFarmStateChanged() {
    if (mounted) {
      setState(() {});
      _saveFarmProgress();
      if (!_centeredOnce) {
        if (_resetViewportToCenter()) {
          _centeredOnce = true;
        }
      }
    }
  }

  void _onResearchStateChanged() {
    if (mounted) {
      setState(() {});
      _saveResearchProgress();
    }
  }

  FarmCodeInterpreter _getInterpreter() {
    return InterpreterFactory.getInterpreter(
      languageId: widget.languageId,
      farmState: _farmState,
      researchState: _researchState,
      onCropHarvested: _onCropHarvested,
      onLineExecuting: (line) => _executingLineNotifier.value = line,
      onLineError: (line, isError) => _errorLineNotifier.value = isError ? line : null,
      onLogUpdate: (message) {
        _logNotifier.value = List.from(_logNotifier.value)..add(message);
      },
      mounted: mounted,
    );
  }

  Future<void> _onCropHarvested(CropType cropType) async {
    // Persistence is handled by FarmState; ensure local notifier is in sync.
    try {
      final ud = LocalStorageService.instance.userDataNotifier.value;
      if (ud != null) _farmState.setUserData(ud);
    } catch (_) {}
  }

  Future<void> _runExecution() async {
    final interpreter = _getInterpreter();
    
    await CodeExecutionHandler.runExecution(
      context: context,
      isExecuting: _isExecuting,
      mounted: mounted,
      farmState: _farmState,
      codeFiles: _codeFiles,
      selectedExecutionFileIndex: _selectedExecutionFileIndex,
      interpreter: interpreter,
      executingLineNotifier: _executingLineNotifier,
      errorLineNotifier: _errorLineNotifier,
      logNotifier: _logNotifier,
      setIsExecuting: (value) => setState(() => _isExecuting = value),
      setAutoScrollEnabled: (value) => setState(() => _autoScrollEnabled = value),
      setShowExecutionLog: (value) => setState(() => _showExecutionLog = value),
      setExecutionLog: (_) {},
      setCurrentInterpreter: (interp) => _currentInterpreter = interp,
      notificationController: _notificationController,
    );
  }
  
  void _stopExecution() {
    CodeExecutionHandler.stopExecution(
      currentInterpreter: _currentInterpreter,
      mounted: mounted,
      setIsExecuting: (value) => setState(() => _isExecuting = value),
      farmState: _farmState,
      executingLineNotifier: _executingLineNotifier,
      setShowExecutionLog: (value) => setState(() => _showExecutionLog = value),
    );
  }

  /// Helper to reset the interactive viewport to center based on farm grid
  bool _resetViewportToCenter() {
    try {
      final styles = AppStyles();
      final double plotSize = styles.getStyles('farm_page.farm_grid.plot_size') as double;
      final double spacing = styles.getStyles('farm_page.farm_grid.plot_spacing') as double;
      final double totalPlotSize = plotSize + spacing;

      _viewportController.resetToCenter(
        gridSize: Size(_farmState.gridWidth.toDouble(), _farmState.gridHeight.toDouble()),
        plotSize: Size(totalPlotSize, totalPlotSize),
      );

      return true;
    } catch (e) {
      // ignore and return failure
      return false;
    }
  }

  // File navigation methods for code editor
  void _nextEditorFile() {
    CodeFilesHandler.nextEditorFile(
      codeFiles: _codeFiles,
      codeController: _codeController,
      languageId: widget.languageId,
      isExecuting: _isExecuting,
      onStateChanged: () => setState(() {}),
      notificationController: _notificationController,
    );
  }
  
  void _previousEditorFile() {
    CodeFilesHandler.previousEditorFile(
      codeFiles: _codeFiles,
      codeController: _codeController,
      languageId: widget.languageId,
      isExecuting: _isExecuting,
      onStateChanged: () => setState(() {}),
      notificationController: _notificationController,
    );
  }
  
  // File navigation methods for execution file selector
  void _nextExecutionFile() {
    CodeExecutionHandler.nextExecutionFile(
      currentIndex: _selectedExecutionFileIndex,
      codeFiles: _codeFiles,
      setSelectedExecutionFileIndex: (index) => setState(() => _selectedExecutionFileIndex = index),
    );
  }
  
  void _previousExecutionFile() {
    CodeExecutionHandler.previousExecutionFile(
      currentIndex: _selectedExecutionFileIndex,
      codeFiles: _codeFiles,
      setSelectedExecutionFileIndex: (index) => setState(() => _selectedExecutionFileIndex = index),
    );
  }
  
  // Add new file
  void _showAddFileDialog() {
    showAddFileDialog(
      context: context,
      languageId: widget.languageId,
      codeFiles: _codeFiles,
      codeController: _codeController,
      isExecuting: _isExecuting,
      onStateChanged: () => setState(() {}),
      notificationController: _notificationController,
    );
  }
  
  // Delete current file
  void _deleteCurrentFile() {
    CodeFilesHandler.deleteCurrentFile(
      context: context,
      codeFiles: _codeFiles,
      codeController: _codeController,
      languageId: widget.languageId,
      isExecuting: _isExecuting,
      selectedExecutionFileIndex: _selectedExecutionFileIndex,
      onExecutionIndexChanged: (index) => setState(() => _selectedExecutionFileIndex = index),
      onStateChanged: () => setState(() {}),
      notificationController: _notificationController,
    );
  }
  
  /// Handle code changes
  void _onCodeChanged(String code) {
    _codeFiles.updateCurrentFileContent(code);
    _saveCodeFiles();
  }

  void _showInventoryPopup() {
    showInventoryPopup(
      context,
      LocalStorageService.instance.userDataNotifier.value,
      notificationController: _notificationController,
    );
  }

  /// Show confirmation dialog before clearing farm
  void _showClearFarmDialog() {
    showClearFarmDialog(
      context: context,
      farmState: _farmState,
      notificationController: _notificationController,
    );
  }

  /// Handle research completion: deduct items from inventory and mark as completed
  /// Requirements use simplified item IDs (e.g., "wheat", "carrot")
  void _handleResearchCompleted(String researchId, Map<String, int> requirements) async {
    await ResearchCompletionHandler.handleResearchCompleted(
      context: context,
      researchId: researchId,
      requirements: requirements,
      researchState: _researchState,
      farmState: _farmState,
      notificationController: _notificationController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final loadingTransitionMs = styles.getStyles('farm_page.loading_view.transition_duration') as int;

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: loadingTransitionMs),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _loadingState == FarmLoadingState.success
              ? _buildFarmContent()
              : FarmLoadingView(
                  key: ValueKey(_loadingState),
                  state: _loadingState,
                  errorMessage: _loadingErrorMessage,
                  onGoBack: () {
                    // Stop execution if running before navigating back
                    if (_isExecuting && _currentInterpreter != null) {
                      _currentInterpreter!.stop();
                      _farmState.setExecuting(false);
                    }
                    Navigator.of(context).pop();
                  },
                  onTryAgain: _initializeFarmData,
                ),
        ),
      ),
    );
  }

  Widget _buildFarmContent() {
    final styles = AppStyles();
    final codeEditorTransitionMs = styles.getStyles('farm_page.code_editor.transition_duration') as int;
    final researchLabTransitionMs = styles.getStyles('farm_page.research_lab_display.transition_duration') as int;
    final executionLogTransitionMs = styles.getStyles('farm_page.execution_log.transition_duration') as int;

    return Stack(
      key: const ValueKey('farm_content'),
      children: [
        // Layer 1: Farm Grid View (Bottom Layer - Centered)
        _buildFarmGridLayer(),
        
        // Layer 2: Top Bar and Control Buttons
        _buildControlLayer(),
        
        // Layer 3: Execution Log Overlay with slide animation
        _buildExecutionLogOverlayWithAnimation(
          Duration(milliseconds: executionLogTransitionMs),
        ),
        
        // Layer 4: Code Editor Overlay with slide animation
        _buildCodeEditorOverlayWithAnimation(
          Duration(milliseconds: codeEditorTransitionMs),
        ),
        
        // Layer 5: Research Lab Overlay with slide animation
        _buildResearchLabOverlayWithAnimation(
          Duration(milliseconds: researchLabTransitionMs),
        ),

        // Layer 6: Topmost notification overlay
        Positioned(
          left: 24,
          right: 24,
          top: 72,
          child: NotificationDisplay(
            controller: _notificationController,
            position: NotificationPosition.topToBottom,
          ),
        ),
      ],
    );
  }
  
  // Layer 1: Farm Grid with Infinite Viewport
  Widget _buildFarmGridLayer() {
    return Positioned.fill(
      child: FarmGridView(
        farmState: _farmState,
        controller: _viewportController,
      ),
    );
  }
  
  // Layer 2: Top Bar and Control Buttons
  Widget _buildControlLayer() {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Top bar with back button, title, coins display, and language display
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _buildBackButton(),
                const Spacer(),
                _buildTitleLabel(),
                const Spacer(),
                _buildCoinsDisplay(),
                const SizedBox(width: 16),
                _buildLanguageDisplay(),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Zoom control buttons
          _buildZoomControls(),
          
          const SizedBox(height: 8),
          
          // Top controls: Run/Stop/Log buttons
          FarmTopControls(
            isExecuting: _isExecuting,
            codeFiles: _codeFiles,
            selectedExecutionFileIndex: _selectedExecutionFileIndex,
            onRunPressed: _runExecution,
            onStopPressed: _stopExecution,
            onLogPressed: () {
              setState(() {
                _showExecutionLog = !_showExecutionLog;
              });
            },
            onNextFile: _nextExecutionFile,
            onPreviousFile: _previousExecutionFile,
            onClearFarmPressed: _showClearFarmDialog,
          ),
          
          const SizedBox(height: 16),
          
          // Bottom controls: Code, Inventory, Research buttons
          FarmBottomControls(
            onCodePressed: () {
              setState(() => _showCodeEditor = !_showCodeEditor);
            },
            onInventoryPressed: _showInventoryPopup,
            onResearchPressed: () {
              setState(() => _showResearchLab = !_showResearchLab);
            },
          ),
        ],
      ),
    );
  }
  
  // Layer 3: Execution Log Overlay with fade animation
  Widget _buildExecutionLogOverlayWithAnimation(Duration transitionDuration) {
    final styles = AppStyles();
    final logHeight = styles.getStyles('farm_page.execution_log.height') as double;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 64,
      height: logHeight,
      child: AnimatedOpacity(
        duration: transitionDuration,
        opacity: _showExecutionLog ? 1.0 : 0.0,
        curve: Curves.easeInOut,
        child: IgnorePointer(
          ignoring: !_showExecutionLog,
          child: _buildExecutionLog(),
        ),
      ),
    );
  }
  
  // Layer 4: Code Editor Overlay with slide animation
  Widget _buildCodeEditorOverlayWithAnimation(Duration transitionDuration) {
    return AnimatedPositioned(
      duration: transitionDuration,
      curve: Curves.easeInOut,
      left: 24,
      right: 24,
      top: _showCodeEditor ? 96 : MediaQuery.of(context).size.height,
      bottom: _showCodeEditor ? 0 : -MediaQuery.of(context).size.height,
      child: IgnorePointer(
        ignoring: !_showCodeEditor,
        child: _buildCodeEditorWithFileSelector(),
      ),
    );
  }
  
  // Layer 5: Research Lab Overlay with slide animation
  Widget _buildResearchLabOverlayWithAnimation(Duration transitionDuration) {
    return AnimatedPositioned(
      duration: transitionDuration,
      curve: Curves.easeInOut,
      left: 24,
      right: 24,
      top: _showResearchLab ? 96 : MediaQuery.of(context).size.height,
      bottom: _showResearchLab ? 0 : -MediaQuery.of(context).size.height,
      child: IgnorePointer(
        ignoring: !_showResearchLab,
          child: ResearchLabDisplay(
          researchState: _researchState,
          userData: LocalStorageService.instance.userDataNotifier.value,
          currentLanguage: widget.languageId,
          onClose: () {
            setState(() => _showResearchLab = false);
          },
          onResearchCompleted: _handleResearchCompleted,
          notificationController: _notificationController,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    final styles = AppStyles();
    final iconPath = styles.getStyles('farm_page.top_layer.back.icon.image') as String;
    final iconWidth = styles.getStyles('farm_page.top_layer.back.icon.width') as double;
    final iconHeight = styles.getStyles('farm_page.top_layer.back.icon.height') as double;
    final width = styles.getStyles('farm_page.top_layer.back.width') as double;
    final height = styles.getStyles('farm_page.top_layer.back.height') as double;
    final bgColor = styles.getStyles('farm_page.top_layer.back.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.top_layer.back.border_radius') as double;

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
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Image.asset(iconPath, width: iconWidth, height: iconHeight),
        ),
      ),
    );
  }

  Widget _buildTitleLabel() {
    final styles = AppStyles();

    final bgColor = styles.getStyles('farm_page.top_layer.title.background_color') as Color;
    final bgHeight = styles.getStyles('farm_page.top_layer.title.height') as double;
    final bgBorderRadius = styles.getStyles('farm_page.top_layer.title.border_radius') as double;

    final labelColor = styles.getStyles('farm_page.top_layer.title.label.color') as Color;
    final labelFontSize = styles.getStyles('farm_page.top_layer.title.label.font_size') as double;
    final labelFontWeight = styles.getStyles('farm_page.top_layer.title.label.font_weight') as FontWeight;

    final Color shadowColor = styles.getStyles('farm_page.top_layer.title.label.shadow.color') as Color;
    final sopRaw = styles.getStyles('farm_page.top_layer.title.label.shadow.opacity');
    final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
    final sblur = styles.getStyles('farm_page.top_layer.title.label.shadow.blur_radius') as double;
    final textShadows = [
      Shadow(
        color: shadowColor.withAlpha((sop * 255).round()),
        blurRadius: sblur,
      ),
    ];

    return Container(
      height: bgHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(bgBorderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        'Your Farm',
        style: TextStyle(
          fontSize: labelFontSize,
          fontWeight: labelFontWeight,
          color: labelColor,
          shadows: textShadows,
        ),
      ),
    );
  }

  Widget _buildCoinsDisplay() {
    final styles = AppStyles();
    final width = styles.getStyles('farm_page.top_layer.coins_display.width') as double;
    final height = styles.getStyles('farm_page.top_layer.coins_display.height') as double;
    final borderRadius = styles.getStyles('farm_page.top_layer.coins_display.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.top_layer.coins_display.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.top_layer.coins_display.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.top_layer.coins_display.stroke_color') as LinearGradient;
    final iconPath = styles.getStyles('farm_page.top_layer.coins_display.icon.image') as String;
    final iconWidth = styles.getStyles('farm_page.top_layer.coins_display.icon.width') as double;
    final iconHeight = styles.getStyles('farm_page.top_layer.coins_display.icon.height') as double;
    final textColor = styles.getStyles('farm_page.top_layer.coins_display.text.color') as Color;
    final textFontSize = styles.getStyles('farm_page.top_layer.coins_display.text.font_size') as double;
    final textFontWeight = styles.getStyles('farm_page.top_layer.coins_display.text.font_weight') as FontWeight;

    return ValueListenableBuilder<UserData?>(
      valueListenable: LocalStorageService.instance.userDataNotifier,
      builder: (context, userData, _) {
        final coins = userData?.getCoins() ?? 0;

        return Container(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: iconWidth,
                  height: iconHeight,
                ),
                const SizedBox(width: 8),
                Text(
                  NumberUtils.formatNumberShort(coins),
                  style: TextStyle(
                    color: textColor,
                    fontSize: textFontSize,
                    fontWeight: textFontWeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageDisplay() {
    final styles = AppStyles();
    final width = styles.getStyles('farm_page.top_layer.language_display.width') as double;
    final height = styles.getStyles('farm_page.top_layer.language_display.height') as double;
    final borderRadius = styles.getStyles('farm_page.top_layer.language_display.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.top_layer.language_display.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.top_layer.language_display.background_color') as LinearGradient;
    
    // Get language-specific icon and stroke color from course_cards.style_coding
    final languageIcon = styles.getStyles('course_cards.style_coding.${widget.languageId}.icon') as String;
    final strokeGradient = styles.getStyles('course_cards.style_coding.${widget.languageId}.stroke_color') as LinearGradient;

    return Container(
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
        child: Center(
          child: Image.asset(
            languageIcon,
            width: width * 0.6,
            height: height * 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    final styles = AppStyles();
    final spacing = styles.getStyles('farm_page.zoom_controls.spacing') as double;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildZoomButton('zoom_out', () => _viewportController.zoomOut()),
        SizedBox(width: spacing),
        _buildZoomButton('center_focus', () {
          _resetViewportToCenter();
        }),
        SizedBox(width: spacing),
        _buildZoomButton('zoom_in', () => _viewportController.zoomIn()),
      ],
    );
  }

  Widget _buildZoomButton(String iconIdentifier, VoidCallback onTap) {
    final styles = AppStyles();
    final width = styles.getStyles('farm_page.zoom_controls.width') as double;
    final height = styles.getStyles('farm_page.zoom_controls.height') as double;
    final borderRadius = styles.getStyles('farm_page.zoom_controls.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.zoom_controls.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.zoom_controls.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.zoom_controls.stroke_color') as LinearGradient;
    final iconPath = styles.getStyles('farm_page.zoom_controls.icons.$iconIdentifier') as String;

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
          child: Center(
            child: Image.asset(
              iconPath,
              width: width * 0.6,
              height: height * 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeEditorWithFileSelector() {
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
      currentFileName: _codeFiles.currentFileName,
      canDeleteFile: _codeFiles.files.length > 1,
      onAddFile: _showAddFileDialog,
      onDeleteFile: _deleteCurrentFile,
      onNextFile: _nextEditorFile,
      onPreviousFile: _previousEditorFile,
    );
  }

  Widget _buildExecutionLog() {
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
