import 'package:equatable/equatable.dart';
import 'package:supabase_flutter_app/core/utils/validators.dart';

/// Signup states - represents the current state of signup screen
sealed class SignupState extends Equatable {
  final String email;
  final String password;
  final String confirmPassword;
  final bool isEmailValid;
  final bool isPasswordValid;
  final bool doPasswordsMatch;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;
  final PasswordStrength passwordStrength;

  const SignupState({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.isEmailValid,
    required this.isPasswordValid,
    required this.doPasswordsMatch,
    required this.isSubmitting,
    this.errorMessage,
    this.isSuccess = false,
    this.passwordStrength = PasswordStrength.weak,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        confirmPassword,
        isEmailValid,
        isPasswordValid,
        doPasswordsMatch,
        isSubmitting,
        errorMessage,
        isSuccess,
        passwordStrength,
      ];

  /// Helper to check if form is valid
  bool get isFormValid =>
      isEmailValid && isPasswordValid && doPasswordsMatch;
}

/// Initial state when signup screen loads
class SignupInitial extends SignupState {
  const SignupInitial()
      : super(
          email: '',
          password: '',
          confirmPassword: '',
          isEmailValid: false,
          isPasswordValid: false,
          doPasswordsMatch: false,
          isSubmitting: false,
        );
}

/// State when user is typing - updates validation
class SignupEditing extends SignupState {
  const SignupEditing({
    required super.email,
    required super.password,
    required super.confirmPassword,
    required super.isEmailValid,
    required super.isPasswordValid,
    required super.doPasswordsMatch,
    required super.passwordStrength,
  }) : super(
          isSubmitting: false,
          errorMessage: null,
        );
}

/// State when signup is being processed
class SignupInProgress extends SignupState {
  const SignupInProgress({
    required super.email,
    required super.password,
    required super.confirmPassword,
    required super.isEmailValid,
    required super.isPasswordValid,
    required super.doPasswordsMatch,
    required super.passwordStrength,
  }) : super(
          isSubmitting: true,
          errorMessage: null,
        );
}

/// State when signup succeeds
class SignupSuccess extends SignupState {
  const SignupSuccess({
    required super.email,
    required super.password,
  }) : super(
          confirmPassword: '',
          isEmailValid: true,
          isPasswordValid: true,
          doPasswordsMatch: true,
          isSubmitting: false,
          isSuccess: true,
          passwordStrength: PasswordStrength.strong,
        );
}

/// State when signup fails
class SignupFailure extends SignupState {
  const SignupFailure({
    required super.email,
    required super.password,
    required super.confirmPassword,
    required super.isEmailValid,
    required super.isPasswordValid,
    required super.doPasswordsMatch,
    required super.passwordStrength,
    required super.errorMessage,
  }) : super(
          isSubmitting: false,
        );
}
