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
  /// Handles both formats:
  /// - With + prefix: +917666086414 (Twilio production)
  /// - Without + prefix: 917666086414 (Supabase test OTP format)
  Future<void> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      print('📞 Sending OTP to: $phoneNumber');
      
      // Ensure phone number has country code
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+91$phoneNumber';
      }
      
      print('📱 Trying with + prefix: $formattedPhone');
      
      try {
        // FIRST: Try with + prefix (for Twilio production)
        await _supabaseClient.auth.signInWithOtp(
          phone: formattedPhone,
        );
        print('✅ OTP sent successfully');
        return;
        
      } on AuthException catch (e) {
        // If invalid, retry without + prefix for Supabase test OTPs
        if (e.message.toLowerCase().contains('invalid') && 
            formattedPhone.startsWith('+')) {
          
          // Remove ONLY the + sign, keep country code
          String withoutPlus = formattedPhone.substring(1);
          print('🔄 Retrying without + prefix: $withoutPlus');
          
          // SECOND: Try without + (for Supabase test format: 917666086414=4685)
          await _supabaseClient.auth.signInWithOtp(
            phone: withoutPlus,
          );
          print('✅ OTP sent successfully (test format)');
          return;
        }
        rethrow;
      }
      
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      
      if (e.message.toLowerCase().contains('invalid')) {
        throw InvalidPhoneNumberException();
      } else if (e.message.toLowerCase().contains('too many')) {
        throw TooManyRequestsException();
      }
      throw UnknownPhoneAuthException(e.message);
      
    } catch (e) {
      print('❌ Unknown error: $e');
      
      if (e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      throw UnknownPhoneAuthException(e.toString());
    }
  }

  /// Verify OTP code
  /// 
  /// Returns Supabase User if successful
  /// Uses same E.164 format as sendOTP
  Future<User> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      print('🔍 Verifying OTP for: $phoneNumber');
      
      // Ensure phone number has country code (same as sendOTP)
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+91$phoneNumber';
      }
      
      print('📱 Formatted phone: $formattedPhone');
      
      final response = await _supabaseClient.auth.verifyOTP(
        phone: formattedPhone,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.user == null) {
        throw UnknownPhoneAuthException('Failed to verify OTP');
      }

      print('✅ OTP verified successfully');
      return response.user!;
      
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('expired')) {
        throw InvalidVerificationCodeException();
      } else if (e.message.toLowerCase().contains('too many')) {
        throw TooManyRequestsException();
      }
      throw UnknownPhoneAuthException(e.message);
      
    } catch (e) {
      print('❌ Unknown error: $e');
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
