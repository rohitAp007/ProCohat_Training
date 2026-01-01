import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_exceptions.dart';
import 'package:supabase_flutter_app/core/utils/validators.dart';
import 'signup_event.dart';
import 'signup_state.dart';

/// Signup BLoC - Handles signup screen business logic
/// 
/// This BLoC is production-ready and reusable:
/// - Uses repository pattern for testability
/// - Handles real-time validation with password strength
/// - Validates password confirmation
/// - Provides detailed error messages
/// - Can be copied to any project
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final AuthRepository _authRepository;

  SignupBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const SignupInitial()) {
    // Register event handlers
    on<SignupEmailChanged>(_onEmailChanged);
    on<SignupPasswordChanged>(_onPasswordChanged);
    on<SignupConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  /// Handle email field changes - validates in real-time
  void _onEmailChanged(
    SignupEmailChanged event,
    Emitter<SignupState> emit,
  ) {
    final isValid = isValidEmail(event.email);

    emit(SignupEditing(
      email: event.email,
      password: state.password,
      confirmPassword: state.confirmPassword,
      isEmailValid: isValid,
      isPasswordValid: state.isPasswordValid,
      doPasswordsMatch: state.doPasswordsMatch,
      passwordStrength: state.passwordStrength,
    ));
  }

  /// Handle password field changes - validates and checks strength
  void _onPasswordChanged(
    SignupPasswordChanged event,
    Emitter<SignupState> emit,
  ) {
    final isValid = isStrongPassword(event.password);
    final strength = getPasswordStrength(event.password);
    final doMatch = event.password == state.confirmPassword && 
                    state.confirmPassword.isNotEmpty;

    emit(SignupEditing(
      email: state.email,
      password: event.password,
      confirmPassword: state.confirmPassword,
      isEmailValid: state.isEmailValid,
      isPasswordValid: isValid,
      doPasswordsMatch: doMatch,
      passwordStrength: strength,
    ));
  }

  /// Handle confirm password field changes - validates match
  void _onConfirmPasswordChanged(
    SignupConfirmPasswordChanged event,
    Emitter<SignupState> emit,
  ) {
    final doMatch = state.password == event.confirmPassword && 
                    event.confirmPassword.isNotEmpty;

    emit(SignupEditing(
      email: state.email,
      password: state.password,
      confirmPassword: event.confirmPassword,
      isEmailValid: state.isEmailValid,
      isPasswordValid: state.isPasswordValid,
      doPasswordsMatch: doMatch,
      passwordStrength: state.passwordStrength,
    ));
  }

  /// Handle signup submission - calls repository
  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    // Don't submit if form is invalid
    if (!state.isFormValid) {
      return;
    }

    // Emit loading state
    emit(SignupInProgress(
      email: state.email,
      password: state.password,
      confirmPassword: state.confirmPassword,
      isEmailValid: state.isEmailValid,
      isPasswordValid: state.isPasswordValid,
      doPasswordsMatch: state.doPasswordsMatch,
      passwordStrength: state.passwordStrength,
    ));

    try {
      // Call repository to sign up
      await _authRepository.signUpWithEmail(
        email: state.email,
        password: state.password,
      );

      // Emit success state
      emit(SignupSuccess(
        email: state.email,
        password: state.password,
      ));
    } on AppAuthException catch (e) {
      // Handle auth exceptions with user-friendly messages
      emit(SignupFailure(
        email: state.email,
        password: state.password,
        confirmPassword: state.confirmPassword,
        isEmailValid: state.isEmailValid,
        isPasswordValid: state.isPasswordValid,
        doPasswordsMatch: state.doPasswordsMatch,
        passwordStrength: state.passwordStrength,
        errorMessage: e.message,
      ));
    } catch (e) {
      // Handle unexpected errors
      emit(SignupFailure(
        email: state.email,
        password: state.password,
        confirmPassword: state.confirmPassword,
        isEmailValid: state.isEmailValid,
        isPasswordValid: state.isPasswordValid,
        doPasswordsMatch: state.doPasswordsMatch,
        passwordStrength: state.passwordStrength,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }
}
