import '../services/localization_service.dart';
import '../constants/translation_keys.dart';
import 'package:logger/logger.dart';

/// Shared synchronous form validators used across screens.
/// Each validator returns a localized error string via LocalizationService().translate(key)
/// or null when the value is valid.
/// Supports real-time validation with optional isRealTime parameter.

final RegExp _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
final RegExp _urlRegExp = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
final RegExp _postalCodeRegExp = RegExp(r'^\d{4,10}$');
final Logger _logger = Logger();

/// Validate email: non-empty + valid email regex with stricter validation.
/// Enhanced with real-time validation support.
String? validateEmail(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('email_required');
  }

  final String email = value.trim().toLowerCase();

  // For real-time validation, be more lenient with incomplete emails
  if (isRealTime && !email.contains('@')) {
    return null; // Allow typing before @
  }

  // Check basic format
  if (!_emailRegExp.hasMatch(email)) {
    return LocalizationService().translate('invalid_email');
  }

  // Additional validation for common issues
  if (email.startsWith('.') ||
      email.startsWith('@') ||
      email.endsWith('.') ||
      email.endsWith('@')) {
    return LocalizationService().translate('invalid_email');
  }

  // Check for consecutive dots
  if (email.contains('..')) {
    return LocalizationService().translate('invalid_email');
  }

  // Check for valid domain (at least one dot after @)
  final int atIndex = email.indexOf('@');
  if (atIndex == -1 || !email.substring(atIndex).contains('.')) {
    return LocalizationService().translate('invalid_email');
  }

  // Check for suspicious patterns that might indicate injection attempts
  final suspiciousPatterns = [
    RegExp(r'<[^>]*>'), // HTML tags
    RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
    RegExp(r'on\w+\s*='), // Event handlers
    RegExp(r';\s*--'), // SQL comment injection
    RegExp(r'union\s+select', caseSensitive: false), // SQL injection
    RegExp(r'script', caseSensitive: false), // Script tags
  ];

  for (final pattern in suspiciousPatterns) {
    if (pattern.hasMatch(email)) {
      return LocalizationService().translate('invalid_email');
    }
  }

  // Check for excessively long email (potential DoS)
  if (email.length > 254) {
    return LocalizationService().translate('email_too_long');
  }

  return null;
}

/// Validate password: non-empty + minimum length 8 + complexity requirements.
/// Returns an error string when invalid, otherwise null.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return LocalizationService().translate('password_required');
  }
  if (value.length < 8) {
    // New key added for 8-char minimum
    return LocalizationService().translate('password_too_short_8');
  }

  // Check for at least one uppercase letter
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return LocalizationService().translate('password_requires_uppercase');
  }

  // Check for at least one lowercase letter
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return LocalizationService().translate('password_requires_lowercase');
  }

  // Check for at least one digit
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return LocalizationService().translate('password_requires_digit');
  }

  // Check for common weak patterns
  final weakPatterns = [
    RegExp(r'(.)\1{2,}'), // Three or more consecutive identical characters
    RegExp(r'123456|password|qwerty|abc123', caseSensitive: false), // Common weak passwords
  ];

  for (final pattern in weakPatterns) {
    if (pattern.hasMatch(value)) {
      return LocalizationService().translate('password_too_weak');
    }
  }

  return null;
}

/// Validate confirm password matches [password].
String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return LocalizationService().translate('password_required');
  }
  if (value != password) {
    return LocalizationService().translate('passwords_not_match');
  }
  return null;
}

/// Validate full name: required, min length 2, must contain at least one letter.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('name_required');
  }

  final String name = value.trim();

  if (name.length < 2) {
    return LocalizationService().translate('name_too_short');
  }

  // Check if name contains at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(name)) {
    return LocalizationService().translate('name_must_contain_letter');
  }

  // Check for placeholder/invalid names
  final String lowerName = name.toLowerCase();
  if (lowerName.contains('development') ||
      lowerName.contains('test') ||
      lowerName.contains('user') ||
      lowerName.contains('admin') ||
      lowerName.contains('placeholder') ||
      lowerName.length < 3) {
    return LocalizationService().translate('name_invalid_placeholder');
  }

  // Check for potentially malicious patterns
  final maliciousPatterns = [
    RegExp(r'<[^>]*>'), // HTML tags
    RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
    RegExp(r'on\w+\s*='), // Event handlers
    RegExp(r';\s*--'), // SQL comment injection
    RegExp(r'union\s+select', caseSensitive: false), // SQL injection
    RegExp(r'script', caseSensitive: false), // Script tags
  ];

  for (final pattern in maliciousPatterns) {
    if (pattern.hasMatch(name)) {
      return LocalizationService().translate('name_invalid_characters');
    }
  }

  // Check for excessively long name (potential DoS)
  if (name.length > 100) {
    return LocalizationService().translate('name_too_long');
  }

  return null;
}

/// Validate team description: optional, but if present must be reasonable length and safe.
String? validateTeamDescription(String? value) {
 if (value == null || value.trim().isEmpty) {
   return null; // Optional field
 }

 final String description = value.trim();

 // Check length limits
 if (description.length > 500) {
   return LocalizationService().translate('team_description_too_long');
 }

 if (description.length < 10) {
   return LocalizationService().translate('team_description_too_short');
 }

 // Check for potentially malicious patterns
 final maliciousPatterns = [
   RegExp(r'<[^>]*>'), // HTML tags
   RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
   RegExp(r'on\w+\s*='), // Event handlers
   RegExp(r';\s*--'), // SQL comment injection
   RegExp(r'union\s+select', caseSensitive: false), // SQL injection
   RegExp(r'script', caseSensitive: false), // Script tags
 ];

 for (final pattern in maliciousPatterns) {
   if (pattern.hasMatch(description)) {
     return LocalizationService().translate('team_description_invalid_characters');
   }
 }

 return null;
}

/// Validate match description: optional, but if present must be reasonable length and safe.
String? validateMatchDescription(String? value) {
 if (value == null || value.trim().isEmpty) {
   return null; // Optional field
 }

 final String description = value.trim();

 // Check length limits
 if (description.length > 300) {
   return LocalizationService().translate('match_description_too_long');
 }

 if (description.length < 5) {
   return LocalizationService().translate('match_description_too_short');
 }

 // Check for potentially malicious patterns
 final maliciousPatterns = [
   RegExp(r'<[^>]*>'), // HTML tags
   RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
   RegExp(r'on\w+\s*='), // Event handlers
   RegExp(r';\s*--'), // SQL comment injection
   RegExp(r'union\s+select', caseSensitive: false), // SQL injection
   RegExp(r'script', caseSensitive: false), // Script tags
 ];

 for (final pattern in maliciousPatterns) {
   if (pattern.hasMatch(description)) {
     return LocalizationService().translate('match_description_invalid_characters');
   }
 }

 return null;
}

/// Validate city name: required, reasonable length, and safe characters.
String? validateCity(String? value) {
 if (value == null || value.trim().isEmpty) {
   return LocalizationService().translate('city_required');
 }

 final String city = value.trim();

 // Check length limits
 if (city.length > 100) {
   return LocalizationService().translate('city_too_long');
 }

 if (city.length < 2) {
   return LocalizationService().translate('city_too_short');
 }

 // Allow letters, spaces, hyphens, apostrophes
 final RegExp validCityPattern = RegExp(r"^[a-zA-Z\s\-']+$");
 if (!validCityPattern.hasMatch(city)) {
   return LocalizationService().translate('city_invalid_characters');
 }

 // Check for potentially malicious patterns
 final maliciousPatterns = [
   RegExp(r'<[^>]*>'), // HTML tags
   RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
   RegExp(r'on\w+\s*='), // Event handlers
   RegExp(r';\s*--'), // SQL comment injection
   RegExp(r'union\s+select', caseSensitive: false), // SQL injection
   RegExp(r'script', caseSensitive: false), // Script tags
 ];

 for (final pattern in maliciousPatterns) {
   if (pattern.hasMatch(city)) {
     return LocalizationService().translate('city_invalid_characters');
   }
 }

 return null;
}

/// Validate postal code: optional, but if present must be numeric and reasonable length.
String? validatePostalCode(String? value) {
 if (value == null || value.trim().isEmpty) {
   return null; // Optional field
 }

 final String postalCode = value.trim();

 // Check if it's numeric and within reasonable length
 if (!_postalCodeRegExp.hasMatch(postalCode)) {
   return LocalizationService().translate('postal_code_invalid');
 }

 return null;
}

/// Validate URL: optional, but if present must be valid HTTP/HTTPS URL.
String? validateUrl(String? value) {
 if (value == null || value.trim().isEmpty) {
   return null; // Optional field
 }

 final String url = value.trim();

 // Check basic URL format
 if (!_urlRegExp.hasMatch(url)) {
   return LocalizationService().translate('url_invalid');
 }

 // Check for excessively long URL (potential DoS)
 if (url.length > 2000) {
   return LocalizationService().translate('url_too_long');
 }

 return null;
}

/// Validate optional phone: if present must contain at least 7 digits after removing non-digit characters.
/// Supports international phone numbers (7-25 digits) to accommodate various formats.
/// Only allows digits, spaces, +, -, (, ) in the input.
/// Enhanced with support for partial input validation.
String? validatePhoneOptional(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) return null;

  final String trimmed = value.trim();

  // Check for invalid characters - only allow digits, spaces, +, -, (, )
  if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(trimmed)) {
    _logger.w('Phone validation failed - contains invalid characters');
    return LocalizationService().translate(TranslationKeys.phoneInvalid);
  }

  final String cleaned = trimmed.replaceAll(RegExp(r'\D'), '');
  _logger.d(
    'Phone validation - input: "$value", cleaned: "$cleaned", length: ${cleaned.length}, real-time: $isRealTime',
  );

  // For real-time validation, be more lenient with short numbers
  if (isRealTime) {
    // Allow very short numbers during typing (1-3 digits)
    if (cleaned.length < 4) {
      return null;
    }

    // For numbers 4-6 digits, only do basic format validation
    if (cleaned.length < 7) {
      if (_isValidPartialPhoneNumber(cleaned)) {
        return null;
      } else {
        return LocalizationService().translate(TranslationKeys.phoneInvalid);
      }
    }
  }

  if (cleaned.length < 7 || cleaned.length > 25) {
    _logger.w(
      'Phone validation failed - length ${cleaned.length} not between 7-25 digits',
    );
    return LocalizationService().translate(TranslationKeys.phoneInvalid);
  }

  // Reject numbers starting with 0 that are less than 10 digits (like 061234567 = 9 digits)
  if (cleaned.startsWith('0') && cleaned.length < 10) {
    _logger.w('Phone validation failed - number starting with 0 must be at least 10 digits');
    return LocalizationService().translate(TranslationKeys.phoneInvalid);
  }

  return null;
}

/// Check if a partial phone number is potentially valid
bool _isValidPartialPhoneNumber(String number) {
  if (number.isEmpty) return false;

  // Basic validation - allow numbers starting with 1-9
  // More sophisticated validation is handled by PhoneService
  return RegExp(r'^[1-9]').hasMatch(number);
}

/// General-purpose validators for common validation patterns.

/// Validate required field: non-empty after trimming.
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('${fieldName}_required');
  }
  return null;
}

/// Validate numeric value: must be a valid number.
String? validateNumeric(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('${fieldName}_required');
  }

  final num? number = num.tryParse(value.trim());
  if (number == null) {
    return LocalizationService().translate('${fieldName}_must_be_number');
  }

  return null;
}

/// Validate integer value: must be a valid integer.
String? validateInteger(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('${fieldName}_required');
  }

  final int? integer = int.tryParse(value.trim());
  if (integer == null) {
    return LocalizationService().translate('${fieldName}_must_be_integer');
  }

  return null;
}

/// Validate range: numeric value within min and max bounds.
String? validateRange(String? value, String fieldName, num min, num max) {
  final num? number = num.tryParse(value?.trim() ?? '');
  if (number == null) {
    return LocalizationService().translate('${fieldName}_must_be_number');
  }

  if (number < min || number > max) {
    return LocalizationService().translate('${fieldName}_out_of_range').replaceAll('{min}', min.toString()).replaceAll('{max}', max.toString());
  }

  return null;
}

/// Validate minimum length: string must be at least minLength characters.
String? validateMinLength(String? value, String fieldName, int minLength) {
  if (value == null || value.trim().length < minLength) {
    return LocalizationService().translate('${fieldName}_too_short_min').replaceAll('{min}', minLength.toString());
  }
  return null;
}

/// Validate maximum length: string must not exceed maxLength characters.
String? validateMaxLength(String? value, String fieldName, int maxLength) {
  if (value != null && value.trim().length > maxLength) {
    return LocalizationService().translate('${fieldName}_too_long_max').replaceAll('{max}', maxLength.toString());
  }
  return null;
}

/// Validate exact length: string must be exactly length characters.
String? validateExactLength(String? value, String fieldName, int length) {
  if (value == null || value.trim().length != length) {
    return LocalizationService().translate('${fieldName}_must_be_length').replaceAll('{length}', length.toString());
  }
  return null;
}


/// Validate age: required, numeric and within sensible range (13-100).
/// Enhanced with real-time validation support.
String? validateAge(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('age_required');
  }

  final String trimmed = value.trim();

  // For real-time validation, allow partial input
  if (isRealTime && trimmed.isEmpty) {
    return null;
  }

  final int? age = int.tryParse(trimmed);
  if (age == null) {
    return LocalizationService().translate('age_must_be_number');
  }

  if (age < 13 || age > 100) {
    return LocalizationService().translate('age_invalid_range');
  }

  return null;
}

/// Validate age: optional, numeric and within sensible range (13-100) if provided.
String? validateAgeOptional(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Allow empty
  }
  final int? age = int.tryParse(value.trim());
  if (age == null || age < 13 || age > 100) {
    return LocalizationService().translate('age_invalid');
  }
  return null;
}

/// Validate location: non-empty.
String? validateLocation(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('location_required');
  }
  return null;
}

/// Validate match title: non-empty and reasonable length (>=3).
/// Enhanced with real-time validation and security checks.
String? validateMatchTitle(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('match_title_required');
  }

  final String title = value.trim();

  // For real-time validation, be more lenient with short titles
  if (isRealTime && title.length < 3) {
    return null; // Allow typing
  }

  if (title.length < 3) {
    return LocalizationService().translate('match_title_too_short');
  }

  if (title.length > 100) {
    return LocalizationService().translate('match_title_too_long');
  }

  // Check for potentially malicious patterns
  final maliciousPatterns = [
    RegExp(r'<[^>]*>'), // HTML tags
    RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
    RegExp(r'on\w+\s*='), // Event handlers
    RegExp(r';\s*--'), // SQL comment injection
    RegExp(r'union\s+select', caseSensitive: false), // SQL injection
    RegExp(r'script', caseSensitive: false), // Script tags
  ];

  for (final pattern in maliciousPatterns) {
    if (pattern.hasMatch(title)) {
      return LocalizationService().translate('match_title_invalid_characters');
    }
  }

  return null;
}

/// Validate max players: must be > 0.
String? validateMaxPlayers(int? value) {
  if (value == null || value <= 0) {
    return LocalizationService().translate('max_players_required');
  }
  return null;
}

/// Validate team name: non-empty and min length 2.
/// Enhanced with real-time validation and improved security.
String? validateTeamName(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('team_name_required');
  }

  final String teamName = value.trim();

  // For real-time validation, be more lenient with short names
  if (isRealTime && teamName.length < 2) {
    return null; // Allow typing
  }

  if (teamName.length < 2) {
    return LocalizationService().translate('team_name_too_short');
  }

  // Check for excessively long team name (potential DoS)
  if (teamName.length > 50) {
    return LocalizationService().translate('team_name_too_long');
  }

  // Check for placeholder/invalid team names
  final String lowerName = teamName.toLowerCase();
  if (lowerName.contains('test') ||
      lowerName.contains('development') ||
      lowerName.contains('placeholder') ||
      lowerName.contains('sample')) {
    return LocalizationService().translate('team_name_invalid_placeholder');
  }

  // Check for potentially malicious patterns
  final maliciousPatterns = [
    RegExp(r'<[^>]*>'), // HTML tags
    RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
    RegExp(r'on\w+\s*='), // Event handlers
    RegExp(r';\s*--'), // SQL comment injection
    RegExp(r'union\s+select', caseSensitive: false), // SQL injection
    RegExp(r'script', caseSensitive: false), // Script tags
  ];

  for (final pattern in maliciousPatterns) {
    if (pattern.hasMatch(teamName)) {
      return LocalizationService().translate('team_name_invalid_characters');
    }
  }

  return null;
}

/// Validate match date/time is in the future.
String? validateMatchDateTime(DateTime matchDateTime) {
  final now = DateTime.now();
  // Reject current time and past times - must be at least 1 second in the future
  if (matchDateTime.isBefore(now) || matchDateTime.isAtSameMomentAs(now) || 
      matchDateTime.difference(now).inMilliseconds <= 0) {
    return LocalizationService().translate('match_date_time_future');
  }
  return null;
}

/// Validate search query: non-empty, reasonable length, and safe characters.
/// Enhanced with real-time validation support.
String? validateSearchQuery(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return null; // Allow empty search
  }

  final String query = value.trim();

  // Check length limits
  if (query.length > 100) {
    return LocalizationService().translate('search_query_too_long');
  }

  // For real-time validation, be more lenient with short queries
  if (isRealTime && query.length < 2) {
    return null; // Allow typing
  }

  // Check for minimum length (optional)
  if (query.length < 2) {
    return LocalizationService().translate('search_query_too_short');
  }

  // Validate characters - only allow safe characters
  final RegExp validPattern = RegExp(r"^[a-zA-Z0-9\s\-\.\,']+$");
  if (!validPattern.hasMatch(query)) {
    return LocalizationService().translate('search_query_invalid_characters');
  }

  // Check for potentially malicious patterns
  final List<RegExp> maliciousPatterns = [
    RegExp(r'<[^>]*>'), // HTML tags
    RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
    RegExp(r'on\w+\s*='), // Event handlers
    RegExp(r';\s*--'), // SQL comment injection
    RegExp(r'union\s+select', caseSensitive: false), // SQL injection
  ];

  for (final RegExp pattern in maliciousPatterns) {
    if (pattern.hasMatch(query)) {
      return LocalizationService().translate('search_query_invalid_characters');
    }
  }

  return null;
}

/// Validate username: required, alphanumeric with underscores, reasonable length.
/// Enhanced with real-time validation and security checks.
String? validateUsername(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return LocalizationService().translate('username_required');
  }

  final String username = value.trim();

  // For real-time validation, be more lenient with short usernames
  if (isRealTime && username.length < 3) {
    return null; // Allow typing
  }

  // Check length limits
  if (username.length < 3) {
    return LocalizationService().translate('username_too_short');
  }

  if (username.length > 30) {
    return LocalizationService().translate('username_too_long');
  }

  // Check for valid characters (letters, numbers, underscores)
  final RegExp validUsernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
  if (!validUsernamePattern.hasMatch(username)) {
    return LocalizationService().translate('username_invalid_characters');
  }

  // Must start with a letter
  if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
    return LocalizationService().translate('username_must_start_with_letter');
  }

  // Check for reserved usernames
  final String lowerUsername = username.toLowerCase();
  final List<String> reservedNames = [
    'admin', 'administrator', 'root', 'system', 'support', 'help',
    'moderator', 'staff', 'official', 'bot', 'api', 'test', 'null'
  ];

  if (reservedNames.contains(lowerUsername)) {
    return LocalizationService().translate('username_reserved');
  }

  return null;
}

/// Validate bio/description: optional, but if present must be reasonable length and safe.
/// Enhanced with real-time validation.
String? validateBio(String? value, {bool isRealTime = false}) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }

  final String bio = value.trim();

  // Check length limits
  if (bio.length > 500) {
    return LocalizationService().translate('bio_too_long');
  }

  // For real-time validation, be more lenient with short bios
  if (isRealTime && bio.length < 10) {
    return null; // Allow typing
  }

  if (bio.length < 10) {
    return LocalizationService().translate('bio_too_short');
  }

  // Check for potentially malicious patterns
  final maliciousPatterns = [
    RegExp(r'<[^>]*>'), // HTML tags
    RegExp(r'javascript:', caseSensitive: false), // JavaScript injection
    RegExp(r'on\w+\s*='), // Event handlers
    RegExp(r';\s*--'), // SQL comment injection
    RegExp(r'union\s+select', caseSensitive: false), // SQL injection
    RegExp(r'script', caseSensitive: false), // Script tags
  ];

  for (final pattern in maliciousPatterns) {
    if (pattern.hasMatch(bio)) {
      return LocalizationService().translate('bio_invalid_characters');
    }
  }

  return null;
}
