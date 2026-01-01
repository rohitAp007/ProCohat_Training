import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as gotrue;
import 'auth_exceptions.dart';

/// Authentication Repository - Reusable across projects
/// 
/// This repository handles all authentication-related business logic.
/// It separates Supabase operations from BLoC, making code:
/// - More testable (can mock this repository)
/// - Reusable (copy to any project)
/// - Maintainable (business logic in one place)
class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Sign in with email and password
  /// 
  /// Throws [InvalidCredentialsException] if credentials are wrong
  /// Throws [NetworkException] if no internet
  /// Throws [UnknownAuthException] for other errors
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw InvalidCredentialsException();
      }

      return response.user!;
    } on gotrue.AuthException catch (e) {
      // Handle Supabase auth errors
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('credentials')) {
        throw InvalidCredentialsException();
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        throw EmailNotConfirmedException();
      }
      throw UnknownAuthException(e.message);
    } catch (e) {
      // Handle network errors
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      throw UnknownAuthException(e.toString());
    }
  }

  /// Sign up with email and password
  /// 
  /// Throws [EmailAlreadyInUseException] if email exists
  /// Throws [WeakPasswordException] if password is weak
  /// Throws [NetworkException] if no internet
  /// Throws [UnknownAuthException] for other errors
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw UnknownAuthException('Failed to create account');
      }

      return response.user!;
    } on gotrue.AuthException catch (e) {
      // Handle Supabase auth errors
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        throw EmailAlreadyInUseException();
      } else if (e.message.toLowerCase().contains('password')) {
        throw WeakPasswordException();
      }
      throw UnknownAuthException(e.message);
    } catch (e) {
      // Handle network errors
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      throw UnknownAuthException(e.toString());
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      throw UnknownAuthException('Failed to sign out');
    }
  }

  /// Get current user if logged in
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn => _supabaseClient.auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<AuthState> authStateChanges() {
    return _supabaseClient.auth.onAuthStateChange;
  }

  /// Reset password - sends reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email.trim());
    } on gotrue.AuthException catch (e) {
      throw UnknownAuthException(e.message);
    } catch (e) {
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException();
      }
      throw UnknownAuthException(e.toString());
    }
  }
}
