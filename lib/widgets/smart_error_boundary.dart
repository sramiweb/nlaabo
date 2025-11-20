import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/error_recovery_service.dart';
import '../services/error_reporting_service.dart';
import '../constants/responsive_constants.dart';
import 'loading_overlay.dart';

/// Smart error boundary that automatically chooses the best recovery strategy
class SmartErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? context;
  final bool enableReporting;
  final bool enableAutoRecovery;

  const SmartErrorBoundary({
    super.key,
    required this.child,
    this.context,
    this.enableReporting = true,
    this.enableAutoRecovery = true,
  });

  @override
  State<SmartErrorBoundary> createState() => _SmartErrorBoundaryState();
}

class _SmartErrorBoundaryState extends State<SmartErrorBoundary> {
  bool _hasError = false;
  bool _isRecovering = false;
  RecoveryAction? _recoveryAction;

  @override
  void didUpdateWidget(SmartErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _hasError = false;
      _recoveryAction = null;
    }
  }

  void _handleError(Object error, StackTrace? stackTrace) async {
    final standardizedError = ErrorHandler.standardizeError(error, stackTrace);

    // Report error if enabled
    if (widget.enableReporting) {
      final reportingService = ErrorReportingService();
      await reportingService.reportError(
        standardizedError,
        context: widget.context,
      );
    }

    // Get recovery action
    final recoveryService = ErrorRecoveryService();
    final recoveryAction = await recoveryService.getRecoveryAction(standardizedError);

    if (mounted) {
      setState(() {
        _hasError = true;
        _recoveryAction = recoveryAction;
      });

      // Auto-recover if enabled and action supports it
      if (widget.enableAutoRecovery && _shouldAutoRecover(recoveryAction)) {
        _performAutoRecovery(recoveryAction);
      }
    }
  }

  bool _shouldAutoRecover(RecoveryAction action) {
    // Auto-recover for network errors and timeouts
    return action.type == RecoveryType.retry ||
           action.type == RecoveryType.checkConnectivity ||
           action.type == RecoveryType.offlineMode;
  }

  void _performAutoRecovery(RecoveryAction action) async {
    setState(() {
      _isRecovering = true;
    });

    try {
      await action.primaryAction.action();

      if (mounted) {
        setState(() {
          _hasError = false;
          _recoveryAction = null;
          _isRecovering = false;
        });
      }
    } catch (e) {
      // Auto-recovery failed, stay in error state
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  void _manualRecovery() async {
    if (_recoveryAction == null) return;

    setState(() {
      _isRecovering = true;
    });

    try {
      await _recoveryAction!.primaryAction.action();

      if (mounted) {
        setState(() {
          _hasError = false;
          _recoveryAction = null;
          _isRecovering = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _recoveryAction != null) {
      return _buildRecoveryUI();
    }

    // Wrap child with error boundary
    return ErrorBoundary(
      onError: _handleError,
      child: LoadingOverlay(
        isLoading: _isRecovering,
        loadingMessage: 'Recovering...',
        child: widget.child,
      ),
    );
  }

  Widget _buildRecoveryUI() {
    final action = _recoveryAction!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: ResponsiveConstants.getResponsivePadding(context, 'xl'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getErrorIcon(action.type),
                  size: 48,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                action.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                action.description,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (action.secondaryActions.isNotEmpty) ...[
                ...action.secondaryActions.map(
                  (secondaryAction) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await secondaryAction.action();
                      },
                      icon: Icon(_getActionIcon(secondaryAction.label)),
                      label: Text(secondaryAction.label),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(200, 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _manualRecovery,
                icon: Icon(_getActionIcon(action.primaryAction.label)),
                label: Text(action.primaryAction.label),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon(RecoveryType type) {
    switch (type) {
      case RecoveryType.checkConnectivity:
      case RecoveryType.offlineMode:
        return Icons.wifi_off;
      case RecoveryType.reauthenticate:
        return Icons.lock;
      case RecoveryType.wait:
        return Icons.hourglass_empty;
      case RecoveryType.requestPermission:
        return Icons.security;
      case RecoveryType.correctInput:
        return Icons.edit;
      case RecoveryType.contactSupport:
        return Icons.support_agent;
      default:
        return Icons.error_outline;
    }
  }

  IconData _getActionIcon(String label) {
    if (label.toLowerCase().contains('retry')) return Icons.refresh;
    if (label.toLowerCase().contains('login')) return Icons.login;
    if (label.toLowerCase().contains('settings')) return Icons.settings;
    if (label.toLowerCase().contains('permission')) return Icons.security;
    if (label.toLowerCase().contains('support')) return Icons.support_agent;
    if (label.toLowerCase().contains('check')) return Icons.check_circle;
    return Icons.arrow_forward;
  }
}

/// Simple error boundary widget for catching errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    // Install error handler
    ErrorWidget.builder = (FlutterErrorDetails details) {
      widget.onError?.call(details.exception, details.stack);
      return _buildErrorWidget(details);
    };
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text('An error occurred'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
