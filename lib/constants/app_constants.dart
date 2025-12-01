/// User roles
class UserRoles {
  static const String player = 'player';
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  
  static const List<String> all = [player, admin, moderator];
}

/// Gender values
class Genders {
  static const String male = 'male';
  static const String female = 'female';
  static const String other = 'other';
  
  static const List<String> all = [male, female, other];
}

/// Match status values
class MatchStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String open = 'open';
  static const String closed = 'closed';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  static const String inProgress = 'in_progress';
  
  static const List<String> all = [pending, confirmed, open, closed, cancelled, completed, inProgress];
}

/// Match types
class MatchTypes {
  static const String male = 'male';
  static const String female = 'female';
  static const String mixed = 'mixed';
  
  static const List<String> all = [male, female, mixed];
}

/// Skill levels
class SkillLevels {
  static const String beginner = 'beginner';
  static const String intermediate = 'intermediate';
  static const String advanced = 'advanced';
  
  static const List<String> all = [beginner, intermediate, advanced];
}

/// Team join request status
class JoinRequestStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  
  static const List<String> all = [pending, approved, rejected];
}

/// Notification types
class NotificationTypes {
  static const String matchJoined = 'match_joined';
  static const String teamInvite = 'team_invite';
  static const String teamJoinRequest = 'team_join_request';
  static const String teamMemberLeft = 'team_member_left';
  static const String general = 'general';
  
  static const List<String> all = [matchJoined, teamInvite, teamJoinRequest, teamMemberLeft, general];
}

/// API timeouts
class ApiTimeouts {
  static const Duration short = Duration(seconds: 10);
  static const Duration medium = Duration(seconds: 30);
  static const Duration long = Duration(seconds: 60);
}

/// Pagination
class Pagination {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// Validation constraints
class ValidationConstraints {
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minBioLength = 0;
  static const int maxBioLength = 500;
  static const int minLocationLength = 2;
  static const int maxLocationLength = 100;
  static const int minAge = 13;
  static const int maxAge = 120;
  static const int minPlayers = 1;
  static const int maxPlayers = 50;
}
