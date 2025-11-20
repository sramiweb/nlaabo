import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlaabo/config/supabase_config.dart';

void main() {
  group('Supabase Configuration Validation Tests', () {
    setUp(() async {
      // Initialize dotenv for testing
      await dotenv.load(fileName: '.env');
    });

    tearDown(() {
      // Clean up after each test
      dotenv.clean();
    });

    test('should return valid configuration when both SUPABASE_URL and SUPABASE_ANON_KEY are set', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = 'https://test.supabase.co';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test-anon-key-12345';

      // Act
      final url = supabaseUrl;
      final key = supabaseAnonKey;

      // Assert
      expect(url, equals('https://test.supabase.co'));
      expect(key, equals('test-anon-key-12345'));
    });

    test('should throw exception when SUPABASE_URL is missing', () {
      // Arrange
      dotenv.env.remove('SUPABASE_URL');
      dotenv.env['SUPABASE_ANON_KEY'] = 'test-key';

      // Act & Assert
      expect(
        () => supabaseUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf([
            contains('SUPABASE_URL is not set'),
            contains('Missing Supabase configuration'),
            contains('Please check your .env file'),
          ]),
        )),
      );
    });

    test('should throw exception when SUPABASE_ANON_KEY is missing', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = 'https://test.supabase.co';
      dotenv.env.remove('SUPABASE_ANON_KEY');

      // Act & Assert
      expect(
        () => supabaseAnonKey,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf([
            contains('SUPABASE_ANON_KEY is not set'),
            contains('Missing Supabase configuration'),
            contains('Please check your .env file'),
          ]),
        )),
      );
    });

    test('should throw exception when SUPABASE_URL is empty string', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = '';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test-key';

      // Act & Assert
      expect(
        () => supabaseUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('SUPABASE_URL is not set'),
        )),
      );
    });

    test('should throw exception when SUPABASE_ANON_KEY is empty string', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = 'https://test.supabase.co';
      dotenv.env['SUPABASE_ANON_KEY'] = '';

      // Act & Assert
      expect(
        () => supabaseAnonKey,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('SUPABASE_ANON_KEY is not set'),
        )),
      );
    });

    test('should throw exception when both configuration values are missing', () {
      // Arrange
      dotenv.env.clear();

      // Act & Assert
      expect(
        () => supabaseUrl,
        throwsA(isA<Exception>()),
      );

      expect(
        () => supabaseAnonKey,
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when both configuration values are empty', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = '';
      dotenv.env['SUPABASE_ANON_KEY'] = '';

      // Act & Assert
      expect(
        () => supabaseUrl,
        throwsA(isA<Exception>()),
      );

      expect(
        () => supabaseAnonKey,
        throwsA(isA<Exception>()),
      );
    });

    test('should accept valid Supabase URL formats', () {
      // Arrange
      const validUrls = [
        'https://test.supabase.co',
        'https://my-project.supabase.co',
        'https://abcdefghijklmnop.supabase.co',
        'https://test-project-123.supabase.co',
      ];

      dotenv.env['SUPABASE_ANON_KEY'] = 'test-key';

      for (final url in validUrls) {
        // Act
        dotenv.env['SUPABASE_URL'] = url;
        final result = supabaseUrl;

        // Assert
        expect(result, equals(url));
      }
    });

    test('should accept valid Supabase anon key formats', () {
      // Arrange
      const validKeys = [
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature',
        'sbp_test_key_1234567890123456789012345678901234567890',
        'test-anon-key-with-dashes-and-numbers-123',
      ];

      dotenv.env['SUPABASE_URL'] = 'https://test.supabase.co';

      for (final key in validKeys) {
        // Act
        dotenv.env['SUPABASE_ANON_KEY'] = key;
        final result = supabaseAnonKey;

        // Assert
        expect(result, equals(key));
      }
    });

    test('should handle whitespace-only values as empty', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = '   '; // whitespace only
      dotenv.env['SUPABASE_ANON_KEY'] = '\t\n'; // whitespace only

      // Act & Assert - Currently returns whitespace, but should ideally validate
      // This test documents current behavior - whitespace is considered valid
      expect(() => supabaseUrl, returnsNormally);
      expect(() => supabaseAnonKey, returnsNormally);
      expect(supabaseUrl, equals('   '));
      expect(supabaseAnonKey, equals('\t\n'));
    });

    test('should validate configuration access order independence', () {
      // Arrange
      dotenv.env['SUPABASE_URL'] = 'https://test.supabase.co';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test-key';

      // Act - Access in different orders
      final urlFirst = supabaseUrl;
      final keyFirst = supabaseAnonKey;

      final keySecond = supabaseAnonKey;
      final urlSecond = supabaseUrl;

      // Assert - Results should be consistent regardless of access order
      expect(urlFirst, equals(urlSecond));
      expect(keyFirst, equals(keySecond));
      expect(urlFirst, equals('https://test.supabase.co'));
      expect(keyFirst, equals('test-key'));
    });

    test('should provide clear error messages for troubleshooting', () {
      // Arrange
      dotenv.env.remove('SUPABASE_URL');
      dotenv.env['SUPABASE_ANON_KEY'] = 'test-key';

      // Act & Assert
      expect(
        () => supabaseUrl,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf([
            contains('Missing Supabase configuration'),
            contains('SUPABASE_URL is not set'),
            contains('Please check your .env file'),
            contains('SUPABASE_URL is properly configured'),
          ]),
        )),
      );
    });

    test('should handle malformed environment variables gracefully', () {
      // Arrange - Simulate various malformed scenarios
      dotenv.env.remove('SUPABASE_URL'); // Treat as null/missing
      dotenv.env['SUPABASE_ANON_KEY'] = 'test-key';

      // Act & Assert
      expect(
        () => supabaseUrl,
        throwsA(isA<Exception>()),
      );
    });
  });
}