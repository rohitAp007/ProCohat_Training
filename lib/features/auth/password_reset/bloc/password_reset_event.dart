import 'package:equatable/equatable.dart';

/// Password reset events
sealed class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when user types email
class PasswordResetEmailChanged extends PasswordResetEvent {
  final String email;

  const PasswordResetEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

/// Triggered when user submits password reset request
class PasswordResetSubmitted extends PasswordResetEvent {
  const PasswordResetSubmitted();
}

/// Triggered to reset the state (for navigation back)
class PasswordResetReset extends PasswordResetEvent {
  const PasswordResetReset();
}
