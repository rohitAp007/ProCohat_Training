import 'package:supabase_flutter/supabase_flutter.dart';
import 'phone_auth_exceptions.dart';

/// Phone Authentication Repository using Supabase Auth
/// 
/// Handles Supabase Phone Authentication operations
class PhoneAuthRepository {
  final SupabaseClient _supabaseClient;

  PhoneAuthRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Send OTP to phone number
  /// 
  /// Supabase will send an SMS with verification code
  Future<void> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid')) {
        throw InvalidPhoneNumberException();
      } else if (e.message.toLowerCase().contains('too many')) {
        throw TooManyRequestsException();
      }
      throw UnknownPhoneAuthException(e.message);
    } catch (e) {
      if (e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      throw UnknownPhoneAuthException(e.toString());
    }
  }

  /// Verify OTP code
  /// 
  /// Returns Supabase User if successful
  Future<User> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await _supabaseClient.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.user == null) {
        throw UnknownPhoneAuthException('Failed to verify OTP');
      }

      return response.user!;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('expired')) {
        throw InvalidVerificationCodeException();
      } else if (e.message.toLowerCase().contains('expired')) {
        throw SessionExpiredException();
      }
      throw UnknownPhoneAuthException(e.message);
    } catch (e) {
      if (e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      throw UnknownPhoneAuthException(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn => _supabaseClient.auth.currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> authStateChanges() {
    return _supabaseClient.auth.onAuthStateChange;
  }
}
