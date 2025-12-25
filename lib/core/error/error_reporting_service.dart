import 'package:flutter/foundation.dart';

/// Simplified error reporting service
class ErrorReportingService {
  Future<void> initialize() async {
    // Initialize error reporting
  }

  static void reportError(
    Exception error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) {
    debugPrint('Error: $error');
    debugPrint('StackTrace: $stackTrace');
    if (context != null) {
      debugPrint('Context: $context');
    }
  }
}
