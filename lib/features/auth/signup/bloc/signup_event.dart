import 'package:equatable/equatable.dart';

/// Signup events - all user interactions on signup screen
sealed class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when user types in email field
class SignupEmailChanged extends SignupEvent {
  final String email;

  const SignupEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

/// Triggered when user types in password field
class SignupPasswordChanged extends SignupEvent {
  final String password;

  const SignupPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

/// Triggered when user types in confirm password field
class SignupConfirmPasswordChanged extends SignupEvent {
  final String confirmPassword;

  const SignupConfirmPasswordChanged(this.confirmPassword);

  @override
  List<Object?> get props => [confirmPassword];
}

/// Triggered when user submits the signup form
class SignupSubmitted extends SignupEvent {
  const SignupSubmitted();
}
