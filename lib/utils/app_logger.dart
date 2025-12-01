import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: false,
  ),
  level: Level.debug,
);

/// Log debug message
void logDebug(String message) => appLogger.d(message);

/// Log info message
void logInfo(String message) => appLogger.i(message);

/// Log warning message
void logWarning(String message) => appLogger.w(message);

/// Log error message
void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  appLogger.e(message, error: error, stackTrace: stackTrace);
}
