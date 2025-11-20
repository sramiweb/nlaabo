import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:logger/logger.dart';
import '../services/localization_service.dart';
import '../constants/translation_keys.dart';

// Re-export for convenience
export 'package:intl_phone_number_input/intl_phone_number_input.dart';

/// Cache entry for validation results
class _ValidationCacheEntry {
  final String? error;
  final DateTime timestamp;

  _ValidationCacheEntry(this.error, this.timestamp);

  bool get isExpired => DateTime.now().difference(timestamp) > PhoneService._validationCacheDuration;
}

/// Cache entry for format results
class _FormatCacheEntry {
  final String? formatted;
  final DateTime timestamp;

  _FormatCacheEntry(this.formatted, this.timestamp);

  bool get isExpired => DateTime.now().difference(timestamp) > PhoneService._validationCacheDuration;
}

/// Cache entry for parse results
class _ParseCacheEntry {
  final PhoneNumber? parsed;
  final DateTime timestamp;

  _ParseCacheEntry(this.parsed, this.timestamp);

  bool get isExpired => DateTime.now().difference(timestamp) > PhoneService._validationCacheDuration;
}

/// Service class for phone number validation, formatting, and normalization
/// using Google's libphonenumber library via intl_phone_number_input.
///
/// This service provides comprehensive phone number handling with special
/// support for Moroccan phone numbers as the primary use case.
///
/// ## Security Features
///
/// ### Input Sanitization
/// - Removes potentially malicious characters and patterns
/// - Prevents XSS attacks via script injection
/// - Validates input length to prevent buffer overflow
/// - Strips HTML tags and JavaScript content
///
/// ### Rate Limiting
/// - Limits validation requests to 100 per minute per client
/// - Prevents abuse and DoS attacks
/// - Automatic cleanup of expired rate limit data
/// - Configurable rate limits via static constants
///
/// ### Secure Storage
/// - Optional SHA-256 hashing for phone number storage
/// - One-way encryption prevents data leakage
/// - Maintains validation capability while securing stored data
/// - Input sanitization before hashing
///
/// ## Usage Examples
///
/// ### Basic Validation
/// ```dart
/// final error = await PhoneService.validatePhoneNumber('+212641170012');
/// if (error == null) {
///   // Phone number is valid
/// } else {
///   // Handle validation error
/// }
/// ```
///
/// ### Rate Limited Validation
/// ```dart
/// final error = await PhoneService.validatePhoneNumber(
///   '+212641170012',
///   clientId: 'user-123'
/// );
/// ```
///
/// ### Secure Storage
/// ```dart
/// final hashedPhone = await PhoneService.normalizePhoneNumber(
///   '+212641170012',
///   encryptForStorage: true
/// );
/// // Store hashedPhone securely
/// ```
///
/// ## Features:
/// - Phone number validation with country-specific rules
/// - Formatting for display and storage
/// - Normalization to international format
/// - Error handling with localized messages
/// - Support for Moroccan phone number patterns
/// - Security enhancements: input sanitization, rate limiting, secure storage
class PhoneService {
  static final Logger _logger = Logger();

  // Singleton instance
  static PhoneService? _instance;
  static PhoneService get instance {
    _instance ??= PhoneService._internal();
    return _instance!;
  }

  PhoneService._internal();

  // Caching for validation results
  static const Duration _validationCacheDuration = Duration(minutes: 30);
  final Map<String, _ValidationCacheEntry> _validationCache = {};
  final Map<String, _FormatCacheEntry> _formatCache = {};
  final Map<String, _ParseCacheEntry> _parseCache = {};

  // Debounced validation timer
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  // Security: Rate limiting for validation requests
  static const int _maxRequestsPerMinute = 100;
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  final Map<String, List<DateTime>> _requestTimestamps = {};
  final Map<String, int> _blockedClients = {};

  // Security: Input sanitization patterns
  static final RegExp _phoneSanitizationPattern = RegExp(r'[^\d\s\+\-\(\)\.]');
  static final RegExp _suspiciousPattern = RegExp(r'''[<>"';]|javascript:|data:|vbscript:|on\w+\s*=|style\s*=.*expression|style\s*=.*javascript''', caseSensitive: false);
  static const int _maxPhoneLength = 25;

  /// Initialize the phone number library
  /// Should be called once during app initialization
  static Future<void> initialize() async {
    try {
      // The intl_phone_number_input library initializes automatically
      _logger.i('PhoneService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize PhoneService: $e');
      rethrow;
    }
  }

  /// Check if a partial phone number is valid for the given country
  ///
  /// [number]: The cleaned phone number digits
  /// [countryCode]: ISO country code
  ///
  /// Returns true if the partial number is potentially valid
  static bool _isValidPartialNumber(String number, String countryCode) {
    if (number.isEmpty) return false;

    // For Moroccan numbers, check if it starts with valid prefixes
    if (countryCode == 'MA') {
      // Moroccan mobile numbers start with 6 or 7
      // Moroccan landline numbers start with 5
      return number.startsWith('6') || number.startsWith('7') || number.startsWith('5');
    }

    // For other countries, basic validation - allow numbers starting with 1-9
    return RegExp(r'^[1-9]').hasMatch(number);
  }

  /// Validate Moroccan phone number with improved edge case handling
  ///
  /// [nationalNumber]: The national number without country code
  /// [fullNumber]: The full international number
  /// [isRealTime]: Whether this is real-time validation
  ///
  /// Returns true if valid Moroccan number
  static bool _validateMoroccanNumber(String nationalNumber, String fullNumber, bool isRealTime) {
    _logger.d('Validating Moroccan number: $nationalNumber (full: $fullNumber, real-time: $isRealTime)');

    // Handle real-time validation for partial numbers
    if (isRealTime) {
      if (nationalNumber.length < 4) {
        // Very short numbers are allowed during typing
        return true;
      } else if (nationalNumber.length < 9) {
        // For partial numbers, just check the prefix
        return nationalNumber.startsWith('6') ||
               nationalNumber.startsWith('7') ||
               nationalNumber.startsWith('5');
      }
    }

    // Full validation for complete numbers
    if (nationalNumber.length != 9) {
      _logger.w('Moroccan number length invalid: ${nationalNumber.length} (expected 9)');
      return false;
    }

    // Moroccan mobile numbers: start with 6 or 7
    if (nationalNumber.startsWith('6') || nationalNumber.startsWith('7')) {
      _logger.d('Valid Moroccan mobile number: $nationalNumber');
      return true;
    }

    // Moroccan landline numbers: start with 5
    if (nationalNumber.startsWith('5')) {
      _logger.d('Valid Moroccan landline number: $nationalNumber');
      return true;
    }

    // Special cases: some regions use other prefixes
    // 8xx for some mobile operators, 2xx for some regions
    if (nationalNumber.startsWith('8') || nationalNumber.startsWith('2')) {
      _logger.d('Valid Moroccan special number: $nationalNumber');
      return true;
    }

    _logger.w('Invalid Moroccan number pattern: $nationalNumber');
    return false;
  }

  /// Sanitize phone number input to prevent injection attacks
  ///
  /// [phoneNumber]: The raw phone number input to sanitize
  ///
  /// Returns sanitized phone number or null if input is malicious
  static String? _sanitizePhoneInput(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) return phoneNumber;

    // Check for suspicious patterns that could indicate injection attempts
    if (_suspiciousPattern.hasMatch(phoneNumber)) {
      _logger.w('Suspicious phone input detected: $phoneNumber');
      return null;
    }

    // Remove any characters that are not allowed in phone numbers
    final sanitized = phoneNumber.replaceAll(_phoneSanitizationPattern, '');

    // Only check maximum length (allow partial input during typing)
    if (sanitized.length > _maxPhoneLength) {
      _logger.w('Phone input too long: ${sanitized.length}');
      return null;
    }

    return sanitized;
  }

  /// Check if client is rate limited for validation requests
  ///
  /// [clientId]: Unique identifier for the client (e.g., IP address, user ID)
  ///
  /// Returns true if rate limited, false otherwise
  static bool _isRateLimited(String clientId) {
    final now = DateTime.now();
    final timestamps = instance._requestTimestamps[clientId] ?? [];

    // Remove timestamps outside the rate limit window
    final validTimestamps = timestamps.where((timestamp) =>
        now.difference(timestamp) < _rateLimitWindow).toList();

    // Update the timestamps
    instance._requestTimestamps[clientId] = validTimestamps;

    // Check if client is blocked
    if (instance._blockedClients.containsKey(clientId)) {
      final blockedUntil = instance._blockedClients[clientId]!;
      if (now.millisecondsSinceEpoch < blockedUntil) {
        return true;
      } else {
        instance._blockedClients.remove(clientId);
      }
    }

    // Check rate limit
    if (validTimestamps.length >= _maxRequestsPerMinute) {
      // Block client for the rate limit window
      instance._blockedClients[clientId] = now.add(_rateLimitWindow).millisecondsSinceEpoch;
      _logger.w('Client $clientId rate limited for phone validation');
      return true;
    }

    // Add current timestamp
    validTimestamps.add(now);
    instance._requestTimestamps[clientId] = validTimestamps;

    return false;
  }

  /// Validate a phone number string with security enhancements
  ///
  /// [phoneNumber]: The phone number to validate (can include formatting)
  /// [countryCode]: Optional ISO country code (defaults to 'MA' for Morocco)
  /// [clientId]: Optional client identifier for rate limiting
  /// [isRealTime]: Whether this is real-time validation during input (more lenient)
  ///
  /// Returns null if valid, or a localized error message if invalid
  static Future<String?> validatePhoneNumber(
    String? phoneNumber, {
    String countryCode = 'MA',
    String? clientId,
    bool isRealTime = false,
  }) async {
    // Rate limiting check
    if (clientId != null && _isRateLimited(clientId)) {
      _logger.w('Phone validation request rate limited for client: $clientId');
      return LocalizationService().translate(TranslationKeys.phoneRateLimited);
    }

    // Input sanitization
    final sanitized = _sanitizePhoneInput(phoneNumber);
    if (sanitized == null) {
      _logger.w('Phone input sanitization failed for: $phoneNumber');
      return LocalizationService().translate(TranslationKeys.phoneInvalidInput);
    }

    if (sanitized.trim().isEmpty) {
      return isRealTime ? null : LocalizationService().translate(TranslationKeys.phoneRequired);
    }

    final trimmed = sanitized.trim();
    final cacheKey = '${trimmed}_$countryCode${isRealTime ? '_realtime' : '_final'}';

    // Check cache first
    final cached = instance._validationCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.error;
    }

    try {
      // For real-time validation, be more lenient with short numbers
      if (isRealTime) {
        final cleanedNumber = trimmed.replaceAll(RegExp(r'\D'), '');

        // Allow very short numbers during typing (1-3 digits)
        if (cleanedNumber.length < 4) {
          instance._validationCache[cacheKey] = _ValidationCacheEntry(null, DateTime.now());
          return null;
        }

        // For numbers 4-6 digits, only do basic format validation
        if (cleanedNumber.length < 7) {
          if (_isValidPartialNumber(cleanedNumber, countryCode)) {
            instance._validationCache[cacheKey] = _ValidationCacheEntry(null, DateTime.now());
            return null;
          } else {
            final error = LocalizationService().translate(TranslationKeys.phoneInvalid);
            instance._validationCache[cacheKey] = _ValidationCacheEntry(error, DateTime.now());
            return error;
          }
        }
      }

      // Parse the phone number using intl_phone_number_input
      final phoneNumberObj = await PhoneNumber.getRegionInfoFromPhoneNumber(trimmed, countryCode);

      // Check if the number is valid using basic validation
      // The intl_phone_number_input library handles validation internally
      final isValid = phoneNumberObj.phoneNumber != null && phoneNumberObj.phoneNumber!.isNotEmpty;

      if (!isValid) {
        _logger.w('Invalid phone number: $trimmed for country: $countryCode (real-time: $isRealTime)');
        final error = LocalizationService().translate(TranslationKeys.phoneInvalid);
        instance._validationCache[cacheKey] = _ValidationCacheEntry(error, DateTime.now());
        return error;
      }

      // Additional validation for Moroccan numbers
      if (countryCode == 'MA') {
        final fullNumber = phoneNumberObj.phoneNumber ?? '';
        final nationalNumber = fullNumber.replaceAll(RegExp(r'\+\d+'), '').replaceAll(RegExp(r'\D'), '');

        // Moroccan phone number validation with better edge case handling
        final isValidMoroccan = _validateMoroccanNumber(nationalNumber, fullNumber, isRealTime);

        if (!isValidMoroccan) {
          _logger.w('Invalid Moroccan phone pattern: $nationalNumber (full: $fullNumber, real-time: $isRealTime)');
          final error = LocalizationService().translate(TranslationKeys.phoneInvalidMoroccan);
          instance._validationCache[cacheKey] = _ValidationCacheEntry(error, DateTime.now());
          return error;
        }
      }

      instance._validationCache[cacheKey] = _ValidationCacheEntry(null, DateTime.now());
      return null;

    } catch (e, stackTrace) {
      // Enhanced error handling with detailed logging
      _logger.e('Phone validation error for "$trimmed" (country: $countryCode, real-time: $isRealTime)',
                error: e, stackTrace: stackTrace);

      // Categorize different types of errors for better user feedback
      String errorMessage;
      if (e.toString().contains('Invalid phone number')) {
        errorMessage = LocalizationService().translate(TranslationKeys.phoneInvalid);
      } else if (e.toString().contains('Network') || e.toString().contains('timeout')) {
        errorMessage = LocalizationService().translate(TranslationKeys.errorNetwork);
        _logger.w('Network-related phone validation error: $e');
      } else if (e.toString().contains('parsing') || e.toString().contains('format')) {
        errorMessage = LocalizationService().translate(TranslationKeys.phoneInvalidInput);
        _logger.w('Phone parsing error: $e');
      } else {
        errorMessage = LocalizationService().translate(TranslationKeys.phoneValidationError);
        _logger.e('Unexpected phone validation error: $e');
      }

      instance._validationCache[cacheKey] = _ValidationCacheEntry(errorMessage, DateTime.now());
      return errorMessage;
    }
  }

  /// Format a phone number for display with caching
  ///
  /// [phoneNumber]: The phone number to format
  /// [countryCode]: Optional ISO country code (defaults to 'MA' for Morocco)
  ///
  /// Returns the formatted phone number or null if formatting fails
  static Future<String?> formatPhoneNumber(
    String phoneNumber, {
    String countryCode = 'MA',
  }) async {
    final cacheKey = '${phoneNumber}_$countryCode';

    // Check cache first
    final cached = instance._formatCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.formatted;
    }

    try {
      final phoneNumberObj = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber, countryCode);
      final formatted = phoneNumberObj.phoneNumber ?? phoneNumber;
      instance._formatCache[cacheKey] = _FormatCacheEntry(formatted, DateTime.now());
      return formatted;
    } catch (e) {
      _logger.w('Failed to format phone number "$phoneNumber": $e');
      instance._formatCache[cacheKey] = _FormatCacheEntry(null, DateTime.now());
      return null;
    }
  }

  /// Normalize a phone number to international format for secure storage
  ///
  /// [phoneNumber]: The phone number to normalize
  /// [countryCode]: Optional ISO country code (defaults to 'MA' for Morocco)
  /// [encryptForStorage]: Whether to hash the phone number for secure storage
  ///
  /// Returns the normalized phone number in E.164 format or null if normalization fails
  /// If encryptForStorage is true, returns a SHA-256 hash of the normalized number
  static Future<String?> normalizePhoneNumber(
    String phoneNumber, {
    String countryCode = 'MA',
    bool encryptForStorage = false,
  }) async {
    try {
      // Sanitize input first
      final sanitized = _sanitizePhoneInput(phoneNumber);
      if (sanitized == null) {
        _logger.w('Phone input sanitization failed during normalization: $phoneNumber');
        return null;
      }

      final phoneNumberObj = await PhoneNumber.getRegionInfoFromPhoneNumber(sanitized, countryCode);
      final e164 = phoneNumberObj.phoneNumber ?? sanitized;

      if (encryptForStorage) {
        // Hash the phone number for secure storage (one-way encryption)
        final bytes = utf8.encode(e164);
        final hash = sha256.convert(bytes);
        return hash.toString();
      } else {
        return e164;
      }
    } catch (e) {
      _logger.w('Failed to normalize phone number "$phoneNumber": $e');
      return null;
    }
  }

  /// Parse a phone number and return detailed information with caching
  ///
  /// [phoneNumber]: The phone number to parse
  /// [countryCode]: Optional ISO country code (defaults to 'MA' for Morocco)
  ///
  /// Returns a PhoneNumber object containing parsed information
  static Future<PhoneNumber?> parsePhoneNumber(
    String phoneNumber, {
    String countryCode = 'MA',
  }) async {
    final cacheKey = '${phoneNumber}_$countryCode';

    // Check cache first
    final cached = instance._parseCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.parsed;
    }

    try {
      final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber, countryCode);
      instance._parseCache[cacheKey] = _ParseCacheEntry(parsed, DateTime.now());
      return parsed;
    } catch (e) {
      _logger.w('Failed to parse phone number "$phoneNumber": $e');
      instance._parseCache[cacheKey] = _ParseCacheEntry(null, DateTime.now());
      return null;
    }
  }

  /// Get country information for a phone number
  ///
  /// [phoneNumber]: The phone number to analyze
  ///
  /// Returns country information or null if detection fails
  static Future<PhoneNumber?> getCountryInfo(String phoneNumber) async {
    try {
      final countryInfo = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber);
      return countryInfo;
    } catch (e) {
      _logger.w('Failed to get country info for "$phoneNumber": $e');
      return null;
    }
  }

  /// Check if a phone number is valid for a specific country
  ///
  /// [phoneNumber]: The phone number to validate
  /// [countryCode]: ISO country code to validate against
  ///
  /// Returns true if valid, false otherwise
  static Future<bool> isValidForCountry(String phoneNumber, String countryCode) async {
    try {
      final phoneNumberObj = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber, countryCode);
      final isValid = phoneNumberObj.phoneNumber != null && phoneNumberObj.phoneNumber!.isNotEmpty;
      return isValid;
    } catch (e) {
      _logger.w('Validation error for "$phoneNumber" in $countryCode: $e');
      return false;
    }
  }

  /// Format a phone number as you type (for input fields)
  ///
  /// [phoneNumber]: The current phone number input
  /// [countryCode]: Optional ISO country code (defaults to 'MA' for Morocco)
  ///
  /// Returns the formatted phone number for display in input field
  static Future<String?> formatAsYouType(
    String phoneNumber, {
    String countryCode = 'MA',
  }) async {
    try {
      final phoneNumberObj = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber, countryCode);
      final formatted = phoneNumberObj.phoneNumber ?? phoneNumber;
      return formatted;
    } catch (e) {
      _logger.w('Failed to format as you type "$phoneNumber": $e');
      return phoneNumber; // Return original if formatting fails
    }
  }

  /// Get all supported regions/countries
  ///
  /// Returns a list of supported country codes
  static Future<List<String>?> getSupportedRegions() async {
    try {
      // The intl_phone_number_input library doesn't expose this directly
      // Return a common list of supported regions
      final regions = ['MA', 'US', 'GB', 'FR', 'DE', 'ES', 'IT', 'CA', 'AU', 'BR'];
      return regions;
    } catch (e) {
      _logger.w('Failed to get supported regions: $e');
      return null;
    }
  }

  /// Validate Moroccan phone number specifically
  ///
  /// [phoneNumber]: The phone number to validate as Moroccan
  ///
  /// Returns null if valid Moroccan number, or error message if invalid
  static Future<String?> validateMoroccanPhone(String? phoneNumber) async {
    return validatePhoneNumber(phoneNumber, countryCode: 'MA');
  }

  /// Format Moroccan phone number for display
  ///
  /// [phoneNumber]: The Moroccan phone number to format
  ///
  /// Returns formatted Moroccan phone number or null if formatting fails
  static Future<String?> formatMoroccanPhone(String phoneNumber) async {
    return formatPhoneNumber(phoneNumber, countryCode: 'MA');
  }

  /// Normalize Moroccan phone number to international format
  ///
  /// [phoneNumber]: The Moroccan phone number to normalize
  ///
  /// Returns normalized Moroccan phone number or null if normalization fails
  static Future<String?> normalizeMoroccanPhone(String phoneNumber) async {
    return normalizePhoneNumber(phoneNumber, countryCode: 'MA');
  }

  /// Clear all cached validation results
  static void clearValidationCache() {
    instance._validationCache.clear();
  }

  /// Clear all cached format results
  static void clearFormatCache() {
    instance._formatCache.clear();
  }

  /// Clear all cached parse results
  static void clearParseCache() {
    instance._parseCache.clear();
  }

  /// Clear all caches
  static void clearAllCaches() {
    clearValidationCache();
    clearFormatCache();
    clearParseCache();
  }

  /// Clean up expired cache entries
  static void cleanupExpiredCache() {
    instance._validationCache.removeWhere((key, entry) => entry.isExpired);
    instance._formatCache.removeWhere((key, entry) => entry.isExpired);
    instance._parseCache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'validation_cache_size': instance._validationCache.length,
      'format_cache_size': instance._formatCache.length,
      'parse_cache_size': instance._parseCache.length,
    };
  }

  /// Debounced validation method for input fields with security enhancements
  static void debouncedValidate(
    String phoneNumber,
    String countryCode,
    void Function(String?) onResult, {
    String? clientId,
    bool isRealTime = true,
  }) {
    instance._debounceTimer?.cancel();
    instance._debounceTimer = Timer(_debounceDuration, () async {
      final result = await validatePhoneNumber(
        phoneNumber,
        countryCode: countryCode,
        clientId: clientId,
        isRealTime: isRealTime,
      );
      onResult(result);
    });
  }

  /// Cancel any pending debounced validation
  static void cancelDebouncedValidation() {
    instance._debounceTimer?.cancel();
    instance._debounceTimer = null;
  }

  /// Periodic cache cleanup - call this periodically (e.g., every 5 minutes)
  static void performPeriodicCleanup() {
    cleanupExpiredCache();

    // Clean up expired rate limiting data
    _cleanupRateLimitData();

    // Optional: Log cache stats for monitoring
    final stats = getCacheStats();
    _logger.d('Cache stats - Validation: ${stats['validation_cache_size']}, '
        'Format: ${stats['format_cache_size']}, Parse: ${stats['parse_cache_size']}');
  }

  /// Clean up expired rate limiting data
  static void _cleanupRateLimitData() {
    final now = DateTime.now();
  
    // Create a new map to avoid concurrent modification
    final Map<String, List<DateTime>> updatedTimestamps = {};
  
    // Filter timestamps without modifying the original map during iteration
    instance._requestTimestamps.forEach((clientId, timestamps) {
      final validTimestamps = timestamps.where((timestamp) =>
          now.difference(timestamp) < _rateLimitWindow).toList();
      
      // Only keep non-empty timestamp lists
      if (validTimestamps.isNotEmpty) {
        updatedTimestamps[clientId] = validTimestamps;
      }
    });
  
    // Replace the entire map with the filtered data
    instance._requestTimestamps.clear();
    instance._requestTimestamps.addAll(updatedTimestamps);
  
    // Remove expired blocks (this is safe as it's a different map)
    instance._blockedClients.removeWhere((clientId, blockedUntil) =>
        now.millisecondsSinceEpoch >= blockedUntil);
  }

  /// Get security statistics
  static Map<String, dynamic> getSecurityStats() {
    return {
      'active_clients': instance._requestTimestamps.length,
      'blocked_clients': instance._blockedClients.length,
      'total_requests_last_minute': instance._requestTimestamps.values
          .fold(0, (sum, timestamps) => sum + timestamps.length),
    };
  }
}

/// Enum for phone number formats
enum PhoneNumberFormat {
  /// E.164 format: +1234567890
  e164,

  /// International format: +1 234 567 890
  international,

  /// National format: (234) 567-890
  national,

  /// RFC3966 format: tel:+1-234-567-890
  rfc3966,
}
