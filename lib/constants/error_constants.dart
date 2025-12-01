/// Error messages
class ErrorMessages {
  // Network errors
  static const String networkError = 'Network connection failed. Please check your internet connection.';
  static const String timeout = 'Request timed out. Please try again.';
  static const String noInternet = 'No internet connection available.';
  static const String serverError = 'Server error occurred. Please try again later.';

  // Auth errors
  static const String invalidCredentials = 'Invalid email or password.';
  static const String emailNotConfirmed = 'Please confirm your email address before logging in.';
  static const String accountLocked = 'Your account has been temporarily suspended.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  static const String unauthorized = 'You are not authorized to perform this action.';

  // Validation errors
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidPassword = 'Password must be at least 6 characters.';
  static const String invalidName = 'Name must be between 2 and 100 characters.';
  static const String invalidPhone = 'Please enter a valid phone number.';
  static const String invalidAge = 'Age must be between 13 and 120.';
  static const String requiredField = 'This field is required.';
  static const String emailAlreadyExists = 'An account with this email already exists.';
  static const String teamNameExists = 'A team with this name already exists.';

  // Database errors
  static const String databaseError = 'Database error occurred. Please try again.';
  static const String duplicateEntry = 'This entry already exists.';
  static const String notFound = 'The requested item was not found.';

  // Upload errors
  static const String uploadFailed = 'Failed to upload file. Please try again.';
  static const String fileTooLarge = 'File size is too large.';
  static const String invalidFileType = 'Invalid file type.';

  // Generic errors
  static const String genericError = 'An unexpected error occurred. Please try again.';
  static const String operationFailed = 'Operation failed. Please try again.';
  static const String tryAgainLater = 'Please try again later.';
}

/// Success messages
class SuccessMessages {
  static const String loginSuccess = 'Login successful.';
  static const String signupSuccess = 'Account created successfully. Please check your email to confirm.';
  static const String logoutSuccess = 'Logged out successfully.';
  static const String profileUpdated = 'Profile updated successfully.';
  static const String teamCreated = 'Team created successfully.';
  static const String teamDeleted = 'Team deleted successfully.';
  static const String matchCreated = 'Match created successfully.';
  static const String matchJoined = 'You have joined the match.';
  static const String matchLeft = 'You have left the match.';
  static const String requestSent = 'Request sent successfully.';
  static const String requestApproved = 'Request approved.';
  static const String requestRejected = 'Request rejected.';
  static const String passwordReset = 'Password reset successfully.';
  static const String passwordResetEmailSent = 'Password reset email sent. Please check your email.';
}

/// Error recovery messages
class ErrorRecoveryMessages {
  static const String checkConnection = 'Please check your internet connection and try again.';
  static const String tryAgain = 'Please try again.';
  static const String contactSupport = 'If the problem persists, please contact support.';
  static const String refreshPage = 'Please refresh the page and try again.';
  static const String loginAgain = 'Please login again and try.';
  static const String checkInput = 'Please check your input and try again.';
}
