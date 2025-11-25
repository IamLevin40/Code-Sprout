import 'package:flutter/material.dart';

/// Error boundary widget that catches and displays errors in a user-friendly way
/// Useful for debugging on mobile devices where console logs are not visible
class ErrorBoundary extends StatefulWidget {
  final Widget Function() builder;
  final String pageName;

  const ErrorBoundary({
    super.key,
    required this.builder,
    required this.pageName,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();

  /// Static method to wrap a widget builder with error handling
  static Widget wrapBuild({
    required BuildContext context,
    required String pageName,
    required Widget Function() builder,
  }) {
    return ErrorBoundary(
      pageName: pageName,
      builder: builder,
    );
  }
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorScreen(
        context: context,
        pageName: widget.pageName,
        error: _error!,
        stackTrace: _stackTrace!,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    try {
      return widget.builder();
    } catch (e, stackTrace) {
      // Capture synchronous errors
      return _buildErrorScreen(
        context: context,
        pageName: widget.pageName,
        error: e,
        stackTrace: stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }
  }

  Widget _buildErrorScreen({
    required BuildContext context,
    required String pageName,
    required Object error,
    required StackTrace stackTrace,
    VoidCallback? onRetry,
  }) {
    // Get a compact stack trace (first 5 lines)
    final stackLines = stackTrace.toString().split('\n').take(5).join('\n');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Page Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'An error occurred in: $pageName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error Details:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        error.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stack Trace (first 5 lines):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        stackLines,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Try to go back
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (onRetry != null) {
                            onRetry();
                          } else {
                            // Refresh by popping and going back
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Debugging Tips:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Take a screenshot of this error for debugging\n'
                  '• Check if assets are properly loaded\n'
                  '• Verify internet connection for Firebase\n'
                  '• Try restarting the app',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
