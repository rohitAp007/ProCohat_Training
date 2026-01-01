import 'package:equatable/equatable.dart';

/// Login states - represents the current state of login screen
sealed class LoginState extends Equatable {
  final String email;
  final String password;
  final bool isEmailValid;
  final bool isPasswordValid;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const LoginState({
    required this.email,
    required this.password,
    required this.isEmailValid,
    required this.isPasswordValid,
    required this.isSubmitting,
    this.errorMessage,
    this.isSuccess = false,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        isEmailValid,
        isPasswordValid,
        isSubmitting,
        errorMessage,
        isSuccess,
      ];

  /// Helper to check if form is valid
  bool get isFormValid => isEmailValid && isPasswordValid;
}

/// Initial state when login screen loads
class LoginInitial extends LoginState {
  const LoginInitial()
      : super(
          email: '',
          password: '',
          isEmailValid: false,
          isPasswordValid: false,
          isSubmitting: false,
        );
}

/// State when user is typing - updates validation
class LoginEditing extends LoginState {
  const LoginEditing({
    required super.email,
    required super.password,
    required super.isEmailValid,
    required super.isPasswordValid,
  }) : super(
          isSubmitting: false,
          errorMessage: null,
        );
}

/// State when login is being processed
class LoginInProgress extends LoginState {
  const LoginInProgress({
    required super.email,
    required super.password,
    required super.isEmailValid,
    required super.isPasswordValid,
  }) : super(
          isSubmitting: true,
          errorMessage: null,
        );
}

/// State when login succeeds
class LoginSuccess extends LoginState {
  const LoginSuccess({
    required super.email,
    required super.password,
  }) : super(
          isEmailValid: true,
          isPasswordValid: true,
          isSubmitting: false,
          isSuccess: true,
        );
}

/// State when login fails
class LoginFailure extends LoginState {
  const LoginFailure({
    required super.email,
    required super.password,
    required super.isEmailValid,
    required super.isPasswordValid,
    required super.errorMessage,
  }) : super(
          isSubmitting: false,
        );
}

