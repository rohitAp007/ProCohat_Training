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
  /// For test OTPs, tries without country code first (as configured in Supabase)
  Future<void> sendOTP({
    required String phoneNumber,
  }) async {
    // Extract number without country code for test OTPs
    String numberWithoutCode = phoneNumber;
    if (phoneNumber.startsWith('+')) {
      // Remove country code (e.g., +91 = 3 chars)
      numberWithoutCode = phoneNumber.substring(3);
    }
    
    try {
      // FIRST: Try without country code (for Supabase test OTPs)
      // Test OTPs are configured like: 7666086414=4685
      await _supabaseClient.auth.signInWithOtp(
        phone: numberWithoutCode,
      );
      return; // Success!
    } on AuthException catch (e) {
      // If that failed, try with full number (for real Twilio SMS)
      if (phoneNumber != numberWithoutCode) {
        try {
          await _supabaseClient.auth.signInWithOtp(
            phone: phoneNumber,
          );
          return; // Success with full number!
        } on AuthException catch (e2) {
          // Both attempts failed, use the second error
          if (e2.message.toLowerCase().contains('invalid')) {
            throw InvalidPhoneNumberException();
          } else if (e2.message.toLowerCase().contains('too many')) {
            throw TooManyRequestsException();
          }
          throw UnknownPhoneAuthException(e2.message);
        }
      }
      
      // Original attempt failed and no retry needed
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
