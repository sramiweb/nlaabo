import 'app_config.dart';

/// Network configuration section for centralized network-related settings
class NetworkConfig {
  // Connection timeouts
  final Duration _connectTimeout;
  final Duration _receiveTimeout;

  // Retry configuration
  final int _maxRetries;
  final Duration _initialRetryDelay;

  // Test URLs for connectivity checks
  final List<String> _testUrls;

  // DNS resolution timeout
  final Duration _dnsTimeout;

  // Supabase specific timeouts
  final Duration _supabaseTimeout;

  // Environment-specific adjustments
  final AppEnvironment _environment;

  const NetworkConfig._({
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required int maxRetries,
    required Duration initialRetryDelay,
    required List<String> testUrls,
    required Duration dnsTimeout,
    required Duration supabaseTimeout,
    required AppEnvironment environment,
  })  : _connectTimeout = connectTimeout,
        _receiveTimeout = receiveTimeout,
        _maxRetries = maxRetries,
        _initialRetryDelay = initialRetryDelay,
        _testUrls = testUrls,
        _dnsTimeout = dnsTimeout,
        _supabaseTimeout = supabaseTimeout,
        _environment = environment;

  /// Create NetworkConfig from environment variables with environment-specific defaults
  factory NetworkConfig.fromEnv(Map<String, String> env, AppEnvironment environment) {
    // Base timeouts - longer for production to handle network variability
    final baseConnectTimeout = Duration(
      seconds: int.tryParse(env['NETWORK_CONNECT_TIMEOUT_SECONDS'] ?? '10') ?? 10,
    );
    final baseReceiveTimeout = Duration(
      seconds: int.tryParse(env['NETWORK_RECEIVE_TIMEOUT_SECONDS'] ?? '30') ?? 30,
    );

    // Environment-specific timeout adjustments
    final (connectTimeout, receiveTimeout) = _adjustTimeoutsForEnvironment(
      baseConnectTimeout,
      baseReceiveTimeout,
      environment,
    );

    return NetworkConfig._(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      maxRetries: int.tryParse(env['NETWORK_MAX_RETRIES'] ?? '3') ?? 3,
      initialRetryDelay: Duration(
        seconds: int.tryParse(env['NETWORK_RETRY_DELAY_SECONDS'] ?? '1') ?? 1,
      ),
      testUrls: env['NETWORK_TEST_URLS']?.split(',') ??
          [
            'https://www.google.com',
            'https://1.1.1.1',
            'https://8.8.8.8',
            'https://httpbin.org/get',
          ],
      dnsTimeout: Duration(
        seconds: int.tryParse(env['NETWORK_DNS_TIMEOUT_SECONDS'] ?? '5') ?? 5,
      ),
      supabaseTimeout: Duration(
        seconds: int.tryParse(env['NETWORK_SUPABASE_TIMEOUT_SECONDS'] ?? '20') ?? 20,
      ),
      environment: environment,
    );
  }

  /// Adjust timeouts based on environment
  static (Duration, Duration) _adjustTimeoutsForEnvironment(
    Duration baseConnectTimeout,
    Duration baseReceiveTimeout,
    AppEnvironment environment,
  ) {
    switch (environment) {
      case AppEnvironment.development:
        // Shorter timeouts for faster feedback during development
        return (
          Duration(seconds: (baseConnectTimeout.inSeconds * 0.5).round().clamp(3, 15)),
          Duration(seconds: (baseReceiveTimeout.inSeconds * 0.5).round().clamp(10, 45)),
        );
      case AppEnvironment.staging:
        // Slightly longer than dev, shorter than prod
        return (
          Duration(seconds: (baseConnectTimeout.inSeconds * 0.8).round().clamp(5, 20)),
          Duration(seconds: (baseReceiveTimeout.inSeconds * 0.8).round().clamp(15, 60)),
        );
      case AppEnvironment.production:
        // Full timeouts for production stability
        return (baseConnectTimeout, baseReceiveTimeout);
    }
  }


  // Getters for configuration values
  Duration get connectTimeout => _connectTimeout;
  Duration get receiveTimeout => _receiveTimeout;
  int get maxRetries => _maxRetries;
  Duration get initialRetryDelay => _initialRetryDelay;
  List<String> get testUrls => List.unmodifiable(_testUrls);
  Duration get dnsTimeout => _dnsTimeout;
  Duration get supabaseTimeout => _supabaseTimeout;
  AppEnvironment get environment => _environment;

  /// Get a general network timeout (connect + receive)
  Duration get generalTimeout => _connectTimeout + _receiveTimeout;

  /// Get retry delay for a specific attempt (exponential backoff)
  Duration getRetryDelay(int attempt) {
    if (attempt <= 1) return _initialRetryDelay;
    return Duration(seconds: _initialRetryDelay.inSeconds * attempt);
  }

  /// Get environment-specific timeout for connectivity tests
  Duration get connectivityTestTimeout {
    switch (_environment) {
      case AppEnvironment.development:
        return const Duration(seconds: 8);
      case AppEnvironment.staging:
        return const Duration(seconds: 12);
      case AppEnvironment.production:
        return const Duration(seconds: 15);
    }
  }

  /// Get environment-specific timeout for diagnostics
  Duration get diagnosticsTimeout {
    switch (_environment) {
      case AppEnvironment.development:
        return const Duration(seconds: 3);
      case AppEnvironment.staging:
        return const Duration(seconds: 5);
      case AppEnvironment.production:
        return const Duration(seconds: 8);
    }
  }

  /// Validate network configuration
  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (_connectTimeout.inSeconds < 1) {
      errors.add('NETWORK_CONNECT_TIMEOUT_SECONDS must be at least 1 second');
    }

    if (_receiveTimeout.inSeconds < 5) {
      warnings.add('NETWORK_RECEIVE_TIMEOUT_SECONDS is very low (${_receiveTimeout.inSeconds}s)');
    }

    if (_maxRetries < 0) {
      errors.add('NETWORK_MAX_RETRIES cannot be negative');
    } else if (_maxRetries > 10) {
      warnings.add('NETWORK_MAX_RETRIES is very high ($_maxRetries), consider reducing');
    }

    if (_initialRetryDelay.inSeconds < 1) {
      errors.add('NETWORK_RETRY_DELAY_SECONDS must be at least 1 second');
    }

    if (_testUrls.isEmpty) {
      errors.add('NETWORK_TEST_URLS cannot be empty');
    } else {
      // Validate test URLs
      for (final url in _testUrls) {
        if (!url.startsWith('https://')) {
          warnings.add('Test URL should use HTTPS: $url');
        }
      }
    }

    if (_dnsTimeout.inSeconds < 1) {
      errors.add('NETWORK_DNS_TIMEOUT_SECONDS must be at least 1 second');
    }

    if (_supabaseTimeout.inSeconds < 5) {
      warnings.add('NETWORK_SUPABASE_TIMEOUT_SECONDS is very low (${_supabaseTimeout.inSeconds}s)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  @override
  String toString() {
    return 'NetworkConfig('
        'environment: $_environment, '
        'connectTimeout: ${_connectTimeout.inSeconds}s, '
        'receiveTimeout: ${_receiveTimeout.inSeconds}s, '
        'maxRetries: $_maxRetries, '
        'initialRetryDelay: ${_initialRetryDelay.inSeconds}s, '
        'testUrls: ${_testUrls.length} urls, '
        'dnsTimeout: ${_dnsTimeout.inSeconds}s, '
        'supabaseTimeout: ${_supabaseTimeout.inSeconds}s)';
  }
}
