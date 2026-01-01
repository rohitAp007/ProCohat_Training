import 'package:equatable/equatable.dart';

/// Login events - all user interactions on login screen
sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when user types in email field
class LoginEmailChanged extends LoginEvent {
  final String email;

  const LoginEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

/// Triggered when user types in password field
class LoginPasswordChanged extends LoginEvent {
  final String password;

  const LoginPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

/// Triggered when user submits the login form
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

/// Triggered when user requests password reset
class LoginPasswordResetRequested extends LoginEvent {
  final String email;

  const LoginPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

