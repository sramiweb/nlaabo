import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_router.dart';
import 'config/app_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'widgets/smart_error_boundary.dart';
import 'services/error_reporting_service.dart';
import 'services/robust_supabase_client.dart';
import 'services/connectivity_service.dart';
import 'services/secure_credential_service.dart';
import 'utils/app_initialization_utils.dart';
import 'config/app_config.dart';
import 'config/build_config.dart';
import 'config/web_config.dart';

enum AppInitializationError {
  configurationMissing,
  configurationInvalid,
  networkUnavailable,
  supabaseUnreachable,
  unknown,
}

class NlaaboBootstrap extends StatefulWidget {
  const NlaaboBootstrap({super.key});

  @override
  State<NlaaboBootstrap> createState() => _NlaaboBootstrapState();
}

class _NlaaboBootstrapState extends State<NlaaboBootstrap> {
  bool _isInitializing = true;
  AppInitializationError? _errorType;
  bool _canRetry = false;
  bool _showDiagnostics = false;
  bool _isRunningDiagnostics = false;
  String? _diagnosticsResult;
  bool _diagnosticsHasError = false;
  String? _diagnosticsErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isInitializing = true;
      _errorType = null;
      _canRetry = false;
      _showDiagnostics = false;
      _diagnosticsResult = null;
      _diagnosticsHasError = false;
      _diagnosticsErrorMessage = null;
    });

    try {
      // Load .env file first with better error handling
      try {
        await dotenv.load(fileName: '.env');
        debugPrint('Successfully loaded .env file');
      } catch (e) {
        debugPrint('Failed to load .env file: $e');
        throw Exception('Failed to load .env file: $e');
      }

      // Check if credentials are initialized in secure storage
      final credentialsInitialized =
          await SecureCredentialService.areCredentialsInitialized();

      if (!credentialsInitialized) {
        // Initialize with credentials from .env
        final url = dotenv.env['SUPABASE_URL'];
        final key = dotenv.env['SUPABASE_ANON_KEY'];

        if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
          await SecureCredentialService.initializeCredentials(
            supabaseUrl: url,
            supabaseAnonKey: key,
          );
          debugPrint('Initialized credentials from .env to secure storage');
        } else {
          throw Exception(
              'No credentials found in .env file. SUPABASE_URL and SUPABASE_ANON_KEY must be set.');
        }
      }

      // Validate credentials in secure storage
      final validationResult =
          await SecureCredentialService.validateCredentials();
      if (!validationResult.isValid) {
        throw Exception(
            'Invalid Supabase credentials: ${validationResult.error}');
      }

      // Initialize AppConfig
      await AppConfig.initialize(environment: BuildConfig.environment);

      // Initialize web-specific configuration if running on web
      if (kIsWeb) {
        await WebConfig.initialize();
      }

      // Initialize error reporting service
      final errorReportingService = ErrorReportingService();
      await errorReportingService.initialize();

      // Initialize Supabase with robust client (consolidated)
      await RobustSupabaseClient.initialize();

      // Initialize localization service
      await AppInitializationUtils.loadInitialLanguage();

      // Success - show main app
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('App initialization failed: $e');
      final errorMessage = e.toString();
      final errorType = _classifyError(errorMessage);

      setState(() {
        _isInitializing = false;
        _errorType = errorType;
        _canRetry = true;
      });
    }
  }

  AppInitializationError _classifyError(String errorMessage) {
    debugPrint('Classifying error: $errorMessage');

    if (errorMessage.contains('Failed to load .env file') ||
        errorMessage.contains('FileNotFoundError')) {
      return AppInitializationError.configurationMissing;
    }
    if (errorMessage.contains('SUPABASE_URL') ||
        errorMessage.contains('SUPABASE_ANON_KEY')) {
      return AppInitializationError.configurationMissing;
    }
    if (errorMessage.contains('Configuration') ||
        errorMessage.contains('AppConfig') ||
        errorMessage.contains('validation failed')) {
      return AppInitializationError.configurationInvalid;
    }
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('internet')) {
      return AppInitializationError.networkUnavailable;
    }
    if (errorMessage.contains('Supabase') || errorMessage.contains('server')) {
      return AppInitializationError.supabaseUnreachable;
    }
    return AppInitializationError.unknown;
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticsResult = null;
      _diagnosticsHasError = false;
      _diagnosticsErrorMessage = null;
    });

    try {
      final result = await ConnectivityService.runDiagnostics();
      setState(() {
        _isRunningDiagnostics = false;
        _diagnosticsResult = result.details;
        _diagnosticsHasError = !result.success;
        _showDiagnostics = true;
      });
    } catch (e) {
      setState(() {
        _isRunningDiagnostics = false;
        _diagnosticsHasError = true;
        _diagnosticsErrorMessage = e.toString();
        _showDiagnostics = true;
      });
    }
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

  IconData _getErrorIcon(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
      case AppInitializationError.configurationInvalid:
        return Icons.settings;
      case AppInitializationError.networkUnavailable:
        return Icons.wifi_off;
      case AppInitializationError.supabaseUnreachable:
        return Icons.cloud_off;
      case AppInitializationError.unknown:
        return Icons.error;
    }
  }

  Color _getErrorColor(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
      case AppInitializationError.configurationInvalid:
        return Colors.red;
      case AppInitializationError.networkUnavailable:
        return Colors.orange;
      case AppInitializationError.supabaseUnreachable:
        return Colors.blue;
      case AppInitializationError.unknown:
        return Colors.grey;
    }
  }

  String _getErrorTitle(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
        return 'Configuration Missing';
      case AppInitializationError.configurationInvalid:
        return 'Configuration Error';
      case AppInitializationError.networkUnavailable:
        return 'Network Unavailable';
      case AppInitializationError.supabaseUnreachable:
        return 'Server Unreachable';
      case AppInitializationError.unknown:
        return 'Initialization Error';
    }
  }

  String _getErrorMessage(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
        return 'Required configuration is missing.\nPlease check your .env file exists and contains SUPABASE_URL and SUPABASE_ANON_KEY variables.';
      case AppInitializationError.configurationInvalid:
        return 'Configuration is invalid.\nPlease verify your settings and try again.';
      case AppInitializationError.networkUnavailable:
        return 'Network connection is unavailable.\nPlease check your internet connection and try again.';
      case AppInitializationError.supabaseUnreachable:
        return 'Cannot connect to Nlaabo servers.\nThe service may be temporarily unavailable.';
      case AppInitializationError.unknown:
        return 'An unexpected error occurred during initialization.\nPlease try again or contact support.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing Nlaabo...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorType != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getErrorIcon(_errorType!),
                      size: 64,
                      color: _getErrorColor(_errorType!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getErrorTitle(_errorType!),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getErrorMessage(_errorType!),
                      textAlign: TextAlign.center,
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Debug Info:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Error Type: ${_errorType.toString()}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_canRetry)
                      ElevatedButton(
                        onPressed: _initializeApp,
                        child: const Text('Retry'),
                      ),
                    const SizedBox(height: 8),
                    if (!_showDiagnostics)
                      TextButton(
                        onPressed: _runDiagnostics,
                        child: const Text('Show Details'),
                      )
                    else if (_isRunningDiagnostics)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Running diagnostics...'),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text(
                            'Network Diagnostics:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_diagnosticsHasError)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diagnostics failed to run:',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(_diagnosticsErrorMessage ??
                                    'Unknown error'),
                                const SizedBox(height: 16),
                                const Text('Troubleshooting steps:'),
                                const Text('• Check your internet connection'),
                                const Text(
                                    '• Verify .env file is properly configured'),
                                const Text(
                                    '• Ensure Supabase credentials are valid'),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_diagnosticsResult ??
                                    'No results available'),
                                const SizedBox(height: 16),
                                const Text(
                                  'Actionable Feedback:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                _getActionableFeedback(_diagnosticsResult!),
                              ],
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showDiagnostics = false;
                              });
                            },
                            child: const Text('Hide Details'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Success - show main app
    return SmartErrorBoundary(
      enableReporting: true,
      enableAutoRecovery: true,
      context: 'NlaaboApp',
      child: MultiProvider(
        providers: getAppProviders(),
        child: const NlaaboApp(),
      ),
    );
  }
}

class NlaaboApp extends StatelessWidget {
  const NlaaboApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationProvider = context.watch<LocalizationProvider>();

    return MaterialApp.router(
      key: ValueKey(localizationProvider.currentLanguage),
      title: 'Nlaabo',
      debugShowCheckedModeBanner: false,
      locale: localizationProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(clampDouble(
              MediaQuery.of(context).textScaler.scale(1.0),
              0.8,
              1.2,
            )),
          ),
          child: Directionality(
            textDirection: localizationProvider.textDirection,
            child: child!,
          ),
        );
      },
      theme: context.watch<ThemeProvider>().themeData,
      darkTheme: context.watch<ThemeProvider>().themeData,
      themeMode: context.watch<ThemeProvider>().themeMode,
      routerConfig: router,
    );
  }
}
