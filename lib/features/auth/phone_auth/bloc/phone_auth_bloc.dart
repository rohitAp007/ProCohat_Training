import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/phone_auth_repository.dart';
import '../data/phone_auth_exceptions.dart';
import 'phone_auth_event.dart';
import 'phone_auth_state.dart';

/// Phone Authentication BLoC
/// 
/// Handles phone number + OTP authentication flow with Supabase
class PhoneAuthBloc extends Bloc<PhoneAuthEvent, PhoneAuthState> {
  final PhoneAuthRepository repository;
  String? _phoneNumber;

  PhoneAuthBloc({required this.repository}) : super(const PhoneAuthInitial()) {
    on<PhoneOTPSendRequested>(_onOTPSendRequested);
    on<PhoneOTPVerifyRequested>(_onOTPVerifyRequested);
    on<PhoneOTPResendRequested>(_onOTPResendRequested);
    on<PhoneAuthSignOutRequested>(_onSignOutRequested);
  }

  /// Handle send OTP request
  Future<void> _onOTPSendRequested(
    PhoneOTPSendRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    print('📝 [PhoneAuthBloc] Received PhoneOTPSendRequested');
    print('📱 Phone: ${event.fullPhoneNumber}');
    
    emit(const PhoneAuthSendingOTP());

    _phoneNumber = event.fullPhoneNumber;

    try {
      print('🚀 [PhoneAuthBloc] Calling repository.sendOTP()');
      await repository.sendOTP(phoneNumber: event.fullPhoneNumber);
      
      print('✅ [PhoneAuthBloc] OTP sent successfully!');
      emit(PhoneAuthOTPSent(
        verificationId: event.fullPhoneNumber, // Supabase doesn't use verification ID
        phoneNumber: event.fullPhoneNumber,
      ));
    } on PhoneAuthException catch (e) {
      print('❌ [PhoneAuthBloc] PhoneAuthException: ${e.message}');
      emit(PhoneAuthError(
        message: e.message,
        isRecoverable: true,
      ));
    } catch (e) {
      print('❌ [PhoneAuthBloc] Unexpected error: $e');
      emit(PhoneAuthError(
        message: 'Failed to send OTP: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Handle verify OTP request
  Future<void> _onOTPVerifyRequested(
    PhoneOTPVerifyRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    if (_phoneNumber == null) {
      emit(const PhoneAuthError(
        message: 'Phone number not found. Please request OTP again.',
        isRecoverable: true,
      ));
      return;
    }

    emit(const PhoneAuthVerifying());

    try {
      final user = await repository.verifyOTP(
        phoneNumber: _phoneNumber!,
        otpCode: event.otpCode,
      );

      emit(PhoneAuthSuccess(
        userId: user.id,
        phoneNumber: user.phone ?? _phoneNumber ?? '',
      ));
    } on PhoneAuthException catch (e) {
      emit(PhoneAuthError(
        message: e.message,
        isRecoverable: true,
      ));
    } catch (e) {
      emit(PhoneAuthError(
        message: 'Failed to verify OTP: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Handle resend OTP request
  Future<void> _onOTPResendRequested(
    PhoneOTPResendRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    if (_phoneNumber == null) {
      emit(const PhoneAuthError(
        message: 'Phone number not found. Please enter phone number again.',
        isRecoverable: true,
      ));
      return;
    }

    emit(const PhoneAuthSendingOTP());

    try {
      await repository.sendOTP(phoneNumber: _phoneNumber!);
      
      emit(PhoneAuthOTPSent(
        verificationId: _phoneNumber!,
        phoneNumber: _phoneNumber!,
      ));
    } on PhoneAuthException catch (e) {
      emit(PhoneAuthError(
        message: e.message,
        isRecoverable: true,
      ));
    } catch (e) {
      emit(PhoneAuthError(
        message: 'Failed to resend OTP: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Handle sign out request
  Future<void> _onSignOutRequested(
    PhoneAuthSignOutRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    try {
      await repository.signOut();
      _phoneNumber = null;
      emit(const PhoneAuthInitial());
    } catch (e) {
      emit(PhoneAuthError(
        message: 'Failed to sign out: ${e.toString()}',
        isRecoverable: false,
      ));
    }
  }
}
