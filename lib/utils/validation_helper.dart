import 'package:nlaabo/constants/app_constants.dart';

/// Centralized validation helper
class ValidationHelper {
  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < ValidationConstraints.minPasswordLength) {
      return 'Password must be at least ${ValidationConstraints.minPasswordLength} characters';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.length < ValidationConstraints.minNameLength) {
      return 'Name must be at least ${ValidationConstraints.minNameLength} characters';
    }
    if (value.length > ValidationConstraints.maxNameLength) {
      return 'Name must not exceed ${ValidationConstraints.maxNameLength} characters';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone format';
    }
    return null;
  }

  /// Validate age
  static String? validateAge(int? value) {
    if (value == null) return null; // Optional
    if (value < ValidationConstraints.minAge || value > ValidationConstraints.maxAge) {
      return 'Age must be between ${ValidationConstraints.minAge} and ${ValidationConstraints.maxAge}';
    }
    return null;
  }

  /// Validate gender
  static String? validateGender(String? value) {
    if (value == null) return null; // Optional
    if (!Genders.all.contains(value)) {
      return 'Invalid gender';
    }
    return null;
  }

  /// Validate role
  static String? validateRole(String? value) {
    if (value == null) return 'Role is required';
    if (!UserRoles.all.contains(value)) {
      return 'Invalid role';
    }
    return null;
  }

  /// Validate match status
  static String? validateMatchStatus(String? value) {
    if (value == null) return 'Status is required';
    if (!MatchStatus.all.contains(value)) {
      return 'Invalid status';
    }
    return null;
  }

  /// Validate location
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) return 'Location is required';
    if (value.length > ValidationConstraints.maxLocationLength) {
      return 'Location must not exceed ${ValidationConstraints.maxLocationLength} characters';
    }
    return null;
  }

  /// Validate bio
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length > ValidationConstraints.maxBioLength) {
      return 'Bio must not exceed ${ValidationConstraints.maxBioLength} characters';
    }
    return null;
  }
}
