import 'package:equatable/equatable.dart';

/// Phone Authentication States
abstract class PhoneAuthState extends Equatable {
  const PhoneAuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PhoneAuthInitial extends PhoneAuthState {
  const PhoneAuthInitial();
}

/// Sending OTP
class PhoneAuthSendingOTP extends PhoneAuthState {
  const PhoneAuthSendingOTP();
}

/// OTP sent successfully
class PhoneAuthOTPSent extends PhoneAuthState {
  final String verificationId;
  final String phoneNumber;

  const PhoneAuthOTPSent({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

/// Verifying OTP
class PhoneAuthVerifying extends PhoneAuthState {
  const PhoneAuthVerifying();
}

/// Authentication successful
class PhoneAuthSuccess extends PhoneAuthState {
  final String userId;
  final String phoneNumber;

  const PhoneAuthSuccess({
    required this.userId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [userId, phoneNumber];
}

/// Authentication error
class PhoneAuthError extends PhoneAuthState {
  final String message;
  final bool isRecoverable;

  const PhoneAuthError({
    required this.message,
    this.isRecoverable = true,
  });

  @override
  List<Object?> get props => [message, isRecoverable];
}
