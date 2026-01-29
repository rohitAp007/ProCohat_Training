/// ============================================================================
/// ENHANCED LOGIN FORM - EMAIL + OAUTH
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../signup/ui/signup_screen.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import 'package:supabase_flutter_app/features/auth/services/oauth_service.dart';
import 'package:supabase_flutter_app/core/widgets/custom_snackbar.dart';
import 'dart:io' show Platform;

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _oauthService = OAuthService();
  bool _obscurePassword = true;
  bool _isOAuthLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginEmailChanged(_emailController.text.trim()),
          );
      context.read<LoginBloc>().add(
            LoginPasswordChanged(_passwordController.text),
          );
      context.read<LoginBloc>().add(
            const LoginSubmitted(),
          );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isOAuthLoading = true);
    try {
      await _oauthService.signInWithGoogle();
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Signed in with Google!');
        // Navigation handled by LoginBloc listener
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Google sign-in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isOAuthLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isOAuthLoading = true);
    try {
      await _oauthService.signInWithApple();
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Signed in with Apple!');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Apple sign-in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isOAuthLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isLoading = state is LoginInProgress || _isOAuthLoading;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo  
                const Icon(
                  Icons.chat_bubble,
                  size: 80,
                  color: Color(0xFF25D366),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075E54),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _handleEmailLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Login button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleEmailLogin,
                    child: isLoading && !_isOAuthLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // OAuth buttons
                Row(
                  children: [
                    // Google Sign-In
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        icon: _isOAuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Image.asset(
                                'assets/google_logo.png',
                                height: 24,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.login, size: 24),
                              ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Apple Sign-In (iOS only)
                    if (Platform.isIOS || Platform.isMacOS)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _handleAppleSignIn,
                          icon: const Icon(Icons.apple, size: 24),
                          label: const Text('Apple'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
