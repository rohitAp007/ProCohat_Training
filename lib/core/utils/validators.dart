/// Reusable validation utilities
/// Can be used across any Flutter project

/// Email validation using regex
bool isValidEmail(String email) {
  if (email.isEmpty) return false;
  
  // Standard email regex pattern
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  return emailRegex.hasMatch(email.trim());
}

/// Password strength enum
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Get password strength based on criteria
PasswordStrength getPasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.weak;
  
  int strength = 0;
  
  // Length check
  if (password.length >= 8) strength++;
  if (password.length >= 12) strength++;
  
  // Contains lowercase
  if (password.contains(RegExp(r'[a-z]'))) strength++;
  
  // Contains uppercase
  if (password.contains(RegExp(r'[A-Z]'))) strength++;
  
  // Contains number
  if (password.contains(RegExp(r'[0-9]'))) strength++;
  
  // Contains special character
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
  
  if (strength <= 2) return PasswordStrength.weak;
  if (strength <= 4) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

/// Check if password meets minimum requirements
bool isStrongPassword(String password) {
  if (password.length < 6) return false;
  
  // Must contain at least one letter and one number
  final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
  final hasNumber = password.contains(RegExp(r'[0-9]'));
  
  return hasLetter && hasNumber;
}
