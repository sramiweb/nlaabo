import 'package:flutter/foundation.dart';

/// Simplified logger for debugging Stack Overflow
void logDebug(String message) {
  if (kDebugMode) debugPrint('DEBUG: $message');
}

void logInfo(String message) {
  if (kDebugMode) debugPrint('INFO: $message');
}

void logWarning(String message) {
  if (kDebugMode) debugPrint('WARNING: $message');
}

void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  if (kDebugMode) {
    debugPrint('ERROR: $message');
    if (error != null) debugPrint('ERROR DETAILS: $error');
    if (stackTrace != null) debugPrint('STACK TRACE: $stackTrace');
  }
}
