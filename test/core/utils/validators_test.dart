/// ============================================================================
/// VALIDATORS TEST FILE
/// ============================================================================
/// 
/// PURPOSE: Test email and password validation functions
/// 
/// LEARNING OBJECTIVES:
/// 1. Understand the AAA pattern (Arrange-Act-Assert)
/// 2. Learn how to write unit tests in Flutter
/// 3. Practice testing edge cases
/// 4. Use the `group()` function to organize tests
///
/// ============================================================================

// IMPORT #1: Flutter's testing framework
// This gives us access to test(), expect(), group() functions
import 'package:flutter_test/flutter_test.dart';

// IMPORT #2: The code we want to test
// We're testing the validators.dart file from our app
import 'package:supabase_flutter_app/core/utils/validators.dart';

// ============================================================================
// MAIN FUNCTION
// ============================================================================
// Every test file needs a main() function
// All our tests go inside this function
void main() {
  
  // ==========================================================================
  // GROUP #1: EMAIL VALIDATION TESTS
  // ==========================================================================
  // group() organizes related tests together
  // Makes output readable: "Email Validation" → "returns true for valid email"
  group('Email Validation', () {
    
    // ========================================================================
    // TEST #1: Valid email should return true
    // ========================================================================
    test('returns true for valid email', () {
      // ----------------------------------------------------------------------
      // ARRANGE: Set up test data
      // ----------------------------------------------------------------------
      // We create a valid email address to test with
      // Using 'const' because this value never changes
      const validEmail = 'test@example.com';
      
      // ----------------------------------------------------------------------
      // ACT: Execute the function we're testing
      // ----------------------------------------------------------------------
      // Call isValidEmail() with our test email
      // Store the result so we can check it
      final result = isValidEmail(validEmail);
      
      // ----------------------------------------------------------------------
      // ASSERT: Verify the result is what we expect
      // ----------------------------------------------------------------------
      // expect(actual, expected)
      // We expect the result to be true
      // If result != true, the test FAILS
      expect(result, true);
      
      // LEARNING: This test checks the "happy path" - when everything works
    });
    
    // ========================================================================
    // TEST #2: Invalid email should return false
    // ========================================================================
    test('returns false for invalid email (no @ symbol)', () {
      // ARRANGE: Email without @ symbol
      const invalidEmail = 'notanemail';
      
      // ACT: Test the invalid email
      final result = isValidEmail(invalidEmail);
      
      // ASSERT: Should be false because email is invalid
      expect(result, false);
      
      // LEARNING: We test the "unhappy path" too - when things go wrong
    });
    
    // ========================================================================
    // TEST #3: Empty string edge case
    // ========================================================================
    test('returns false for empty string', () {
      // ARRANGE: Empty email
      const emptyEmail = '';
      
      // ACT
      final result = isValidEmail(emptyEmail);
      
      // ASSERT: Empty email is invalid
      expect(result, false);
      
      // LEARNING: Edge cases are important! Users might leave fields empty
    });
    
    // ========================================================================
    // TEST #4: Email with spaces edge case
    // ========================================================================
    test('returns false for email with spaces', () {
      // ARRANGE: Email with spaces
      const emailWithSpaces = 'test @example.com';
      
      // ACT
      final result = isValidEmail(emailWithSpaces);
      
      // ASSERT: Spaces make email invalid
      expect(result, false);
      
      // LEARNING: Testing edge cases prevents bugs in production
    });
    
    // ========================================================================
    // TEST #5: Missing domain
    // ========================================================================
    test('returns false for email missing domain', () {
      // ARRANGE: Email with @ but no domain
      const noDomain = 'test@';
      
      // ACT
      final result = isValidEmail(noDomain);
      
      // ASSERT: Should be invalid
      expect(result, false);
      
      // LEARNING: We test various invalid formats to ensure robust validation
    });
    
    // ========================================================================
    // TEST #6: Valid email with subdomain
    // ========================================================================
    test('returns true for email with subdomain', () {
      // ARRANGE: Complex but valid email
      const complexEmail = 'user@mail.example.com';
      
      // ACT
      final result = isValidEmail(complexEmail);
      
      // ASSERT: Should be valid
      expect(result, true);
      
      // LEARNING: Real emails can be complex - we test realistic scenarios
    });
  });
  
  // ==========================================================================
  // GROUP #2: PASSWORD STRENGTH TESTS
  // ==========================================================================
  // Testing the getPasswordStrength() function
  // This function returns an enum: PasswordStrength.weak/medium/strong
  group('Password Strength', () {
    
    // ========================================================================
    // TEST #7: Very short password is weak
    // ========================================================================
    test('returns weak for very short password', () {
      // ARRANGE: Super short password (only 3 characters)
      const weakPassword = '123';
      
      // ACT: Check password strength
      final strength = getPasswordStrength(weakPassword);
      
      // ASSERT: Should be classified as weak
      // We compare against the enum value
      expect(strength, PasswordStrength.weak);
      
      // LEARNING: Enums in expect() work just like other values
    });
    
    // ========================================================================
    // TEST #8: Medium password
    // ========================================================================
    test('returns medium for decent password', () {
      // ARRANGE: Password with letters and numbers (8 chars)
      const mediumPassword = 'pass1234';
      
      // ACT
      final strength = getPasswordStrength(mediumPassword);
      
      // ASSERT: Should be medium strength
      expect(strength, PasswordStrength.medium);
      
      // LEARNING: We test the middle ground, not just extremes
    });
    
    // ========================================================================
    // TEST #9: Strong password
    // ========================================================================
    test('returns strong for complex password', () {
      // ARRANGE: Long password with letters, numbers, symbols
      const strongPassword = 'MyP@ssw0rd!2024';
      
      // ACT
      final strength = getPasswordStrength(strongPassword);
      
      // ASSERT: Should be strong
      expect(strength, PasswordStrength.strong);
      
      // LEARNING: Strong passwords have length + complexity
    });
    
    // ========================================================================
    // TEST #10: Empty password is weak
    // ========================================================================
    test('returns weak for empty password', () {
      // ARRANGE: Empty string
      const emptyPassword = '';
      
      // ACT
      final strength = getPasswordStrength(emptyPassword);
      
      // ASSERT: Empty = weak
      expect(strength, PasswordStrength.weak);
      
      // LEARNING: Always test empty inputs - common edge case
    });
  });
  
  // ==========================================================================
  // GROUP #3: STRONG PASSWORD CHECK TESTS
  // ==========================================================================
  // Testing isStrongPassword() which returns bool
  group('Strong Password Check', () {
    
    // ========================================================================
    // TEST #11: Strong password returns true
    // ========================================================================
    test('returns true for strong password', () {
      // ARRANGE: Password that meets strong criteria
      const strongPass = 'SecurePass123!';
      
      // ACT
      final result = isStrongPassword(strongPass);
      
      // ASSERT: Should be true
      expect(result, true);
      
      // LEARNING: Different functions, same testing pattern (AAA)
    });
    
    // ========================================================================
    // TEST #12: Weak password returns false
    // ========================================================================
    test('returns false for weak password', () {
      // ARRANGE: Too short, too simple
      const weakPass = '123';
      
      // ACT
      final result = isStrongPassword(weakPass);
      
      // ASSERT: Should be false
      expect(result, false);
    });
    
    // ========================================================================
    // TEST #13: Medium password returns false (not strong enough)
    // ========================================================================
    test('returns false for password without letters', () {
      // ARRANGE: Password with numbers only (no letters)
      // This fails the "hasLetter" requirement in isStrongPassword()
      const noLetters = '12345678';
      
      // ACT
      final result = isStrongPassword(noLetters);
      
      // ASSERT: Should be false - missing letters
      expect(result, false);
      
      // LEARNING: We discovered through TESTING that isStrongPassword checks:
      // 1. Length >= 6
      // 2. Has at least one letter
      // 3. Has at least one number
      // 
      // Any password meeting ALL THREE criteria returns true!
      // This is why testing is valuable - it documents behavior
    });
  });
}

// ============================================================================
// SUMMARY OF WHAT WE LEARNED:
// ============================================================================
//
// 1. AAA PATTERN:
//    - Arrange: Set up test data
//    - Act: Call the function
//    - Assert: Check the result
//
// 2. TEST ORGANIZATION:
//    - group(): Organize related tests
//    - test(): Define individual test cases
//    - Clear naming: Describe what's being tested
//
// 3. WHY WE TEST:
//    - Catch bugs early
//    - Document expected behavior
//    - Prevent regressions
//    - Enable refactoring
//
// 4. WHAT TO TEST:
//    - Happy path (valid inputs)
//    - Unhappy path (invalid inputs)
//    - Edge cases (empty, null, extremes)
//    - Boundary conditions
//
// 5. EXPECT FUNCTION:
//    - expect(actual, expected)
//    - Test passes if they match
//    - Test fails if they don't match
//
// ============================================================================
