/// ============================================================================
/// LOGIN BLOC TEST FILE - EDUCATIONAL VERSION
/// ============================================================================
/// 
/// PURPOSE: Test LoginBloc behavior with mocked dependencies
/// 
/// LEARNING OBJECTIVES:
/// 1. Understand BLoC testing with blocTest package
/// 2. Learn mocking with mocktail
/// 3. Test asynchronous event-state flows
/// 4. Verify BLoC interacts correctly with repository
///
/// KEY CONCEPTS COVERED:
/// - Mocking dependencies (AuthRepository)
/// - Testing state emissions
/// - Async event handling
/// - Error handling in BLoCs
///
/// ============================================================================

// ============================================================================
// IMPORTS EXPLAINED
// ============================================================================

// IMPORT #1: Flutter's testing framework
// Provides test(), expect(), group() functions
import 'package:flutter_test/flutter_test.dart';

// IMPORT #2: BLoC testing package
// Provides blocTest() function specifically designed for testing BLoCs
import 'package:bloc_test/bloc_test.dart';

// IMPORT #3: Mocking package
// Allows us to create fake versions of classes (mocks)
import 'package:mocktail/mocktail.dart';

// IMPORT #4-8: Our app code to test
import 'package:supabase_flutter_app/features/auth/login/bloc/login_bloc.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_event.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_state.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// MOCK CLASSES - CREATING FAKE DEPENDENCIES
// ============================================================================

/// Mock version of AuthRepository
/// 
/// WHAT IS A MOCK?
/// A mock is a fake version of a class that we control completely.
/// We can make it return whatever we want, throw errors, etc.
/// 
/// WHY MOCK?
/// 1. Tests run fast (no real API calls)
/// 2. Tests are predictable (no network variability)
/// 3. Can simulate errors easily
/// 4. No need for real Supabase setup
/// 
/// HOW IT WORKS:
/// - extends Mock: Gives mocking superpowers from mocktail
/// - implements AuthRepository: Has same methods as real repository
/// - We configure behavior with when().thenAnswer()
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock version of Supabase User
/// 
/// WHY MOCK USER?
/// - Supabase User is a complex class
/// - We don't need real user data for tests
/// - Just need something to return from signIn()
class MockUser extends Mock implements User {}

// ============================================================================
// MAIN TEST FUNCTION
// ============================================================================

void main() {
  // --------------------------------------------------------------------------
  // GROUP: All LoginBloc tests
  // --------------------------------------------------------------------------
  group('LoginBloc', () {
    // ------------------------------------------------------------------------
    // TEST SETUP
    // ------------------------------------------------------------------------
    // Declare variables we'll use across tests
    // 'late' means "will be initialized before use"
    late MockAuthRepository mockAuthRepository;

    // ------------------------------------------------------------------------
    // setUp() - Runs BEFORE each test
    // ------------------------------------------------------------------------
    // Purpose: Prepare fresh test conditions for every test
    // Why: Keeps tests isolated - one test doesn't affect another
    setUp(() {
      // Create fresh mock repository
      mockAuthRepository = MockAuthRepository();
    });

    // ========================================================================
    // TEST #1: Initial State
    // ========================================================================
    // LEARNING: BLoCs start with an initial state
    // We defined this in LoginBloc constructor: super(LoginInitial())
    test('initial state is LoginInitial', () {
      // ARRANGE: Create BLoC
      final bloc = LoginBloc(authRepository: mockAuthRepository);

      // ASSERT: Check BLoC's current state
      // isA<Type>() is a type matcher - checks if value is of Type
      expect(bloc.state, isA<LoginInitial>());

      // CLEANUP: Close BLoC (important to prevent memory leaks)
      bloc.close();

      // WHY THIS TEST?
      // Ensures BLoC starts in correct state before any events
    });

    // ========================================================================
    // GROUP #1: EMAIL CHANGED EVENT TESTS
    // ========================================================================
    // Tests for when user types in email field
    group('LoginEmailChanged', () {
      // ======================================================================
      // TEST #2: Valid email updates state correctly
      // ======================================================================
      // blocTest is a special testing function for BLoCs
      // It's better than regular test() because it:
      // - Handles async state changes automatically
      // - Collects all emitted states
      // - Makes assertions easier
      blocTest<LoginBloc, LoginState>(
        // Test description (should be clear!)
        'emits LoginEditing with valid email',

        // BUILD: Create the BLoC to test
        // This function runs before each test
        // Returns a fresh LoginBloc instance
        build: () => LoginBloc(authRepository: mockAuthRepository),

        // ACT: Add an event to the BLoC
        // This simulates user typing a valid email
        // (bloc) parameter is the BLoC from build()
        act: (bloc) => bloc.add(const LoginEmailChanged('test@example.com')),

        // EXPECT: List of states we expect to see
        // This is a list because BLoC might emit multiple states
        // Order matters! States should appear in this sequence
        expect: () => [
          // isA<Type>() checks state type
          // .having() checks specific property values
          isA<LoginEditing>()
              // First check: email property should match
              .having((s) => s.email, 'email', 'test@example.com')
              // Second check: email should be valid
              .having((s) => s.isEmailValid, 'isEmailValid', true),
        ],

        // LEARNING POINTS:
        // 1. blocTest automatically waits for async operations
        // 2. It collects ALL states emitted during act()
        // 3. Test passes if actual states match expected states
        // 4. having() allows checking individual properties
      );

      // ======================================================================
      // TEST #3: Invalid email updates state correctly
      // ======================================================================
      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with invalid email',

        build: () => LoginBloc(authRepository: mockAuthRepository),

        // ACT: Add event with INVALID email (no @ symbol)
        act: (bloc) => bloc.add(const LoginEmailChanged('invalid-email')),

        // EXPECT: State should show email as invalid
        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.email, 'email', 'invalid-email')
              // isEmailValid should be FALSE
              .having((s) => s.isEmailValid, 'isEmailValid', false),
        ],

        // LEARNING: We test both valid AND invalid cases
        // This ensures validation logic works correctly
      );
    });

    // ========================================================================
    // GROUP #2: PASSWORD CHANGED EVENT TESTS
    // ========================================================================
    group('LoginPasswordChanged', () {
      // ======================================================================
      // TEST #4: Valid password updates state
      // ======================================================================
      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with valid password',

        build: () => LoginBloc(authRepository: mockAuthRepository),

        // ACT: Add password that meets requirements
        // 'password123' has 11 chars, letters AND numbers
        act: (bloc) => bloc.add(const LoginPasswordChanged('password123')),

        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.password, 'password', 'password123')
              // Should be valid (6+ chars, has letters and numbers)
              .having((s) => s.isPasswordValid, 'isPasswordValid', true),
        ],
      );

      // ======================================================================
      // TEST #5: Weak password is invalid
      // ======================================================================
      blocTest<LoginBloc, LoginState>(
        'emits LoginEditing with invalid password (too short)',

        build: () => LoginBloc(authRepository: mockAuthRepository),

        // ACT: Password too short (only 5 chars, needs 6+)
        act: (bloc) => bloc.add(const LoginPasswordChanged('12345')),

        expect: () => [
          isA<LoginEditing>()
              .having((s) => s.password, 'password', '12345')
              // Should be invalid (too short)
              .having((s) => s.isPasswordValid, 'isPasswordValid', false),
        ],
      );
    });

    // ========================================================================
    // GROUP #3: LOGIN SUBMITTED - SUCCESS CASE
    // ========================================================================
    // Most complex test - involves mocking API call
    group('LoginSubmitted', () {
      // Create mock user once for this group
      final mockUser = MockUser();

      // ======================================================================
      // TEST #6: Successful login flow
      // ======================================================================
      blocTest<LoginBloc, LoginState>(
        'emits [LoginInProgress, LoginSuccess] when login succeeds',

        // setUp: Runs BEFORE this specific test
        // Different from outer setUp - this is test-specific
        setUp: () {
          // CONFIGURE MOCK BEHAVIOR
          // "When signInWithEmail() is called, return mockUser"
          when(() => mockAuthRepository.signInWithEmail(
                email: any(named: 'email'), // any() = accept any value
                password: any(named: 'password'),
              )).thenAnswer((_) async => mockUser);

          // EXPLANATION:
          // - when(() => ...) : "When this method is called"
          // - any(named: 'x') : "With any value for parameter x"
          // - thenAnswer((_) async => ...) : "Return this value"
          // - async: Because signInWithEmail() is async
        },

        build: () => LoginBloc(authRepository: mockAuthRepository),

        // seed: Pre-populate BLoC with this state before act()
        // Why? LoginSubmitted reads email/password from current state
        seed: () => const LoginEditing(
          email: 'test@example.com',
          password: 'password123',
          isEmailValid: true,
          isPasswordValid: true,
        ),

        // ACT: Trigger login
        act: (bloc) => bloc.add(const LoginSubmitted()),

        // EXPECT TWO STATES:
        // 1. LoginInProgress (showing loading spinner)
        // 2. LoginSuccess (login completed)
        expect: () => [
          isA<LoginInProgress>()
              .having((s) => s.isSubmitting, 'isSubmitting', true),
          isA<LoginSuccess>().having((s) => s.isSuccess, 'isSuccess', true),
        ],

        // verify: Checks that mock methods were called
        // Ensures BLoC actually used the repository
        verify: (_) {
          verify(() => mockAuthRepository.signInWithEmail(
                email: 'test@example.com',
                password: 'password123',
              )).called(1); // Called exactly once
        },

        // LEARNING POINTS:
        // 1. We mock async operations (repository.signInWithEmail)
        // 2. BLoC emits multiple states during login process
        // 3. Order matters: loading THEN success
        // 4. verify() ensures repository was actually called
        // 5. This tests the "happy path" - when everything works
      );

      // ======================================================================
      // TEST #7: Invalid credentials error
      // ======================================================================
      blocTest<LoginBloc, LoginState>(
        'emits [LoginInProgress, LoginFailure] when login fails with invalid credentials',

        setUp: () {
          // CONFIGURE MOCK TO THROW ERROR
          // "When signInWithEmail() is called, throw InvalidCredentialsException"
          when(() => mockAuthRepository.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(InvalidCredentialsException());

          // EXPLANATION:
          // - thenThrow() instead of thenAnswer()
          // - Simulates wrong password scenario
          // - BLoC should catch and emit failure state
        },

        build: () => LoginBloc(authRepository: mockAuthRepository),

        seed: () => const LoginEditing(
          email: 'test@example.com',
          password: 'wrongpassword',
          isEmailValid: true,
          isPasswordValid: true,
        ),

        act: (bloc) => bloc.add(const LoginSubmitted()),

        // EXPECT: Loading state, then failure with error message
        expect: () => [
          isA<LoginInProgress>(),
          isA<LoginFailure>()
              // Check error message contains expected text
              .having((s) => s.errorMessage, 'errorMessage',
                  contains('Invalid email or password')),
        ],

        // LEARNING: contains() matcher checks if string contains substring
        // More flexible than exact match
      );

      // ======================================================================
      // TEST #8: Form validation prevents submission
      // ======================================================================
      blocTest<LoginBloc, LoginState>(
        'does not emit any state when form is invalid',

        build: () => LoginBloc(authRepository: mockAuthRepository),

        // seed: Start with INVALID form state
        seed: () => const LoginEditing(
          email: 'invalid', // No @ symbol
          password: '123', // Too short
          isEmailValid: false,
          isPasswordValid: false,
        ),

        act: (bloc) => bloc.add(const LoginSubmitted()),

        // EXPECT: NO states emitted (submission blocked)
        expect: () => [],

        // LEARNING: BLoC should validate before making API call
        // Invalid forms should not trigger network requests
        // This prevents unnecessary API calls and wasted resources
      );
    });
  });
}

// ============================================================================
// SUMMARY OF WHAT WE LEARNED:
// ============================================================================
//
// 1. MOCKING WITH MOCKTAIL:
//    - Create mock classes: class MockX extends Mock implements X {}
//    - Configure behavior: when(() => method()).thenAnswer(...)
//    - Simulate errors: when(() => method()).thenThrow(...)
//    - Use any(named: 'param') for flexible argument matching
//    - Verify calls: verify(() => method()).called(n)
//
// 2. BLOC TESTING WITH blocTest:
//    - build: Create BLoC instance
//    - setUp: Configure mocks before test
//    - seed: Pre-populate BLoC state
//    - act: Dispatch events
//    - expect: List of expected states in order
//    - verify: Check mock interactions
//    - Automatically handles async operations
//
// 3. TESTING PATTERNS:
//    - Test initial state
//    - Test each event type (email change, password change, submit)
//    - Test success scenarios
//    - Test all error scenarios
//    - Test validation logic
//
// 4. STATE ASSERTIONS:
//    - Type checking: isA<LoginSuccess>()
//    - Property checking: .having((s) => s.prop, 'name', value)
//    - String matching: contains('substring')
//
// 5. WHY THIS MATTERS:
//    - Ensures BLoC behaves correctly
//    - Catches bugs before production
//    - Documents expected behavior
//    - Enables confident refactoring
//    - Proves repository integration works
//
// 6. BEST PRACTICES:
//    - One scenario per test
//    - Clear test names
//    - Fresh mocks for each test (setUp)
//    - Clean up resources (bloc.close() or tearDown)
//    - Test both success and failure paths
//    - Verify repository calls
//    - Use seed() to set up complex state
//
// 7. COMMON PATTERNS:
//    - arrange/build → act → assert/expect
//    - Mock dependencies
//    - Test state transitions
//    - Verify side effects (API calls)
//
// ============================================================================
