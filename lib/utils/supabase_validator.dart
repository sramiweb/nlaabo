import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class SupabaseValidator {
  /// Validate Supabase configuration
  static Future<ValidationResult> validateConfig() async {
    final url = await supabaseUrl;
    final key = await supabaseAnonKey;
    
    // Check if values are present
    if (url.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'SUPABASE_URL is empty or not loaded from .env file',
      );
    }
    
    if (key.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'SUPABASE_ANON_KEY is empty or not loaded from .env file',
      );
    }
    
    // Validate URL format
    if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      return ValidationResult(
        isValid: false,
        message: 'Invalid Supabase URL format. Should be https://[project-id].supabase.co',
      );
    }
    
    // Validate JWT token format
    if (!_isValidJWT(key)) {
      return ValidationResult(
        isValid: false,
        message: 'Invalid Supabase anon key format. Should be a valid JWT token',
      );
    }
    
    // Test DNS resolution
    try {
      final uri = Uri.parse(url);
      final addresses = await InternetAddress.lookup(uri.host);
      if (addresses.isEmpty) {
        return ValidationResult(
          isValid: false,
          message: 'Cannot resolve Supabase hostname: ${uri.host}',
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'DNS resolution failed for ${Uri.parse(url).host}: $e',
      );
    }
    
    // Test API connectivity
    try {
      final response = await http.get(
        Uri.parse('$url/rest/v1/'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': key,
          'User-Agent': 'FootConnect/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return ValidationResult(
          isValid: true,
          message: 'Supabase configuration is valid and server is reachable',
          details: {
            'url': url,
            'project_id': Uri.parse(url).host.split('.').first,
            'status_code': response.statusCode,
            'response_length': response.body.length,
          },
        );
      } else {
        return ValidationResult(
          isValid: false,
          message: 'Supabase server returned unexpected status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'Failed to connect to Supabase server: $e',
      );
    }
  }
  
  /// Check if string is a valid JWT token
  static bool _isValidJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    
    try {
      // Try to decode the header and payload
      final header = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      
      // Check if they're valid JSON
      jsonDecode(header);
      final payloadJson = jsonDecode(payload);
      
      // Check if it's a Supabase token
      return payloadJson['iss'] == 'supabase' && payloadJson['role'] == 'anon';
    } catch (e) {
      return false;
    }
  }
  
  /// Get detailed configuration info
  static Future<Map<String, dynamic>> getConfigInfo() async {
    final url = await supabaseUrl;
    final key = await supabaseAnonKey;
    
    Map<String, dynamic> info = {
      'url_present': url.isNotEmpty,
      'key_present': key.isNotEmpty,
      'url_format_valid': url.startsWith('https://') && url.contains('.supabase.co'),
      'key_format_valid': _isValidJWT(key),
    };
    
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        info['project_id'] = uri.host.split('.').first;
        info['hostname'] = uri.host;
      } catch (e) {
        info['url_parse_error'] = e.toString();
      }
    }
    
    if (key.isNotEmpty && _isValidJWT(key)) {
      try {
        final parts = key.split('.');
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        info['token_issuer'] = payload['iss'];
        info['token_role'] = payload['role'];
        info['token_ref'] = payload['ref'];
        info['token_expires'] = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000).toIso8601String();
      } catch (e) {
        info['token_decode_error'] = e.toString();
      }
    }
    
    return info;
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic>? details;
  
  ValidationResult({
    required this.isValid,
    required this.message,
    this.details,
  });
}
