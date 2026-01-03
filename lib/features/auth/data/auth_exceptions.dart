/// Custom authentication exceptions for better error handling
/// These can be reused across any project using Supabase authentication

/// Base authentication exception
class AppAuthException implements Exception {
  final String message;
  final String? code;
  final String? technicalDetails;
  final bool isRecoverable;
  final String? suggestedAction;

  AppAuthException(
    this.message, {
    this.code,
    this.technicalDetails,
    this.isRecoverable = true,
    this.suggestedAction,
  });

  @override
  String toString() => message;
}

/// Thrown when email or password is incorrect
class InvalidCredentialsException extends AppAuthException {
  InvalidCredentialsException()
      : super(
          'Invalid email or password. Please try again.',
          code: 'AUTH-001',
          isRecoverable: true,
          suggestedAction: 'Check your credentials and try again',
        );
}

/// Thrown when email is already registered
class EmailAlreadyInUseException extends AppAuthException {
  EmailAlreadyInUseException()
      : super(
          'This email is already registered. Please login instead.',
          code: 'AUTH-002',
          isRecoverable: true,
          suggestedAction: 'Try logging in or use a different email',
        );
}

/// Thrown when password doesn't meet requirements
class WeakPasswordException extends AppAuthException {
  WeakPasswordException()
      : super(
          'Password is too weak. Use at least 6 characters.',
          code: 'AUTH-003',
          isRecoverable: true,
          suggestedAction: 'Choose a stronger password',
        );
}

/// Thrown when there's no internet connection
class NetworkException extends AppAuthException {
  NetworkException()
      : super(
          'No internet connection. Please check your network.',
          code: 'NET-001',
          isRecoverable: true,
          suggestedAction: 'Check your internet connection and try again',
        );
}

/// Thrown when user is not found
class UserNotFoundException extends AppAuthException {
  UserNotFoundException()
      : super(
          'No user found with this email.',
          code: 'AUTH-004',
          isRecoverable: true,
          suggestedAction: 'Check your email or sign up',
        );
}

/// Thrown when email is not confirmed
class EmailNotConfirmedException extends AppAuthException {
  EmailNotConfirmedException()
      : super(
          'Please verify your email before logging in.',
          code: 'AUTH-005',
          isRecoverable: true,
          suggestedAction: 'Check your email for verification link',
        );
}

/// Thrown when session has expired
class SessionExpiredException extends AppAuthException {
  SessionExpiredException()
      : super(
          'Your session has expired. Please login again.',
          code: 'AUTH-006',
          isRecoverable: true,
          suggestedAction: 'Login again to continue',
        );
}

/// Thrown when rate limit is exceeded
class RateLimitException extends AppAuthException {
  RateLimitException()
      : super(
          'Too many attempts. Please try again later.',
          code: 'AUTH-007',
          isRecoverable: true,
          suggestedAction: 'Wait a few minutes before trying again',
        );
}

/// Thrown for server errors
class ServerException extends AppAuthException {
  ServerException([String? details])
      : super(
          'Server error occurred. Please try again.',
          code: 'NET-002',
          technicalDetails: details,
          isRecoverable: true,
          suggestedAction: 'Try again in a moment',
        );
}

/// Thrown for timeout errors
class TimeoutException extends AppAuthException {
  TimeoutException()
      : super(
          'Request timed out. Please try again.',
          code: 'NET-003',
          isRecoverable: true,
          suggestedAction: 'Check your connection and retry',
        );
}

/// Thrown for any other unknown errors
class UnknownAuthException extends AppAuthException {
  UnknownAuthException([String? message])
      : super(
          message ?? 'An unexpected error occurred. Please try again.',
          code: 'ERR-001',
          isRecoverable: true,
          suggestedAction: 'Try again or contact support',
        );
}
