/// Input sanitization utilities to prevent XSS, SQL injection, and other attacks
class InputSanitizer {
  static final _htmlTagPattern = RegExp(r'<[^>]*>');
  static final _scriptPattern = RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false);
  static final _sqlInjectionPatterns = [
    RegExp(r';\\s*--'),
    RegExp(r'union\\s+select', caseSensitive: false),
    RegExp(r'drop\\s+table', caseSensitive: false),
    RegExp(r'insert\\s+into', caseSensitive: false),
    RegExp(r'delete\\s+from', caseSensitive: false),
  ];
  static final _xssPatterns = [
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\\w+\\s*=', caseSensitive: false),
    RegExp(r'<iframe', caseSensitive: false),
    RegExp(r'<embed', caseSensitive: false),
    RegExp(r'<object', caseSensitive: false),
  ];

  /// Sanitize text input by removing dangerous patterns
  static String sanitizeText(String? input) {
    if (input == null || input.isEmpty) return '';
    
    String sanitized = input.trim();
    
    // Remove script tags
    sanitized = sanitized.replaceAll(_scriptPattern, '');
    
    // Remove HTML tags
    sanitized = sanitized.replaceAll(_htmlTagPattern, '');
    
    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');
    
    return sanitized;
  }

  /// Check if input contains malicious patterns
  static bool containsMaliciousPattern(String? input) {
    if (input == null || input.isEmpty) return false;
    
    final lower = input.toLowerCase();
    
    // Check SQL injection patterns
    for (final pattern in _sqlInjectionPatterns) {
      if (pattern.hasMatch(lower)) return true;
    }
    
    // Check XSS patterns
    for (final pattern in _xssPatterns) {
      if (pattern.hasMatch(input)) return true;
    }
    
    return false;
  }

  /// Sanitize and validate email
  static String? sanitizeEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    
    final sanitized = email.trim().toLowerCase();
    
    if (containsMaliciousPattern(sanitized)) return null;
    if (sanitized.length > 254) return null;
    
    return sanitized;
  }

  /// Sanitize name (allow letters, spaces, hyphens, apostrophes)
  static String? sanitizeName(String? name) {
    if (name == null || name.isEmpty) return null;
    
    String sanitized = name.trim();
    
    if (containsMaliciousPattern(sanitized)) return null;
    if (sanitized.length > 100) return null;
    
    // Remove any characters that aren't letters, spaces, hyphens, or apostrophes
    sanitized = sanitized.replaceAll(RegExp(r"[^a-zA-Z\s\-']"), '');
    
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitize phone number (keep only digits, +, -, (, ), spaces)
  static String? sanitizePhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    
    final sanitized = phone.trim();
    
    if (containsMaliciousPattern(sanitized)) return null;
    
    // Keep only valid phone characters
    final cleaned = sanitized.replaceAll(RegExp(r'[^\d\s\+\-\(\)]'), '');
    
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Sanitize general text fields (bio, description, etc.)
  static String? sanitizeTextField(String? text, {int maxLength = 500}) {
    if (text == null || text.isEmpty) return null;
    
    String sanitized = sanitizeText(text);
    
    if (containsMaliciousPattern(sanitized)) return null;
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitize URL
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    final sanitized = url.trim();
    
    if (containsMaliciousPattern(sanitized)) return null;
    if (sanitized.length > 2000) return null;
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      return null;
    }
    
    return sanitized;
  }

  /// Sanitize search query
  static String? sanitizeSearchQuery(String? query) {
    if (query == null || query.isEmpty) return null;
    
    String sanitized = query.trim();
    
    if (containsMaliciousPattern(sanitized)) return null;
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }
    
    // Allow only safe characters for search
    sanitized = sanitized.replaceAll(RegExp(r"[^a-zA-Z0-9\s\-\.,']"), '');
    
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitize integer input
  static int? sanitizeInt(dynamic value, {int? min, int? max}) {
    if (value == null) return null;
    
    final parsed = int.tryParse(value.toString());
    if (parsed == null) return null;
    
    if (min != null && parsed < min) return null;
    if (max != null && parsed > max) return null;
    
    return parsed;
  }

  /// Sanitize map of user input (for API requests)
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) continue;
      
      if (value is String) {
        final cleaned = sanitizeText(value);
        if (cleaned.isNotEmpty && !containsMaliciousPattern(cleaned)) {
          sanitized[key] = cleaned;
        }
      } else if (value is int || value is double || value is bool) {
        sanitized[key] = value;
      } else if (value is List) {
        sanitized[key] = value.map((e) => 
          e is String ? sanitizeText(e) : e
        ).toList();
      } else if (value is Map) {
        sanitized[key] = sanitizeMap(value as Map<String, dynamic>);
      }
    }
    
    return sanitized;
  }
}
