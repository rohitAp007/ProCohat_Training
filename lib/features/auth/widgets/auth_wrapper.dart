import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/core/auth/auth_state_manager.dart';
import 'package:supabase_flutter_app/features/auth/unified_login/ui/unified_login_screen_clean.dart';
import 'package:supabase_flutter_app/features/auth/home/home_screen.dart';

/// Auth Wrapper - Automatically routes based on authentication state
/// 
/// This widget listens to the AuthStateManager and automatically
/// navigates to the appropriate screen based on the user's auth status
class AuthWrapper extends StatefulWidget {
  final AuthStateManager authStateManager;

  const AuthWrapper({
    super.key,
    required this.authStateManager,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state manager
    widget.authStateManager.initialize();
  }

  @override
  void dispose() {
    widget.authStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppAuthState>(
      stream: widget.authStateManager.authStateStream,
      initialData: const AuthLoading(),
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state is AuthLoading) {
          // Show loading screen while checking auth
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is Authenticated) {
          // User is logged in - show home screen
          // TODO: Check email verification (Day 2 next step)
          return const HomeScreen();
        }

        // User is not logged in - show unified login screen
        return const UnifiedLoginScreen();
      },
    );
  }
}
