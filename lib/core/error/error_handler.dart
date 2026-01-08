import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';

/// Centralized error handler for the application
/// 
/// Provides utilities to convert exceptions into user-friendly messages,
/// get error codes, and determine recovery actions
class ErrorHandler {
  /// Convert any exception to a user-friendly message
  static String getErrorMessage(Exception exception) {
    if (exception is AppAuthException) {
      return exception.message;
    }
    
    // Handle other exception types
    final errorString = exception.toString().toLowerCase();
    
    if (errorString.contains('socket') || errorString.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error occurred. Please try again later.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
  
  /// Get error code from exception
  static String? getErrorCode(Exception exception) {
    if (exception is AppAuthException) {
      return exception.code;
    }
    return null;
  }
  
  /// Check if error is recoverable (can retry)
  static bool isRecoverable(Exception exception) {
    if (exception is AppAuthException) {
      return exception.isRecoverable;
    }
    
    // Most errors are recoverable by default
    return true;
  }
  
  /// Get suggested action for the user
  static String? getSuggestedAction(Exception exception) {
    if (exception is AppAuthException) {
      return exception.suggestedAction;
    }
    
    // Default suggestion for unknown errors
    return 'Please try again';
  }
  
  /// Get technical details for debugging
  static String? getTechnicalDetails(Exception exception) {
    if (exception is AppAuthException) {
      return exception.technicalDetails;
    }
    return exception.toString();
  }
  
  /// Determine if error should show retry button
  static bool shouldShowRetry(Exception exception) {
    if (!isRecoverable(exception)) {
      return false;
    }
    
    // Don't show retry for validation errors
    if (exception is AppAuthException) {
      if (exception.code?.startsWith('VAL') ?? false) {
        return false;
      }
    }
    
    return true;
  }
}
