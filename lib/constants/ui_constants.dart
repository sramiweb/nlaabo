/// UI durations
class UiDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration veryLong = Duration(milliseconds: 800);
  static const Duration animation = Duration(milliseconds: 300);
  static const Duration snackBar = Duration(seconds: 3);
  static const Duration dialog = Duration(milliseconds: 200);
}

/// UI delays
class UiDelays {
  static const Duration debounce = Duration(milliseconds: 500);
  static const Duration throttle = Duration(milliseconds: 300);
  static const Duration retry = Duration(seconds: 2);
  static const Duration reconnect = Duration(seconds: 5);
}

/// UI sizes
class UiSizes {
  static const double minTouchTarget = 44.0;
  static const double minButtonHeight = 48.0;
  static const double minInputHeight = 56.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
}

/// UI limits
class UiLimits {
  static const int maxSearchResults = 50;
  static const int maxFeaturedItems = 10;
  static const int maxTeamMembers = 100;
  static const int maxMatchParticipants = 50;
  static const int maxNotifications = 100;
  static const int maxImageSize = 5242880; // 5MB
}

/// Animation delays
class AnimationDelays {
  static const Duration stagger = Duration(milliseconds: 100);
  static const Duration fadeIn = Duration(milliseconds: 300);
  static const Duration slideIn = Duration(milliseconds: 400);
  static const Duration scaleIn = Duration(milliseconds: 300);
}

/// Loading states
class LoadingStates {
  static const String loading = 'loading';
  static const String loaded = 'loaded';
  static const String error = 'error';
  static const String empty = 'empty';
}

/// Dialog types
class DialogTypes {
  static const String alert = 'alert';
  static const String confirm = 'confirm';
  static const String input = 'input';
  static const String custom = 'custom';
}
