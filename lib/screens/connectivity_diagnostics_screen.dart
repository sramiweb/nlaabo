import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../widgets/directional_icon.dart';

class ConnectivityDiagnosticsScreen extends StatefulWidget {
  const ConnectivityDiagnosticsScreen({super.key});

  @override
  State<ConnectivityDiagnosticsScreen> createState() =>
      _ConnectivityDiagnosticsScreenState();
}

class _ConnectivityDiagnosticsScreenState
    extends State<ConnectivityDiagnosticsScreen> {
  bool _isLoading = true;
  String? _diagnosticsResult;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      final result = await ConnectivityService.runDiagnostics();
      setState(() {
        _isLoading = false;
        _diagnosticsResult = result.details;
        _hasError = !result.success;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running diagnostics...'),
                  ],
                ),
              )
            : _hasError
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diagnostics failed to run:',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage ?? 'Unknown error'),
                      const SizedBox(height: 16),
                      const Text('Troubleshooting steps:'),
                      const Text('• Check your internet connection'),
                      const Text('• Verify .env file is properly configured'),
                      const Text('• Ensure Supabase credentials are valid'),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_diagnosticsResult ?? 'No results available'),
                        const SizedBox(height: 16),
                        const Text(
                          'Actionable Feedback:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _getActionableFeedback(_diagnosticsResult!),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _getActionableFeedback(String result) {
    final suggestions = <String>[];

    if (result.contains('❌ SUPABASE_URL is empty')) {
      suggestions.add('• Check your .env file and ensure SUPABASE_URL is set');
    }
    if (result.contains('❌ SUPABASE_ANON_KEY is empty')) {
      suggestions
          .add('• Check your .env file and ensure SUPABASE_ANON_KEY is set');
    }
    if (result.contains('❌ No internet connection')) {
      suggestions.add('• Verify your internet connection and try again');
    }
    if (result.contains('❌ DNS resolution failed')) {
      suggestions.add('• Check DNS settings or try using a different network');
    }
    if (result.contains('❌ Supabase connection failed')) {
      suggestions.add('• Verify Supabase URL and API key are correct');
      suggestions.add('• Check if Supabase service is operational');
    }
    if (result.contains('✅') && !result.contains('❌')) {
      suggestions.add(
          '• All checks passed! The issue may be temporary. Try restarting the app.');
    }

    if (suggestions.isEmpty) {
      suggestions.add(
          '• Review the diagnostic results above for any warnings or errors.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((s) => Text(s)).toList(),
    );
  }
}
