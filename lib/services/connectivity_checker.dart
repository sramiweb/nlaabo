import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/app_config.dart';

/// Service to check backend connectivity and provide helpful diagnostics
class ConnectivityChecker {

  /// Check if Supabase is reachable
  static Future<ConnectivityResult> checkSupabaseConnectivity() async {
    final networkConfig = AppConfig.instance.network;

    try {
      final url = await supabaseUrl;
      if (url.isEmpty) {
        return ConnectivityResult.configurationError;
      }

      final response = await http.get(
        Uri.parse('$url/rest/v1/'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': await supabaseAnonKey,
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



  /// Get a user-friendly message for the connectivity result
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
    }
  }
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
}
