import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App Authentication State
sealed class AppAuthState {
  const AppAuthState();
}

/// User is not authenticated
class Unauthenticated extends AppAuthState {
  const Unauthenticated();
}

/// User is authenticated
class Authenticated extends AppAuthState {
  final User user;
  final bool isEmailVerified;

  const Authenticated({
    required this.user,
    required this.isEmailVerified,
  });
}

/// Auth state is loading/checking
class AuthLoading extends AppAuthState {
  const AuthLoading();
}

/// Auth State Manager - Centralized authentication state management
/// 
/// Monitors Supabase auth state changes and provides a unified stream
class AuthStateManager {
  final SupabaseClient _supabaseClient;
  final StreamController<AppAuthState> _stateController;
  StreamSubscription<AuthState>? _authSubscription;

  AuthStateManager({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client,
        _stateController = StreamController<AppAuthState>.broadcast();

  /// Stream of authentication state changes
  Stream<AppAuthState> get authStateStream => _stateController.stream;

  /// Current authentication state
  AppAuthState get currentState {
    final session = _supabaseClient.auth.currentSession;
    if (session == null) {
      return const Unauthenticated();
    }

    final user = session.user;
    return Authenticated(
      user: user,
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _supabaseClient.auth.currentSession != null;

  /// Get current user
  User? get currentUser => _supabaseClient.auth.currentUser;

  /// Initialize and start listening to auth changes
  void initialize() {
    // Emit initial state
    _stateController.add(currentState);

    // Listen to Supabase auth state changes
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        final session = data.session;

        if (session == null) {
          // User logged out or session expired
          _stateController.add(const Unauthenticated());
        } else {
          // User logged in or session refreshed
          final user = session.user;
          _stateController.add(
            Authenticated(
              user: user,
              isEmailVerified: user.emailConfirmedAt != null,
            ),
          );
        }
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _stateController.close();
  }
}
