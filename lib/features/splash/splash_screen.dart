import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter_app/core/auth/auth_state_manager.dart';
import 'package:supabase_flutter_app/features/auth/login/ui/login_screen.dart';
import 'package:supabase_flutter_app/features/onboarding/onboarding_screen.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_list_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_event.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter_app/core/animations/fade_in_widget.dart';

/// Splash screen with auth check
/// 
/// Displays app branding while checking authentication state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthStateManager _authStateManager = AuthStateManager();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for minimum 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // STEP 1: Check if onboarding completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    if (!onboardingCompleted) {
      // First time user → Onboarding
      _navigateToScreen(const OnboardingScreen());
      return;
    }

    // STEP 2: Check authentication state
    final isAuthenticated = _authStateManager.isAuthenticated;

// Navigate to appropriate screen with fade transition
    if (isAuthenticated) {
      // Logged in → ChatListScreen
      _navigateToScreen(
        BlocProvider(
          create: (context) => ProfileBloc(
            repository: ProfileRepository(),
          )..add(const ProfilesLoadAllRequested()),
          child: const ChatListScreen(),
        ),
      );
    } else {
      // Not logged in → LoginScreen
      _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _authStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon with fade-in
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: Icon(
                  Icons.shield_outlined,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // App Name with fade-in
              FadeInWidget(
                delay: const Duration(milliseconds: 300),
                child: const Text(
                  'ProCohat Training',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tagline with fade-in
              FadeInWidget(
                delay: const Duration(milliseconds: 500),
                child: Text(
                  'Flutter BLoC + Supabase',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator with fade-in
              FadeInWidget(
                delay: const Duration(milliseconds: 700),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 100),

              // Version number at bottom
              FadeInWidget(
                delay: const Duration(milliseconds: 900),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
