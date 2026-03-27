import 'package:supabase_flutter/supabase_flutter.dart';
import 'phone_auth_exceptions.dart';
import 'phone_auth_repository.dart';

/// Custom OTP Repository using Supabase Edge Functions
/// 
/// This repository handles OTP generation and verification through
/// custom Supabase Edge Functions instead of external SMS providers.
/// 
/// Features:
/// - Serverless OTP generation
/// - Built-in rate limiting
/// - 5-minute OTP expiration
/// - Development mode (OTP in response)
/// - Production ready (integrate email/webhook)
class CustomOTPRepository extends PhoneAuthRepository {
  CustomOTPRepository({super.supabaseClient});

  final SupabaseClient _client = Supabase.instance.client;

  /// Send OTP to phone number
  /// 
  /// Calls the Edge Function to generate and store OTP.
  /// In development mode, OTP is returned in the response.
  /// 
  /// Throws:
  /// - [InvalidPhoneNumberException] if phone format is invalid
  /// - [TooManyRequestsException] if rate limit exceeded (3 per 15 min)
  /// - [UnknownPhoneAuthException] for other errors
  @override
  Future<void> sendOTP({required String phoneNumber}) async {
    try {
      print('📞 Calling generate-otp Edge Function for: $phoneNumber');
      
      final response = await _client.functions.invoke(
        'generate-otp',
        body: {'phone': phoneNumber},
      );

      print('📡 Response status: ${response.status}');

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Failed to send OTP';
        print('❌ Error response: $error');
        
        if (error.toString().contains('Too many')) {
          throw TooManyRequestsException();
        }
        throw InvalidPhoneNumberException();
      }

      final data = response.data as Map<String, dynamic>;
      print('✅ OTP generated successfully');
      
      // In development mode, OTP is returned in response
      if (data.containsKey('otp_dev')) {
        final otp = data['otp_dev'];
        print('🔐 DEV MODE - OTP: $otp');
        print('⏰ Expires in: ${data['expires_in']} seconds');
      } else {
        // Production mode - OTP sent via email/webhook
        print('📧 OTP sent (production mode)');
      }

    } on FunctionException catch (e) {
      print('❌ Function Exception: ${e.status} - ${e.details}');
      
      if (e.status == 429) {
        throw TooManyRequestsException();
      }
      throw UnknownPhoneAuthException('Failed to send OTP: ${e.details}');
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      
      if (e is PhoneAuthException) rethrow;
      
      if (e.toString().contains('429') || e.toString().contains('Too many')) {
        throw TooManyRequestsException();
      }
      throw UnknownPhoneAuthException(e.toString());
    }
  }

  /// Verify OTP code
  /// 
  /// Validates the OTP against the stored value in the database.
  /// Creates or retrieves user account and establishes session.
  /// 
  /// Throws:
  /// - [InvalidVerificationCodeException] if OTP is wrong or expired
  /// - [UnknownPhoneAuthException] for other errors
  @override
  Future<User> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      print('🔍 Calling verify-otp Edge Function');
      print('📱 Phone: $phoneNumber');
      print('🔐 OTP: $otpCode');
      
      final response = await _client.functions.invoke(
        'verify-otp',
        body: {
          'phone': phoneNumber,
          'otp': otpCode,
        },
      );

      print('📡 Response status: ${response.status}');

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Invalid OTP';
        print('❌ Verification failed: $error');
        throw InvalidVerificationCodeException();
      }

      final data = response.data as Map<String, dynamic>;
      print('✅ OTP verified successfully');
      print('👤 User ID: ${data['user_id']}');

      // Get current user after session is established
      final user = _client.auth.currentUser;
      if (user == null) {
        throw UnknownPhoneAuthException('User not authenticated after OTP verification');
      }

      return user;

    } on FunctionException catch (e) {
      print('❌ Function Exception: ${e.status} - ${e.details}');
      throw InvalidVerificationCodeException();
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      
      if (e is PhoneAuthException) rethrow;
      throw InvalidVerificationCodeException();
    }
  }

  // Inherited methods from PhoneAuthRepository:
  // - signOut()
  // - getCurrentUser()
  // - isLoggedIn
  // - authStateChanges()
}
