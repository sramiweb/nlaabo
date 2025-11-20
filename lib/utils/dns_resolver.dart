import 'dart:io';
import 'package:flutter/foundation.dart';

class DNSResolver {
  /// Test if DNS resolution is working
  static Future<bool> canResolveDNS() async {
    try {
      final addresses = await InternetAddress.lookup('google.com');
      return addresses.isNotEmpty;
    } catch (e) {
      debugPrint('DNS resolution test failed: $e');
      return false;
    }
  }

  /// Get user-friendly DNS error message
  static String getDNSErrorMessage() {
    return '''
DNS Resolution Failed

This usually happens when:
• Your network blocks certain websites
• DNS servers are not responding
• Network configuration issues

Try:
• Switch between WiFi and mobile data
• Restart your device
• Check with your network administrator
• Try again in a few minutes
''';
  }
}
