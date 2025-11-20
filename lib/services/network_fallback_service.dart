import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/app_config.dart';

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

/// Service to handle network connectivity issues and provide fallback mechanisms
class NetworkFallbackService {
  
  /// Test network connectivity with multiple fallback mechanisms
  static Future<NetworkStatus> checkConnectivity() async {
    final results = <String>[];
    
    // 1. Test basic internet connectivity
    final internetStatus = await _testInternetConnectivity();
    results.add('Internet: ${internetStatus.message}');
    
    if (!internetStatus.isConnected) {
      return NetworkStatus(
        isConnected: false,
        canReachSupabase: false,
        message: 'No internet connection available',
        details: results.join('\n'),
        failureType: NetworkFailureType.noInternet,
      );
    }
    
    // 2. Test DNS resolution for Supabase
    final dnsStatus = await _testDNSResolution();
    results.add('DNS: ${dnsStatus.message}');
    
    // 3. Test Supabase connectivity
    final supabaseStatus = await _testSupabaseConnectivity();
    results.add('Supabase: ${supabaseStatus.message}');
    
    NetworkFailureType? failureType;
    if (!supabaseStatus.isConnected) {
      if (dnsStatus.message.contains('DNS resolution failed') || dnsStatus.message.contains('cannot resolve')) {
        failureType = NetworkFailureType.dnsResolutionFailed;
      } else if (supabaseStatus.message.contains('unreachable') || supabaseStatus.message.contains('timeout')) {
        failureType = NetworkFailureType.supabaseUnreachable;
      } else if (supabaseStatus.message.contains('status 5')) {
        failureType = NetworkFailureType.serverError;
      } else {
        failureType = NetworkFailureType.unknownError;
      }
    }

    // Improve failure type detection
    if (!supabaseStatus.isConnected) {
      if (dnsStatus.message.contains('DNS resolution failed') || dnsStatus.message.contains('cannot resolve')) {
        failureType = NetworkFailureType.dnsResolutionFailed;
      } else if (supabaseStatus.message.contains('timeout') || supabaseStatus.message.contains('TimeoutException')) {
        failureType = NetworkFailureType.networkTimeout;
      } else if (supabaseStatus.message.contains('unreachable') || supabaseStatus.message.contains('Connection refused')) {
        failureType = NetworkFailureType.supabaseUnreachable;
      } else if (supabaseStatus.message.contains('status 5')) {
        failureType = NetworkFailureType.serverError;
      } else {
        failureType = NetworkFailureType.unknownError;
      }
    }

    return NetworkStatus(
      isConnected: internetStatus.isConnected,
      canReachSupabase: supabaseStatus.isConnected,
      message: supabaseStatus.isConnected
          ? 'All connectivity tests passed'
          : 'Supabase connectivity issues detected',
      details: results.join('\n'),
      failureType: failureType,
    );
  }
  
  /// Test basic internet connectivity
  static Future<ConnectivityResult> _testInternetConnectivity() async {
    final networkConfig = AppConfig.instance.network;

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
          return ConnectivityResult(
            isConnected: true,
            message: 'Internet connection verified via $url',
          );
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
        return ConnectivityResult(
          isConnected: true,
          message: 'Internet connection verified via DNS lookup',
        );
      }
    } catch (e) {
      debugPrint('DNS lookup failed: $e');
    }
    
    return ConnectivityResult(
      isConnected: false,
      message: 'No internet connection - all connectivity tests failed',
    );
  }
  
  /// Test DNS resolution for Supabase with fallback DNS servers
  static Future<ConnectivityResult> _testDNSResolution() async {
    final networkConfig = AppConfig.instance.network;

    try {
      final url = await supabaseUrl;
      if (url.isEmpty) {
        return ConnectivityResult(
          isConnected: false,
          message: 'Supabase URL not configured',
        );
      }

      final uri = Uri.parse(url);

      // Try multiple DNS resolution methods
      try {
        final addresses = await InternetAddress.lookup(uri.host).timeout(networkConfig.dnsTimeout);
        if (addresses.isNotEmpty) {
          return ConnectivityResult(
            isConnected: true,
            message: 'DNS resolution successful for ${uri.host} (${addresses.length} addresses)',
          );
        }
      } catch (e) {
        debugPrint('Primary DNS lookup failed: $e');
      }

      // Fallback: Try resolving google.com to test DNS functionality
      try {
        final testAddresses = await InternetAddress.lookup('google.com').timeout(networkConfig.dnsTimeout);
        if (testAddresses.isNotEmpty) {
          return ConnectivityResult(
            isConnected: false,
            message: 'DNS works but cannot resolve ${uri.host} - possible network filtering',
          );
        }
      } catch (e) {
        debugPrint('Fallback DNS test failed: $e');
      }
      
      return ConnectivityResult(
        isConnected: false,
        message: 'DNS resolution failed for ${uri.host} - possible network filtering or DNS server issues',
      );
    } catch (e) {
      return ConnectivityResult(
        isConnected: false,
        message: 'DNS resolution error: $e',
      );
    }
  }
  
  /// Test Supabase connectivity with retries
  static Future<ConnectivityResult> _testSupabaseConnectivity() async {
    final networkConfig = AppConfig.instance.network;
    final url = await supabaseUrl;
    final key = await supabaseAnonKey;

    if (url.isEmpty || key.isEmpty) {
      return ConnectivityResult(
        isConnected: false,
        message: 'Supabase credentials not configured',
      );
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
          return ConnectivityResult(
            isConnected: true,
            message: 'Supabase server reachable (attempt $attempt)',
          );
        } else {
          debugPrint('Supabase returned status ${response.statusCode} on attempt $attempt');
        }
      } catch (e) {
        debugPrint('Supabase connection attempt $attempt failed: $e');
        if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
          return ConnectivityResult(
            isConnected: false,
            message: 'Supabase connection timeout after ${networkConfig.maxRetries} attempts',
          );
        }
        if (attempt < networkConfig.maxRetries) {
          // Progressive delay for WiFi stability
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    return ConnectivityResult(
      isConnected: false,
      message: 'Supabase server unreachable after ${networkConfig.maxRetries} attempts',
    );
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

class ConnectivityResult {
  final bool isConnected;
  final String message;
  
  ConnectivityResult({
    required this.isConnected,
    required this.message,
  });
}
