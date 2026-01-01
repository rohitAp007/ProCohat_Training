import 'validators.dart';

/// Form field validators that return error messages
/// Use with TextFormField validator parameter

/// Email field validator
String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  
  if (!isValidEmail(value)) {
    return 'Please enter a valid email';
  }
  
  return null; // No error
}

/// Password field validator
String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  
  if (!isStrongPassword(value)) {
    return 'Password must contain letters and numbers';
  }
  
  return null; // No error
}

/// Confirm password validator (checks if passwords match)
String? confirmPasswordValidator(String? password, String? confirmPassword) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Please confirm your password';
  }
  
  if (password != confirmPassword) {
    return 'Passwords do not match';
  }
  
  return null; // No error
}

/// Generic required field validator
String? requiredValidator(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return '$fieldName is required';
  }
  return null;
}
