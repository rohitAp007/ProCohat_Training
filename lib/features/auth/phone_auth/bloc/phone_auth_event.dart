import 'package:equatable/equatable.dart';

/// Phone Authentication Events
abstract class PhoneAuthEvent extends Equatable {
  const PhoneAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Send OTP to phone number
class PhoneOTPSendRequested extends PhoneAuthEvent {
  final String phoneNumber;
  final String countryCode;

  const PhoneOTPSendRequested({
    required this.phoneNumber,
    required this.countryCode,
  });

  String get fullPhoneNumber => '$countryCode$phoneNumber';

  @override
  List<Object?> get props => [phoneNumber, countryCode];
}

/// Verify OTP code
class PhoneOTPVerifyRequested extends PhoneAuthEvent {
  final String otpCode;

  const PhoneOTPVerifyRequested({required this.otpCode});

  @override
  List<Object?> get props => [otpCode];
}

/// Resend OTP
class PhoneOTPResendRequested extends PhoneAuthEvent {
  const PhoneOTPResendRequested();
}

/// Sign out
class PhoneAuthSignOutRequested extends PhoneAuthEvent {
  const PhoneAuthSignOutRequested();
}
