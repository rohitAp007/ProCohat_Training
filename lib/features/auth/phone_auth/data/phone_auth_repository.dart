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
  /// In development, tries without country code for test numbers first
  Future<void> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      // Try sending OTP
      await _supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } on AuthException catch (e) {
      // If format is invalid and starts with +, try without country code
      if (e.message.toLowerCase().contains('invalid') && phoneNumber.startsWith('+')) {
        try {
          // Extract just the numbers without country code
          final withoutCountryCode = phoneNumber.substring(3); // Remove +91
          await _supabaseClient.auth.signInWithOtp(
            phone: withoutCountryCode,
          );
          return; // Success with retry
        } catch (_) {
          // If retry also fails, throw original error
        }
      }
      
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
  /// Handles both phone formats (with/without country code)
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
      // Try without country code if initial verification fails
      if (e.message.toLowerCase().contains('invalid') && phoneNumber.startsWith('+')) {
        try {
          final withoutCountryCode = phoneNumber.substring(3);
          final retryResponse = await _supabaseClient.auth.verifyOTP(
            phone: withoutCountryCode,
            token: otpCode,
            type: OtpType.sms,
          );
          
          if (retryResponse.user != null) {
            return retryResponse.user!;
          }
        } catch (_) {
          // Continue to original error handling
        }
      }
      
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
