import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/app_config.dart';

class NetworkDiagnostics {
  /// Run comprehensive network diagnostics
  static Future<DiagnosticResult> runDiagnostics() async {
    final networkConfig = AppConfig.instance.network;
    final results = <String>[];
    bool hasErrors = false;

    // 1. Check environment configuration
    results.add('=== Environment Configuration ===');
    final supabaseUrlValue = await supabaseUrl;
    final supabaseKeyValue = await supabaseAnonKey;

    if (supabaseUrlValue.isEmpty) {
      results.add('❌ SUPABASE_URL is empty or not loaded');
      hasErrors = true;
    } else {
      results.add('✅ SUPABASE_URL: ${supabaseUrlValue.substring(0, 30)}...');
    }

    if (supabaseKeyValue.isEmpty) {
      results.add('❌ SUPABASE_ANON_KEY is empty or not loaded');
      hasErrors = true;
    } else {
      results.add('✅ SUPABASE_ANON_KEY: ${supabaseKeyValue.substring(0, 20)}...');
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

    // 3. Check DNS resolution for Supabase
    if (supabaseUrlValue.isNotEmpty) {
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
}

class DiagnosticResult {
  final bool success;
  final String details;

  DiagnosticResult({
    required this.success,
    required this.details,
  });
}
