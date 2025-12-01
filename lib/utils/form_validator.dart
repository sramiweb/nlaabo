import '../services/localization_service.dart';

/// Consolidated form validation utility
class FormValidator {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('email_required');
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return LocalizationService().translate('email_invalid');
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('password_required');
    }
    if (value.length < 8) {
      return LocalizationService().translate('password_min_length');
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return LocalizationService().translate('password_uppercase');
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return LocalizationService().translate('password_lowercase');
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return LocalizationService().translate('password_digit');
    }
    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('confirm_password_required');
    }
    if (value != password) {
      return LocalizationService().translate('passwords_not_match');
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('name_required');
    }
    if (value.length < 2) {
      return LocalizationService().translate('name_min_length');
    }
    if (value.length > 50) {
      return LocalizationService().translate('name_max_length');
    }
    return null;
  }

  /// Validate age
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('age_required');
    }
    final age = int.tryParse(value);
    if (age == null) {
      return LocalizationService().translate('age_invalid');
    }
    if (age < 13) {
      return LocalizationService().translate('age_min');
    }
    if (age > 120) {
      return LocalizationService().translate('age_max');
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('phone_required');
    }
    if (value.length < 10) {
      return LocalizationService().translate('phone_invalid');
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName ${LocalizationService().translate('is_required')}';
    }
    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('url_required');
    }
    if (!RegExp(r'^https?://').hasMatch(value)) {
      return LocalizationService().translate('url_invalid');
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('field_required');
    }
    if (value.length < minLength) {
      return 'Minimum $minLength characters required';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > maxLength) {
      return 'Maximum $maxLength characters allowed';
    }
    return null;
  }

  /// Validate numeric value
  static String? validateNumeric(String? value) {
    if (value == null || value.isEmpty) {
      return LocalizationService().translate('field_required');
    }
    if (int.tryParse(value) == null) {
      return LocalizationService().translate('must_be_number');
    }
    return null;
  }

  /// Validate match between two fields
  static String? validateMatch(String? value, String otherValue, String fieldName) {
    if (value != otherValue) {
      return '$fieldName does not match';
    }
    return null;
  }
}
