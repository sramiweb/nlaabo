import 'package:flutter/material.dart';
import '../services/performance_monitor.dart';
import '../constants/responsive_constants.dart';
import '../utils/responsive_text_utils.dart';

/// Performance dashboard widget for displaying real-time performance metrics
class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!WidgetsBinding.instance.debugDidSendFirstFrameEvent) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          constraints: BoxConstraints(
            maxHeight: _isExpanded ? 600 : 80,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              if (_isExpanded) _buildExpandedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final alerts = _monitor.getActiveAlerts();
    final hasAlerts = alerts.isNotEmpty;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: ResponsiveConstants.getResponsivePadding(context, 'lg').copyWith(top: ResponsiveConstants.getResponsiveSpacing(context, 'md'), bottom: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
        decoration: BoxDecoration(
          color: hasAlerts ? Colors.red.shade900 : Colors.blue.shade900,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasAlerts ? Icons.warning : Icons.speed,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
            Text(
              'Performance Monitor',
              style: ResponsiveTextUtils.getResponsiveTextStyle(
                context,
                'titleSmall',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (hasAlerts)
              Container(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'xs2'), vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alerts.length.toString(),
                  style: ResponsiveTextUtils.getResponsiveTextStyle(
                    context,
                    'bodySmall',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricSection('Network', _buildNetworkMetrics()),
            const Divider(color: Colors.white24, height: 24),
            _buildMetricSection('Memory', _buildMemoryMetrics()),
            Divider(color: Colors.white24, height: ResponsiveConstants.getResponsiveSpacing(context, 'xl')),
            _buildMetricSection('Operations', _buildOperationMetrics()),
            Divider(color: Colors.white24, height: ResponsiveConstants.getResponsiveSpacing(context, 'xl')),
            _buildAlertsSection(),
            SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg')),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ResponsiveTextUtils.getResponsiveTextStyle(
            context,
            'titleMedium',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
        content,
      ],
    );
  }

  Widget _buildNetworkMetrics() {
    final networkStats = _monitor.getNetworkStats();

    return Column(
      children: [
        _buildMetricRow('Total Requests', networkStats.totalRequests.toString()),
        _buildMetricRow('Success Rate',
          networkStats.totalRequests > 0
            ? '${((networkStats.successCount / networkStats.totalRequests) * 100).toStringAsFixed(1)}%'
            : '0%'
        ),
        _buildMetricRow('Avg Response', '${networkStats.averageResponseTimeMs.toStringAsFixed(1)}ms'),
        _buildMetricRow('95th Percentile', '${networkStats.p95ResponseTimeMs}ms'),
      ],
    );
  }

  Widget _buildMemoryMetrics() {
    final memoryStats = _monitor.getMemoryStats();

    return Column(
      children: [
        _buildMetricRow('Current Usage', '${(memoryStats.currentUsageBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
        _buildMetricRow('Peak Usage', '${(memoryStats.peakUsageBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
        _buildMetricRow('Average Usage', '${(memoryStats.averageUsageBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
        _buildMetricRow('Samples', memoryStats.sampleCount.toString()),
      ],
    );
  }

  Widget _buildOperationMetrics() {
    final stats = _monitor.getAllStats();
    final topOperations = stats.values.toList()
      ..sort((a, b) => b.averageMs.compareTo(a.averageMs))
      ..take(3);

    return Column(
      children: topOperations.map((stat) =>
        _buildMetricRow(
          stat.operationName.length > 20
            ? '${stat.operationName.substring(0, 20)}...'
            : stat.operationName,
          '${stat.averageMs.toStringAsFixed(1)}ms (${stat.count})'
        )
      ).toList(),
    );
  }

  Widget _buildAlertsSection() {
    final alerts = _monitor.getActiveAlerts();

    if (alerts.isEmpty) {
      return Text(
        'No active alerts',
        style: ResponsiveTextUtils.getResponsiveTextStyle(
          context,
          'bodyMedium',
          color: Colors.green,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Alerts',
          style: ResponsiveTextUtils.getResponsiveTextStyle(
            context,
            'bodyMedium',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
        ...alerts.map((alert) => Container(
          margin: EdgeInsets.only(bottom: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
          padding: ResponsiveConstants.getResponsivePadding(context, 'sm'),
          decoration: BoxDecoration(
            color: _getAlertColor(alert.severity),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: ResponsiveTextUtils.getResponsiveTextStyle(
                  context,
                  'bodySmall',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                alert.message,
                style: ResponsiveTextUtils.getResponsiveTextStyle(
                  context,
                  'labelSmall',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _monitor.logReport(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
            ),
            child: Text('Log Report', style: ResponsiveTextUtils.getResponsiveTextStyle(context, 'bodySmall')),
          ),
        ),
        SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _monitor.clearMetrics(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
            ),
            child: Text('Clear Data', style: ResponsiveTextUtils.getResponsiveTextStyle(context, 'bodySmall')),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ResponsiveTextUtils.getResponsiveTextStyle(
              context,
              'bodySmall',
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: ResponsiveTextUtils.getResponsiveTextStyle(
              context,
              'bodySmall',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.error:
        return Colors.red.shade700;
      case AlertSeverity.warning:
        return Colors.orange.shade700;
      case AlertSeverity.info:
        return Colors.blue.shade700;
    }
  }
}

/// Widget that automatically tracks rebuilds
class PerformanceTrackedWidget extends StatefulWidget {
  final Widget child;
  final String widgetName;

  const PerformanceTrackedWidget({
    super.key,
    required this.child,
    required this.widgetName,
  });

  @override
  State<PerformanceTrackedWidget> createState() => _PerformanceTrackedWidgetState();
}

class _PerformanceTrackedWidgetState extends State<PerformanceTrackedWidget> {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    _monitor.trackWidgetRebuild(widget.widgetName);
    return widget.child;
  }
}
