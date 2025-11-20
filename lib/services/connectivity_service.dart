import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/app_config.dart';

// Cache entry for connectivity results
class ConnectivityCacheEntry {
  final ConnectivityResult result;
  final DateTime timestamp;

  ConnectivityCacheEntry({
    required this.result,
    required this.timestamp,
  });
}

/// Enum for specific network failure types
enum NetworkFailureType {
  noInternet,
  dnsResolutionFailed,
  supabaseUnreachable,
  networkTimeout,
  serverError,
  configurationError,
  unknownError,
}

/// Unified service for network connectivity checks, diagnostics, and error handling
class ConnectivityService {
  /// Test network connectivity with multiple fallback mechanisms
  static Future<NetworkStatus> checkConnectivity() async {
    final results = <String>[];

    // 1. Test basic internet connectivity
    final internetResult = await _testInternetConnectivity();
    results.add('Internet: ${getConnectivityMessage(internetResult)}');

    if (internetResult != ConnectivityResult.success) {
      return NetworkStatus(
        isConnected: false,
        canReachSupabase: false,
        message: 'No internet connection available',
        details: results.join('\n'),
        failureType: NetworkFailureType.noInternet,
      );
    }

    // 2. Test DNS resolution for Supabase
    final dnsResult = await _testDNSResolution();
    results.add('DNS: ${getConnectivityMessage(dnsResult)}');

    // 3. Test Supabase connectivity
    final supabaseResult = await _testSupabaseConnectivity();
    results.add('Supabase: ${getConnectivityMessage(supabaseResult)}');

    NetworkFailureType? failureType;
    if (supabaseResult != ConnectivityResult.success) {
      switch (dnsResult) {
        case ConnectivityResult.hostLookupFailed:
          failureType = NetworkFailureType.dnsResolutionFailed;
          break;
        case ConnectivityResult.networkTimeout:
          failureType = NetworkFailureType.networkTimeout;
          break;
        case ConnectivityResult.connectionRefused:
        case ConnectivityResult.networkUnreachable:
          failureType = NetworkFailureType.supabaseUnreachable;
          break;
        case ConnectivityResult.serverError:
          failureType = NetworkFailureType.serverError;
          break;
        default:
          failureType = NetworkFailureType.unknownError;
      }
    }

    return NetworkStatus(
      isConnected: internetResult == ConnectivityResult.success,
      canReachSupabase: supabaseResult == ConnectivityResult.success,
      message: supabaseResult == ConnectivityResult.success
          ? 'All connectivity tests passed'
          : 'Supabase connectivity issues detected',
      details: results.join('\n'),
      failureType: failureType,
    );
  }

  /// Check if Supabase is reachable (simplified check)
  static Future<ConnectivityResult> checkSupabaseConnectivity() async {
    final networkConfig = AppConfig.instance.network;

    try {
      final url = await supabaseUrl;
      final key = await supabaseAnonKey;
      
      if (url.isEmpty || key.isEmpty) {
        return ConnectivityResult.configurationError;
      }

      final response = await http.get(
        Uri.parse('$url/rest/v1/'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': key,
        },
      ).timeout(networkConfig.supabaseTimeout);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return ConnectivityResult.success;
      } else {
        return ConnectivityResult.serverError;
      }
    } on SocketException catch (e) {
      if (e.message.contains('Failed host lookup')) {
        return ConnectivityResult.hostLookupFailed;
      } else if (e.message.contains('Connection refused')) {
        return ConnectivityResult.connectionRefused;
      } else if (e.message.contains('Network is unreachable')) {
        return ConnectivityResult.networkUnreachable;
      } else {
        return ConnectivityResult.networkError;
      }
    } on HttpException {
      return ConnectivityResult.httpError;
    } on FormatException {
      return ConnectivityResult.invalidResponse;
    } catch (e) {
      return ConnectivityResult.unknownError;
    }
  }

  /// Run comprehensive network diagnostics
  static Future<DiagnosticResult> runDiagnostics() async {
    final networkConfig = AppConfig.instance.network;
    final results = <String>[];
    bool hasErrors = false;

    // 1. Check environment configuration with graceful error handling
    results.add('=== Environment Configuration ===');

    // Check if dotenv has been loaded
    bool dotenvLoaded = false;
    try {
      // Try to access any env var to check if dotenv is loaded
      dotenv.env['TEST_VAR']; // This will throw if dotenv is not loaded
      dotenvLoaded = true;
    } catch (e) {
      dotenvLoaded = false;
    }

    if (!dotenvLoaded) {
      results.add('❌ Environment variables not loaded (.env file not processed)');
      results.add('   This usually means dotenv.load() was not called or failed');
      hasErrors = true;
    } else {
      results.add('✅ Environment variables loaded successfully');
    }

    // Safely get configuration values with exception handling
    String? supabaseUrlValue;
    String? supabaseKeyValue;
    bool configError = false;

    try {
      supabaseUrlValue = await supabaseUrl;
    } catch (e) {
      results.add('❌ SUPABASE_URL access failed: ${e.toString()}');
      configError = true;
      hasErrors = true;
    }

    try {
      supabaseKeyValue = await supabaseAnonKey;
    } catch (e) {
      results.add('❌ SUPABASE_ANON_KEY access failed: ${e.toString()}');
      configError = true;
      hasErrors = true;
    }

    if (!configError) {
      if (supabaseUrlValue == null || supabaseUrlValue.isEmpty) {
        results.add('❌ SUPABASE_URL is empty or not loaded');
        hasErrors = true;
      } else {
        results.add('✅ SUPABASE_URL: ${supabaseUrlValue.substring(0, 30)}...');
      }

      if (supabaseKeyValue == null || supabaseKeyValue.isEmpty) {
        results.add('❌ SUPABASE_ANON_KEY is empty or not loaded');
        hasErrors = true;
      } else {
        // Mask the key for security - show only first 8 and last 4 characters
        final maskedKey = supabaseKeyValue.length > 12
            ? '${supabaseKeyValue.substring(0, 8)}${'*' * (supabaseKeyValue.length - 12)}${supabaseKeyValue.substring(supabaseKeyValue.length - 4)}'
            : '****${supabaseKeyValue.substring(supabaseKeyValue.length - 4)}';
        results.add('✅ SUPABASE_ANON_KEY: $maskedKey');
      }
    }

    // 2. Check internet connectivity
    results.add('\n=== Internet Connectivity ===');
    try {
      final response = await http.get(
        Uri.parse(networkConfig.testUrls.first),
      ).timeout(networkConfig.diagnosticsTimeout);

      if (response.statusCode == 200) {
        results.add('✅ Internet connection is working');
      } else {
        results.add('⚠️ Internet connection issue (status: ${response.statusCode})');
        hasErrors = true;
      }
    } catch (e) {
      results.add('❌ No internet connection: $e');
      hasErrors = true;
    }

    // 3. Check DNS resolution for Supabase (only if config is available)
    if (supabaseUrlValue != null && supabaseUrlValue.isNotEmpty && supabaseKeyValue != null && supabaseKeyValue.isNotEmpty) {
      results.add('\n=== DNS Resolution ===');
      try {
        final uri = Uri.parse(supabaseUrlValue);
        final addresses = await InternetAddress.lookup(uri.host);
        if (addresses.isNotEmpty) {
          results.add('✅ DNS resolution successful for ${uri.host}');
          results.add('   IP addresses: ${addresses.map((a) => a.address).join(', ')}');
        } else {
          results.add('❌ DNS resolution failed for ${uri.host}');
          hasErrors = true;
        }
      } catch (e) {
        results.add('❌ DNS lookup error: $e');
        hasErrors = true;
      }

      // 4. Check Supabase connectivity
      results.add('\n=== Supabase Connectivity ===');
      try {
        final response = await http.get(
          Uri.parse('$supabaseUrlValue/rest/v1/'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKeyValue,
          },
        ).timeout(networkConfig.supabaseTimeout);

        if (response.statusCode == 200 || response.statusCode == 404) {
          results.add('✅ Supabase server is reachable');
          results.add('   Response status: ${response.statusCode}');
        } else {
          results.add('⚠️ Supabase server responded with status: ${response.statusCode}');
          results.add('   Response: ${response.body.substring(0, 100)}...');
        }
      } catch (e) {
        results.add('❌ Supabase connection failed: $e');
        hasErrors = true;
      }
    } else {
      results.add('\n=== DNS Resolution & Supabase Connectivity ===');
      results.add('⚠️ Skipped - Configuration not available');
      results.add('   Fix configuration issues above first');
    }

    // 5. Platform information
    results.add('\n=== Platform Information ===');
    results.add('Platform: ${Platform.operatingSystem}');
    results.add('Debug mode: $kDebugMode');

    return DiagnosticResult(
      success: !hasErrors,
      details: results.join('\n'),
    );
  }

  /// Test basic internet connectivity with caching
  static Future<ConnectivityResult> _testInternetConnectivity() async {
    final networkConfig = AppConfig.instance.network;

    // Check cache first (cache for 30 seconds)
    const cacheKey = 'internet_connectivity';
    final cached = _connectivityCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.timestamp) < const Duration(seconds: 30)) {
      return cached.result;
    }

    for (final url in networkConfig.testUrls) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Nlaabo/1.0',
            'Connection': 'close',
          },
        ).timeout(networkConfig.connectivityTestTimeout);

        if (response.statusCode >= 200 && response.statusCode < 400) {
          // Cache successful result
          _connectivityCache[cacheKey] = ConnectivityCacheEntry(
            result: ConnectivityResult.success,
            timestamp: DateTime.now(),
          );
          return ConnectivityResult.success;
        }
      } catch (e) {
        debugPrint('Failed to connect to $url: $e');
        continue;
      }
    }

    // Final DNS test as fallback
    try {
      final addresses = await InternetAddress.lookup('google.com')
          .timeout(networkConfig.dnsTimeout);
      if (addresses.isNotEmpty) {
        // Cache successful result
        _connectivityCache[cacheKey] = ConnectivityCacheEntry(
          result: ConnectivityResult.success,
          timestamp: DateTime.now(),
        );
        return ConnectivityResult.success;
      }
    } catch (e) {
      debugPrint('DNS lookup failed: $e');
    }

    // Cache failed result for shorter duration (10 seconds)
    _connectivityCache[cacheKey] = ConnectivityCacheEntry(
      result: ConnectivityResult.networkUnreachable,
      timestamp: DateTime.now(),
    );
    return ConnectivityResult.networkUnreachable;
  }

  // Cache for connectivity results
  static final Map<String, ConnectivityCacheEntry> _connectivityCache = {};

  /// Test DNS resolution for Supabase with fallback DNS servers
  static Future<ConnectivityResult> _testDNSResolution() async {
    final networkConfig = AppConfig.instance.network;

    try {
      final url = await supabaseUrl;
      if (url.isEmpty) {
        return ConnectivityResult.configurationError;
      }

      final uri = Uri.parse(url);

      // Try multiple DNS resolution methods
      try {
        final addresses = await InternetAddress.lookup(uri.host).timeout(networkConfig.dnsTimeout);
        if (addresses.isNotEmpty) {
          return ConnectivityResult.success;
        }
      } catch (e) {
        debugPrint('Primary DNS lookup failed: $e');
      }

      // Fallback: Try resolving google.com to test DNS functionality
      try {
        final testAddresses = await InternetAddress.lookup('google.com').timeout(networkConfig.dnsTimeout);
        if (testAddresses.isNotEmpty) {
          return ConnectivityResult.hostLookupFailed;
        }
      } catch (e) {
        debugPrint('Fallback DNS test failed: $e');
      }

      return ConnectivityResult.hostLookupFailed;
    } catch (e) {
      return ConnectivityResult.hostLookupFailed;
    }
  }

  /// Test Supabase connectivity with retries
  static Future<ConnectivityResult> _testSupabaseConnectivity() async {
    final networkConfig = AppConfig.instance.network;
    final url = await supabaseUrl;
    final key = await supabaseAnonKey;

    if (url.isEmpty || key.isEmpty) {
      return ConnectivityResult.configurationError;
    }

    for (int attempt = 1; attempt <= networkConfig.maxRetries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('$url/rest/v1/'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': key,
            'User-Agent': 'Nlaabo/1.0',
            'Connection': 'close',
          },
        ).timeout(networkConfig.supabaseTimeout);

        if (response.statusCode >= 200 && response.statusCode < 500) {
          return ConnectivityResult.success;
        } else {
          debugPrint('Supabase returned status ${response.statusCode} on attempt $attempt');
        }
      } catch (e) {
        debugPrint('Supabase connection attempt $attempt failed: $e');
        if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
          return ConnectivityResult.networkTimeout;
        }
        if (attempt < networkConfig.maxRetries) {
          // Progressive delay for WiFi stability
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    return ConnectivityResult.connectionRefused;
  }

  /// Get user-friendly error message and suggestions
  static String getErrorMessageAndSuggestions(NetworkStatus status) {
    if (status.failureType == null) {
      return 'Connection successful';
    }

    switch (status.failureType!) {
      case NetworkFailureType.noInternet:
        return '''
No internet connection detected.

This means your device cannot reach the internet at all.

Step-by-step troubleshooting:
1. Check if WiFi or mobile data is enabled
2. Verify Airplane mode is turned off
3. Test with a different network (e.g., switch from WiFi to mobile data)
4. Restart your device and try again
5. Check network settings in your device configuration
6. If using WiFi, ensure you're connected to the correct network and password is correct
7. Contact your network administrator or ISP if the issue persists

Alternative actions:
• Try using a VPN if you suspect network restrictions
• Check if other devices on the same network have internet access
''';

      case NetworkFailureType.dnsResolutionFailed:
        return '''
DNS resolution failed for Nlaabo servers.

Your device can connect to the internet but cannot resolve the server address.

Step-by-step troubleshooting:
1. Check your DNS settings (try switching to public DNS like 8.8.8.8 or 1.1.1.1)
2. Restart your router or modem
3. Try using a different network (mobile data vs WiFi)
4. Clear your device's DNS cache if possible
5. Check if the issue is specific to this app by testing other websites
6. If using a VPN, try disabling it temporarily

Alternative actions:
• Use a different DNS service in your network settings
• Contact your ISP if DNS issues persist across networks
''';

      case NetworkFailureType.supabaseUnreachable:
        return '''
Cannot reach Nlaabo servers (connection timeout or unreachable).

The servers may be temporarily unavailable or there may be a network issue.

Step-by-step troubleshooting:
1. Wait a few minutes and try again (servers may be under maintenance)
2. Check if other apps or websites work normally
3. Try switching between WiFi and mobile data
4. Restart your device to refresh network connections
5. Check for any firewall or security software blocking the connection
6. Verify your device's date and time settings are correct

Alternative actions:
• Try using a VPN to bypass potential regional restrictions
• Check the Nlaabo status page or social media for known outages
• Contact support if the issue persists for more than 30 minutes
''';

      case NetworkFailureType.networkTimeout:
        return '''
Network request timed out.

The connection is slow or unstable, causing requests to fail.

Step-by-step troubleshooting:
1. Check your internet speed (try a speed test app or website)
2. Move closer to your WiFi router if using wireless
3. Reduce network congestion by closing other apps
4. Try switching to a different network with better signal
5. Restart your router or modem
6. Check for background apps consuming bandwidth

Alternative actions:
• Use a wired connection if possible for more stability
• Wait for peak hours to pass if the network is congested
• Contact your ISP if timeouts persist
''';

      case NetworkFailureType.serverError:
        return '''
Server error detected (5xx response).

The Nlaabo servers are experiencing issues.

Step-by-step troubleshooting:
1. Wait a few minutes and try again (temporary server issues)
2. Check if the issue affects other users (social media, status page)
3. Clear the app cache and data if possible
4. Try using the app on a different device or network
5. Restart the app completely

Alternative actions:
• Check the Nlaabo website or support channels for service status
• Contact support with details about when the error occurs
• The issue is likely on the server side and should resolve soon
''';

      case NetworkFailureType.configurationError:
        return '''
Configuration error detected.

There may be an issue with the app or server configuration.

Step-by-step troubleshooting:
1. Ensure the app is updated to the latest version
2. Check if your device meets the app requirements
3. Clear app cache and restart the app
4. Try logging out and back in
5. Check for any system updates on your device

Alternative actions:
• Reinstall the app if issues persist
• Contact support with your device and app version details
• This may require an app update to fix
''';

      case NetworkFailureType.unknownError:
        return '''
An unknown network error occurred.

This is a general error that doesn't match common issues.

Step-by-step troubleshooting:
1. Restart the app and try again
2. Restart your device
3. Check for app updates
4. Try on a different network
5. Clear app cache and data
6. Check device storage and memory availability

Alternative actions:
• Try using the app in safe mode if available
• Contact support with detailed error information
• Provide details about your device, network, and when the error occurs
''';
    }
  }

  /// Get a user-friendly message for the connectivity result (for simple checks)
  static String getConnectivityMessage(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.success:
        return 'Server is running and accessible';
      case ConnectivityResult.connectionRefused:
        return 'Cannot connect to server. Please check your connection.';
      case ConnectivityResult.networkUnreachable:
        return 'Network connection issue. Please check your internet connection.';
      case ConnectivityResult.serverError:
        return 'Server is running but returning errors. Please try again later.';
      case ConnectivityResult.httpError:
        return 'HTTP protocol error. Please try again.';
      case ConnectivityResult.invalidResponse:
        return 'Invalid response from server. Please try again.';
      case ConnectivityResult.networkError:
        return 'Network error occurred. Please try again.';
      case ConnectivityResult.hostLookupFailed:
        return 'Cannot resolve server hostname. Please check your internet connection and DNS settings.';
      case ConnectivityResult.configurationError:
        return 'Configuration error. Please check your environment settings.';
      case ConnectivityResult.unknownError:
        return 'Unknown connectivity issue. Please check server status.';
      case ConnectivityResult.networkTimeout:
        return 'Network request timed out. Please check your connection.';
      // No default case needed as all enum values are covered
    }
  }
}

class NetworkStatus {
  final bool isConnected;
  final bool canReachSupabase;
  final String message;
  final String details;
  final NetworkFailureType? failureType;

  NetworkStatus({
    required this.isConnected,
    required this.canReachSupabase,
    required this.message,
    required this.details,
    this.failureType,
  });
}

enum ConnectivityResult {
  success,
  connectionRefused,
  networkUnreachable,
  serverError,
  httpError,
  invalidResponse,
  networkError,
  hostLookupFailed,
  configurationError,
  unknownError,
  networkTimeout,
}

class DiagnosticResult {
  final bool success;
  final String details;

  DiagnosticResult({
    required this.success,
    required this.details,
  });
}
