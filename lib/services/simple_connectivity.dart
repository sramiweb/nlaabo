import 'dart:io';
import 'package:flutter/foundation.dart';

class SimpleConnectivity {
  static Future<bool> hasInternet() async {
    try {
      // Simple DNS lookup - works well with wireless
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Simple connectivity check failed: $e');
      return false;
    }
  }
  
  static Future<bool> canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Cannot reach $host: $e');
      return false;
    }
  }
}
