import 'package:flutter/material.dart';

/// A safe FutureBuilder that handles errors gracefully
/// Shows error details for debugging on mobile devices
class SafeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace)? errorBuilder;
  final String? debugLabel;

  const SafeFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!, snapshot.stackTrace ?? StackTrace.current);
          }
          
          // Default error display
          return _buildDefaultError(context, snapshot.error!, snapshot.stackTrace);
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          if (loadingBuilder != null) {
            return loadingBuilder!(context);
          }
          return const SizedBox.shrink(); // Default: show nothing while loading
        }

        // Handle success state
        try {
          return builder(context, snapshot.data as T);
        } catch (e, stackTrace) {
          // Catch errors in the builder itself
          if (errorBuilder != null) {
            return errorBuilder!(context, e, stackTrace);
          }
          return _buildDefaultError(context, e, stackTrace);
        }
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, Object error, StackTrace? stackTrace) {
    final label = debugLabel ?? 'FutureBuilder';
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error in $label',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            error.toString(),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          if (stackTrace != null) ...[
            const SizedBox(height: 4),
            SelectableText(
              stackTrace.toString().split('\n').take(3).join('\n'),
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
