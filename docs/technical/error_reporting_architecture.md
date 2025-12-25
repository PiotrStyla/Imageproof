# VIMz Error Reporting Architecture

## Overview
Comprehensive error handling and reporting system for VIMz application, ensuring robust operation and detailed debugging information.

## Error Classification

### Error Types
1. **User Errors**: Invalid input, permission issues, network problems
2. **System Errors**: Memory constraints, processing failures, storage issues
3. **Cryptographic Errors**: Proof generation failures, verification errors
4. **Platform Errors**: OS-specific issues, hardware limitations
5. **Development Errors**: Programming errors, assertion failures

### Severity Levels
- **Critical**: App crashes, data loss, security breaches
- **High**: Feature failures, proof generation failures
- **Medium**: Performance issues, UI glitches
- **Low**: Minor bugs, cosmetic issues

## Error Handling Strategy

### Global Error Handler
```dart
// /lib/core/error/global_error_handler.dart
class GlobalErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      _reportFlutterError(details);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportPlatformError(error, stack);
      return true;
    };
  }
  
  static void _reportFlutterError(FlutterErrorDetails details) {
    ErrorReportingService.reportError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: {
        'library': details.library,
        'context': details.context,
        'informationCollector': details.informationCollector?.call(),
      },
    );
  }
  
  static void _reportPlatformError(Object error, StackTrace stack) {
    ErrorReportingService.reportError(
      Exception('Platform Error: $error'),
      stack,
      context: {'type': 'platform_error'},
    );
  }
}
```

### Service-Level Error Handling
```dart
// /lib/core/error/service_error_handler.dart
mixin ServiceErrorHandler {
  Future<Result<T>> handleServiceCall<T>(
    Future<T> Function() operation,
    String serviceName,
  ) async {
    try {
      final result = await operation();
      return Success(result);
    } on NetworkException catch (e) {
      return Failure('${serviceName} network error: ${e.message}');
    } on CryptoException catch (e) {
      return Failure('${serviceName} crypto error: ${e.message}');
    } on ValidationException catch (e) {
      return Failure('${serviceName} validation error: ${e.message}');
    } on MemoryException catch (e) {
      return Failure('${serviceName} memory error: ${e.message}');
    } catch (e, stackTrace) {
      ErrorReportingService.reportError(
        Exception('Unexpected error in $serviceName'),
        stackTrace,
        context: {'error': e.toString()},
      );
      return Failure('${serviceName} unexpected error');
    }
  }
}
```

## Custom Exception Types

### Domain-Specific Exceptions
```dart
// /lib/core/exceptions/crypto_exceptions.dart
class CryptoException implements Exception {
  final String message;
  final String? code;
  final dynamic context;
  
  const CryptoException(this.message, {this.code, this.context});
  
  @override
  String toString() => 'CryptoException: $message';
}

class ProofGenerationException extends CryptoException {
  const ProofGenerationException(String message, {dynamic context})
      : super(message, code: 'PROOF_GENERATION_FAILED', context: context);
}

class ProofVerificationException extends CryptoException {
  const ProofVerificationException(String message, {dynamic context})
      : super(message, code: 'PROOF_VERIFICATION_FAILED', context: context);
}

// /lib/core/exceptions/image_processing_exceptions.dart
class ImageProcessingException implements Exception {
  final String message;
  final String? code;
  
  const ImageProcessingException(this.message, {this.code});
  
  @override
  String toString() => 'ImageProcessingException: $message';
}

class ImageSizeExceededException extends ImageProcessingException {
  const ImageSizeExceededException(int maxSize)
      : super('Image size exceeds maximum supported size of $maxSize bytes',
            code: 'IMAGE_SIZE_EXCEEDED');
}

class UnsupportedImageFormatException extends ImageProcessingException {
  const UnsupportedImageFormatException(String format)
      : super('Unsupported image format: $format',
            code: 'UNSUPPORTED_FORMAT');
}
```

## Error Reporting Service

### Centralized Error Reporting
```dart
// /lib/core/services/error_reporting_service.dart
class ErrorReportingService {
  static const String _baseUrl = 'https://api.vimz.app/errors';
  static const int _maxRetries = 3;
  
  static Future<void> reportError(
    Exception error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    if (kDebugMode) {
      _logErrorToConsole(error, stackTrace, context);
      return;
    }
    
    final errorReport = ErrorReport(
      id: const Uuid().v4(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      context: context ?? {},
      severity: severity,
      timestamp: DateTime.now(),
      appVersion: PackageInfo.fromPlatform().then((p) => p.version),
      deviceInfo: _getDeviceInfo(),
    );
    
    await _sendErrorReport(errorReport);
  }
  
  static void _logErrorToConsole(
    Exception error,
    StackTrace stackTrace,
    Map<String, dynamic>? context,
  ) {
    debugPrint('=== ERROR REPORT ===');
    debugPrint('Error: $error');
    debugPrint('Stack: $stackTrace');
    if (context != null) {
      debugPrint('Context: $context');
    }
    debugPrint('==================');
  }
  
  static Future<void> _sendErrorReport(ErrorReport report) async {
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        final response = await dio.post(
          _baseUrl,
          data: report.toJson(),
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        
        if (response.statusCode == 200) {
          debugPrint('Error report sent successfully');
          return;
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          debugPrint('Failed to send error report after $_maxRetries attempts: $e');
        } else {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }
  }
  
  static Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }
}
```

## Error Recovery Strategies

### Automatic Recovery
```dart
// /lib/core/error/recovery_service.dart
class ErrorRecoveryService {
  static Future<bool> attemptRecovery(Exception error) async {
    switch (error.runtimeType) {
      case NetworkException:
        return await _recoverFromNetworkError(error as NetworkException);
      case MemoryException:
        return await _recoverFromMemoryError(error as MemoryException);
      case CryptoException:
        return await _recoverFromCryptoError(error as CryptoException);
      default:
        return false;
    }
  }
  
  static Future<bool> _recoverFromNetworkError(NetworkException error) async {
    // Check connectivity
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    
    if (result == ConnectivityResult.none) {
      // Wait for network restoration
      await connectivity.onConnectivityChanged.firstWhere(
        (r) => r != ConnectivityResult.none,
      );
      return true;
    }
    
    // Retry with exponential backoff
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(seconds: math.pow(2, i).toInt()));
      if (await _testConnection()) {
        return true;
      }
    }
    
    return false;
  }
  
  static Future<bool> _recoverFromMemoryError(MemoryException error) async {
    // Clear caches
    await ImageCache().clear();
    await ImageCache().clearLiveImages();
    
    // Force garbage collection
    await SystemChannels.platform.invokeMethod('System.gc');
    
    // Check available memory
    final memoryInfo = await _getMemoryInfo();
    return memoryInfo.available > memoryInfo.required;
  }
  
  static Future<bool> _recoverFromCryptoError(CryptoException error) async {
    // Reset crypto state
    await CryptoService().reset();
    
    // Reinitialize crypto module
    await CryptoService().initialize();
    
    return true;
  }
}
```

### User-Facing Error Messages
```dart
// /lib/core/error/error_messages.dart
class ErrorMessages {
  static String getUserMessage(Exception error) {
    switch (error.runtimeType) {
      case NetworkException:
        return 'Network connection issue. Please check your internet connection and try again.';
      case ImageSizeExceededException:
        return 'Image is too large. Please use an image smaller than 100MB.';
      case UnsupportedImageFormatException:
        return 'Unsupported image format. Please use JPEG, PNG, or WebP.';
      case ProofGenerationException:
        return 'Failed to generate proof. Please try again with a different image.';
      case ProofVerificationException:
        return 'Proof verification failed. The proof may be corrupted or invalid.';
      case MemoryException:
        return 'Device memory is low. Please close other apps and try again.';
      case PermissionException:
        return 'Permission denied. Please grant the necessary permissions and try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  static String getErrorAction(Exception error) {
    switch (error.runtimeType) {
      case NetworkException:
        return 'Check Connection';
      case ImageSizeExceededException:
        return 'Choose Smaller Image';
      case UnsupportedImageFormatException:
        return 'Convert Image';
      case ProofGenerationException:
        return 'Retry Generation';
      case MemoryException:
        return 'Free Memory';
      case PermissionException:
        return 'Grant Permissions';
      default:
        return 'Try Again';
    }
  }
}
```

## Error Monitoring Dashboard

### Error Analytics
```dart
// /lib/core/monitoring/error_analytics.dart
class ErrorAnalytics {
  static final Map<String, int> _errorCounts = {};
  static final List<ErrorReport> _recentErrors = [];
  
  static void recordError(ErrorReport report) {
    _errorCounts[report.error] = (_errorCounts[report.error] ?? 0) + 1;
    _recentErrors.add(report);
    
    // Keep only last 100 errors
    if (_recentErrors.length > 100) {
      _recentErrors.removeAt(0);
    }
  }
  
  static Map<String, int> getErrorCounts() => Map.unmodifiable(_errorCounts);
  
  static List<ErrorReport> getRecentErrors() => List.unmodifiable(_recentErrors);
  
  static ErrorStatistics getStatistics() {
    return ErrorStatistics(
      totalErrors: _errorCounts.values.fold(0, (a, b) => a + b),
      uniqueErrors: _errorCounts.length,
      mostCommonError: _errorCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key,
      recentErrors: _recentErrors.length,
    );
  }
}
```

## Testing Error Scenarios

### Error Injection for Testing
```dart
// /lib/testing/error_injection.dart
class ErrorInjection {
  static bool _enabled = false;
  static final Map<Type, Exception> _injectedErrors = {};
  
  static void enable() => _enabled = true;
  static void disable() => _enabled = false;
  
  static void injectError<T extends Exception>(T error) {
    _injectedErrors[T] = error;
  }
  
  static T? getInjectedError<T extends Exception>() {
    if (!_enabled) return null;
    return _injectedErrors[T] as T?;
  }
  
  static void clearErrors() => _injectedErrors.clear();
}

// Usage in tests
void main() {
  setUp(() {
    ErrorInjection.enable();
  });
  
  tearDown(() {
    ErrorInjection.disable();
    ErrorInjection.clearErrors();
  });
  
  test('handles network errors gracefully', () async {
    ErrorInjection.injectError(NetworkException('Test error'));
    
    final result = await service.fetchData();
    expect(result.isFailure, isTrue);
    expect(result.error, contains('network error'));
  });
}
```

## Production Error Handling

### Crash Reporting Integration
```dart
// /lib/core/error/crash_reporting.dart
class CrashReportingService {
  static Future<void> initialize() async {
    if (!kDebugMode) {
      // Initialize Firebase Crashlytics or similar
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  }
  
  static Future<void> reportCrash(
    Exception error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
        information: context?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList(),
      );
    }
  }
  
  static void setUserIdentifier(String userId) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }
  
  static void setCustomKey(String key, dynamic value) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }
}
```
