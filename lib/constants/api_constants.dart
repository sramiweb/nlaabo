/// API endpoints
class ApiEndpoints {
  // Auth endpoints
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String resetPassword = '/auth/reset-password';
  static const String requestPasswordReset = '/auth/request-password-reset';

  // User endpoints
  static const String users = '/users';
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String userStats = '/users/stats';

  // Team endpoints
  static const String teams = '/teams';
  static const String teamMembers = '/teams/{id}/members';
  static const String teamJoinRequests = '/teams/{id}/join-requests';
  static const String teamRecruiting = '/teams/{id}/recruiting';

  // Match endpoints
  static const String matches = '/matches';
  static const String matchParticipants = '/matches/{id}/participants';
  static const String matchResults = '/matches/{id}/results';
  static const String matchRequests = '/matches/requests';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String markAsRead = '/notifications/{id}/read';

  // City endpoints
  static const String cities = '/cities';
}

/// API response keys
class ApiResponseKeys {
  static const String data = 'data';
  static const String error = 'error';
  static const String message = 'message';
  static const String status = 'status';
  static const String code = 'code';
  static const String user = 'user';
  static const String session = 'session';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}

/// API error codes
class ApiErrorCodes {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String badRequest = 'BAD_REQUEST';
  static const String conflict = 'CONFLICT';
  static const String rateLimit = 'RATE_LIMIT';
  static const String serverError = 'SERVER_ERROR';
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';
}

/// HTTP status codes
class HttpStatusCodes {
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int rateLimit = 429;
  static const int serverError = 500;
  static const int serviceUnavailable = 503;
}
