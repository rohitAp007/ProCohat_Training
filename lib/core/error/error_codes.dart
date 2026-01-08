/// Error code constants for the application
/// 
/// Format: PREFIX-XXX where PREFIX indicates the category
/// - AUTH: Authentication errors
/// - NET: Network errors  
/// - VAL: Validation errors
/// - ERR: General/Unknown errors
class ErrorCodes {
  // Authentication Errors (AUTH-XXX)
  static const String invalidCredentials = 'AUTH-001';
  static const String emailAlreadyExists = 'AUTH-002';
  static const String weakPassword = 'AUTH-003';
  static const String userNotFound = 'AUTH-004';
  static const String emailNotConfirmed = 'AUTH-005';
  static const String sessionExpired = 'AUTH-006';
  static const String rateLimitExceeded = 'AUTH-007';
  
  // Network Errors (NET-XXX)
  static const String noInternet = 'NET-001';
  static const String serverError = 'NET-002';
  static const String timeout = 'NET-003';
  
  // Validation Errors (VAL-XXX)
  static const String invalidEmail = 'VAL-001';
  static const String passwordMismatch = 'VAL-002';
  static const String requiredField = 'VAL-003';
  
  // General Errors (ERR-XXX)
  static const String unknown = 'ERR-001';
  
  /// Get human-readable description for error code
  static String getDescription(String code) {
    switch (code) {
      case invalidCredentials:
        return 'Invalid email or password';
      case emailAlreadyExists:
        return 'Email already registered';
      case weakPassword:
        return 'Password too weak';
      case userNotFound:
        return 'User not found';
      case emailNotConfirmed:
        return 'Email not verified';
      case sessionExpired:
        return 'Session expired';
      case rateLimitExceeded:
        return 'Too many requests';
      case noInternet:
        return 'No internet connection';
      case serverError:
        return 'Server error';
      case timeout:
        return 'Request timeout';
      case invalidEmail:
        return 'Invalid email format';
      case passwordMismatch:
        return 'Passwords do not match';
      case requiredField:
        return 'Required field missing';
      default:
        return 'Unknown error';
    }
  }
}
