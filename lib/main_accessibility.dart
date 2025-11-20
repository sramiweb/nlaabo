import 'package:flutter/material.dart';
import 'utils/accessibility_monitoring.dart';
import 'utils/accessibility_reporting.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_form_field.dart';

/// Main accessibility integration point for the Nlaabo app
class AccessibilityIntegration {
  static final AccessibilityMonitoring _monitoring = AccessibilityMonitoring();

  /// Initialize accessibility monitoring
  static void initializeAccessibilityMonitoring(BuildContext context) {
    // Define key widgets to monitor
    final monitoredWidgets = <Widget>[
      AuthButton(text: 'Sample Login', onPressed: () {}),
      AuthFormField(
        labelText: 'Email',
        hintText: 'Enter your email',
        validator: (value) => null,
      ),
      AuthFormField(
        labelText: 'Password',
        hintText: 'Enter your password',
        obscureText: true,
        validator: (value) => null,
      ),
    ];

    // Start monitoring with reasonable thresholds
    _monitoring.startMonitoring(
      context: context,
      monitoredWidgets: monitoredWidgets,
      alertThreshold: 85.0,
      enableHistoricalTracking: true,
    );

    // Listen to alerts and handle them
    _monitoring.alerts.listen((alert) {
      _handleAccessibilityAlert(alert);
    });

    debugPrint('✅ Accessibility monitoring initialized');
  }

  /// Handle accessibility alerts
  static void _handleAccessibilityAlert(AccessibilityAlert alert) {
    // Log the alert
    AccessibilityReporting.sendAlertNotification(alert);

    // In a real app, you might:
    // - Show in-app notifications
    // - Send to analytics/monitoring service
    // - Trigger UI updates
    // - Send push notifications

    switch (alert.severity) {
      case AlertSeverity.critical:
        // Immediate action required
        _showCriticalAlert(alert);
        break;
      case AlertSeverity.high:
        // High priority alert
        _showHighPriorityAlert(alert);
        break;
      case AlertSeverity.medium:
        // Medium priority alert
        _showMediumPriorityAlert(alert);
        break;
      case AlertSeverity.low:
        // Low priority alert
        _showLowPriorityAlert(alert);
        break;
    }
  }

  /// Show critical accessibility alert
  static void _showCriticalAlert(AccessibilityAlert alert) {
    debugPrint('🚨 CRITICAL ACCESSIBILITY ALERT: ${alert.message}');
    // In a real app, show modal dialog or notification
  }

  /// Show high priority accessibility alert
  static void _showHighPriorityAlert(AccessibilityAlert alert) {
    debugPrint('⚠️ HIGH PRIORITY ACCESSIBILITY ALERT: ${alert.message}');
    // In a real app, show snackbar or notification
  }

  /// Show medium priority accessibility alert
  static void _showMediumPriorityAlert(AccessibilityAlert alert) {
    debugPrint('📢 MEDIUM PRIORITY ACCESSIBILITY ALERT: ${alert.message}');
    // In a real app, log to analytics
  }

  /// Show low priority accessibility alert
  static void _showLowPriorityAlert(AccessibilityAlert alert) {
    debugPrint('ℹ️ LOW PRIORITY ACCESSIBILITY ALERT: ${alert.message}');
    // In a real app, log for monitoring
  }

  /// Generate accessibility compliance report
  static Future<String> generateComplianceReport() async {
    return _monitoring.generateComplianceReport();
  }

  /// Stop accessibility monitoring
  static void stopAccessibilityMonitoring() {
    _monitoring.stopMonitoring();
    debugPrint('🛑 Accessibility monitoring stopped');
  }

  /// Get current monitoring statistics
  static AccessibilityMonitoringStats getMonitoringStats() {
    return _monitoring.getMonitoringStats();
  }

  /// Export accessibility data
  static Future<void> exportAccessibilityData() async {
    getMonitoringStats(); // Use stats for monitoring
    final report = await generateComplianceReport();

    // Export to various formats
    await AccessibilityReporting.exportReport(report, 'md', filePath: 'accessibility_compliance_report.md');
    await AccessibilityReporting.exportReport(report, 'html', filePath: 'accessibility_compliance_report.html');

    debugPrint('📄 Accessibility reports exported');
  }
}

/// Extension to integrate accessibility into app lifecycle
extension AccessibilityAppExtension on Widget {
  /// Wrap app with accessibility monitoring
  Widget withAccessibilityMonitoring() {
    return _AccessibilityMonitoringWrapper(child: this);
  }
}

/// Widget that handles accessibility monitoring lifecycle
class _AccessibilityMonitoringWrapper extends StatefulWidget {
  final Widget child;

  const _AccessibilityMonitoringWrapper({required this.child});

  @override
  State<_AccessibilityMonitoringWrapper> createState() => _AccessibilityMonitoringWrapperState();
}

class _AccessibilityMonitoringWrapperState extends State<_AccessibilityMonitoringWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize monitoring after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AccessibilityIntegration.initializeAccessibilityMonitoring(context);
      }
    });
  }

  @override
  void dispose() {
    AccessibilityIntegration.stopAccessibilityMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Accessibility-aware MaterialApp wrapper
class AccessibilityAwareApp extends StatelessWidget {
  final Widget home;
  final String title;
  final ThemeData? theme;
  final RouteFactory? onGenerateRoute;
  final List<NavigatorObserver>? navigatorObservers;

  const AccessibilityAwareApp({
    super.key,
    required this.home,
    required this.title,
    this.theme,
    this.onGenerateRoute,
    this.navigatorObservers,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: theme,
      home: home.withAccessibilityMonitoring(),
      onGenerateRoute: onGenerateRoute,
      navigatorObservers: navigatorObservers ?? const [],
      // Accessibility-specific configurations
      debugShowCheckedModeBanner: false,
      // Ensure proper text scaling
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Respect system text scaling
          ),
          child: child!,
        );
      },
    );
  }
}
