import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/error_reporting_service.dart';

/// Global error boundary that catches and handles all uncaught errors
class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;
  final String context;

  const GlobalErrorBoundary({
    super.key,
    required this.child,
    this.context = 'App',
  });

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      _handleError(details.exception, details.stack);
      FlutterError.presentError(details);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
      }
    });

    // Log error
    ErrorHandler.logError(error, stackTrace, widget.context);

    // Report to monitoring service
    ErrorReportingService().reportError(
      ErrorHandler.standardizeError(error, stackTrace),
      context: widget.context,
    );
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The app encountered an unexpected error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
