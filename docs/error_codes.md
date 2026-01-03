# Error Code Reference Documentation

## Overview

This document provides a comprehensive reference for all error codes used in the ProCohat Training application. Error codes follow the format `PREFIX-XXX` where the prefix indicates the error category.

---

## Error Code Categories

### Authentication Errors (AUTH-XXX)

| Code | Description | User Message | Recoverable | Suggested Action |
|------|-------------|--------------|-------------|------------------|
| AUTH-001 | Invalid Credentials | Invalid email or password. Please try again. | Yes | Check your credentials and try again |
| AUTH-002 | Email Already Exists | This email is already registered. Please login instead. | Yes | Try logging in or use a different email |
| AUTH-003 | Weak Password | Password is too weak. Use at least 6 characters. | Yes | Choose a stronger password |
| AUTH-004 | User Not Found | No user found with this email. | Yes | Check your email or sign up |
| AUTH-005 | Email Not Confirmed | Please verify your email before logging in. | Yes | Check your email for verification link |
| AUTH-006 | Session Expired | Your session has expired. Please login again. | Yes | Login again to continue |
| AUTH-007 | Rate Limit Exceeded | Too many attempts. Please try again later. | Yes | Wait a few minutes before trying again |

### Network Errors (NET-XXX)

| Code | Description | User Message | Recoverable | Suggested Action |
|------|-------------|--------------|-------------|------------------|
| NET-001 | No Internet Connection | No internet connection. Please check your network. | Yes | Check your internet connection and try again |
| NET-002 | Server Error | Server error occurred. Please try again. | Yes | Try again in a moment |
| NET-003 | Request Timeout | Request timed out. Please try again. | Yes | Check your connection and retry |

### Validation Errors (VAL-XXX)

| Code | Description | User Message | Recoverable | Suggested Action |
|------|-------------|--------------|-------------|------------------|
| VAL-001 | Invalid Email Format | Please enter a valid email address. | Yes | Check email format |
| VAL-002 | Password Mismatch | Passwords do not match. | Yes | Ensure passwords match |
| VAL-003 | Required Field Missing | This field is required. | Yes | Fill in the required field |

### General Errors (ERR-XXX)

| Code | Description | User Message | Recoverable | Suggested Action |
|------|-------------|--------------|-------------|------------------|
| ERR-001 | Unknown Error | An unexpected error occurred. Please try again. | Yes | Try again or contact support |

---

## Usage in Code

### Throwing Exceptions

```dart
// Throw with specific exception class
throw InvalidCredentialsException();

// Throw with custom message
throw UnknownAuthException('Custom error message');
```

### Handling Exceptions

```dart
try {
  await authRepository.signIn(email, password);
} on InvalidCredentialsException catch (e) {
  // Handle invalid credentials
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  print('Suggested Action: ${e.suggestedAction}');
} on AppAuthException catch (e) {
  // Handle other auth exceptions
  ErrorHandler.handle(e);
}
```

### Using ErrorHandler

```dart
// Get user-friendly message
String message = ErrorHandler.getErrorMessage(exception);

// Get error code
String? code = ErrorHandler.getErrorCode(exception);

// Check if recoverable
bool canRetry = ErrorHandler.isRecoverable(exception);

// Get suggested action
String? action = ErrorHandler.getSuggestedAction(exception);
```

---

## Best Practices

### 1. Always Use Specific Exceptions
```dart
// ✅ Good
throw InvalidCredentialsException();

// ❌ Bad
throw Exception('Invalid credentials');
```

### 2. Provide Context in Error Messages
```dart
// ✅ Good
throw ServerException('Failed to process payment: ${response.error}');

// ❌ Bad
throw ServerException();
```

### 3. Log Error Codes for Debugging
```dart
if (exception is AppAuthException) {
  debugPrint('Error [${exception.code}]: ${exception.message}');
  if (exception.technicalDetails != null) {
    debugPrint('Details: ${exception.technicalDetails}');
  }
}
```

### 4. Show User-Friendly Messages
```dart
// Use ErrorHandler to get clean messages
CustomSnackBar.showError(
  context,
  ErrorHandler.getErrorMessage(exception),
);
```

---

## Adding New Error Codes

When adding new error codes:

1. **Choose appropriate prefix:**
   - AUTH for authentication
   - NET for network  
   - VAL for validation
   - ERR for general

2. **Create exception class:**
```dart
class NewErrorException extends AppAuthException {
  NewErrorException()
      : super(
          'User-friendly message',
          code: 'PREFIX-XXX',
          isRecoverable: true,
          suggestedAction: 'What user should do',
        );
}
```

3. **Update this documentation**

4. **Add to ErrorCodes class** if needed

---

## Error Logging

### Debug Mode
All errors are automatically logged in debug mode with:
- Error code
- Error message
- Technical details
- Stack trace (for unexpected errors)

### Production Mode
Only error codes and user-facing messages are logged to protect sensitive information.

---

## Common Error Scenarios

### Scenario 1: Network Connectivity
```
User tries to login without internet
→ Throws NetworkException (NET-001)
→ Shows "No internet connection" message
→ Provides "Check connection and retry" action
```

### Scenario 2: Invalid Credentials
```
User enters wrong password
→ Throws InvalidCredentialsException (AUTH-001)
→ Shows "Invalid email or password" message
→ Provides "Check credentials" action
→ Password reset option available
```

### Scenario 3: Email Already Exists
```
User tries to signup with existing email
→ Throws EmailAlreadyInUseException (AUTH-002)
→ Shows "Email already registered" message
→ Provides "Try logging in" action
→ Navigate to login option
```

---

## Support & Troubleshooting

If users encounter errors repeatedly:

1. **Check error code** - Identify the specific issue
2. **Review suggested action** - Follow recommended steps
3. **Check logs** - Look for technical details in debug mode
4. **Contact support** - Reference the error code when reporting

---

**Last Updated**: January 3, 2026  
**Version**: 1.0  
**Maintainer**: ProCohat Training Team
