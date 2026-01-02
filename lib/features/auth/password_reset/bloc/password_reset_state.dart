import 'package:equatable/equatable.dart';

/// Password reset states
sealed class PasswordResetState extends Equatable {
  final String email;
  final bool isEmailValid;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const PasswordResetState({
    required this.email,
    required this.isEmailValid,
    required this.isSubmitting,
    this.errorMessage,
    this.isSuccess = false,
  });

  @override
  List<Object?> get props => [
        email,
        isEmailValid,
        isSubmitting,
        errorMessage,
        isSuccess,
      ];
}

/// Initial state
class PasswordResetInitial extends PasswordResetState {
  const PasswordResetInitial()
      : super(
          email: '',
          isEmailValid: false,
          isSubmitting: false,
        );
}

/// State when user is typing
class PasswordResetEditing extends PasswordResetState {
  const PasswordResetEditing({
    required super.email,
    required super.isEmailValid,
  }) : super(
          isSubmitting: false,
          errorMessage: null,
        );
}

/// State when request is being processed
class PasswordResetInProgress extends PasswordResetState {
  const PasswordResetInProgress({
    required super.email,
  }) : super(
          isEmailValid: true,
          isSubmitting: true,
          errorMessage: null,
        );
}

/// State when reset email sent successfully
class PasswordResetSuccess extends PasswordResetState {
  const PasswordResetSuccess({
    required super.email,
  }) : super(
          isEmailValid: true,
          isSubmitting: false,
          isSuccess: true,
        );
}

/// State when reset fails
class PasswordResetFailure extends PasswordResetState {
  const PasswordResetFailure({
    required super.email,
    required super.isEmailValid,
    required super.errorMessage,
  }) : super(
          isSubmitting: false,
        );
}
