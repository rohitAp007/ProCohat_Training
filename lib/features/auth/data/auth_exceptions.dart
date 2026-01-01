/// Custom authentication exceptions for better error handling
/// These can be reused across any project using Supabase authentication

/// Base authentication exception
class AppAuthException implements Exception {
  final String message;
  final String? code;

  AppAuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Thrown when email or password is incorrect
class InvalidCredentialsException extends AppAuthException {
  InvalidCredentialsException()
      : super('Invalid email or password. Please try again.');
}

/// Thrown when email is already registered
class EmailAlreadyInUseException extends AppAuthException {
  EmailAlreadyInUseException()
      : super('This email is already registered. Please login instead.');
}

/// Thrown when password doesn't meet requirements
class WeakPasswordException extends AppAuthException {
  WeakPasswordException()
      : super('Password is too weak. Use at least 6 characters.');
}

/// Thrown when there's no internet connection
class NetworkException extends AppAuthException {
  NetworkException()
      : super('No internet connection. Please check your network.');
}

/// Thrown when user is not found
class UserNotFoundException extends AppAuthException {
  UserNotFoundException()
      : super('No user found with this email.');
}

/// Thrown when email is not confirmed
class EmailNotConfirmedException extends AppAuthException {
  EmailNotConfirmedException()
      : super('Please verify your email before logging in.');
}

/// Thrown for any other unknown errors
class UnknownAuthException extends AppAuthException {
  UnknownAuthException([String? message])
      : super(message ?? 'An unexpected error occurred. Please try again.');
}
