/// ============================================================================
/// OAUTH SERVICE - GOOGLE & APPLE SIGN-IN
/// ============================================================================

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class OAuthService {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  OAuthService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client,
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google tokens');
      }

      // Step 3: Sign in to Supabase with Google tokens
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      return response;
    } catch (e) {
      await _googleSignIn.signOut(); // Clean up on error
      rethrow;
    }
  }

  /// Sign in with Apple (iOS only)
  Future<AuthResponse> signInWithApple() async {
    try {
      // Check iOS platform
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw Exception('Apple sign-in is only available on iOS/macOS');
      }

      // Step 1: Trigger Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      // Step 2: Sign in to Supabase with Apple token
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}
