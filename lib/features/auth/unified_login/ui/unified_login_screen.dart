import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_bloc.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_event.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_state.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/bloc/phone_auth_bloc.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/bloc/phone_auth_event.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/bloc/phone_auth_state.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/data/phone_auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/ui/phone_otp_screen.dart';
import 'package:supabase_flutter_app/features/auth/services/oauth_service.dart';
import 'package:supabase_flutter_app/features/auth/signup/ui/signup_screen.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_list_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_event.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:country_code_picker/country_code_picker.dart';

/// Unified Login Screen
///
/// Provides three authentication methods:
/// 1. Email/Password
/// 2. Phone Number + OTP
/// 3. Google Sign-In
///
/// This is a WRAPPER that provides BLoCs to child widgets
class UnifiedLoginScreen extends StatelessWidget {
  const UnifiedLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide BLoCs at top level
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LoginBloc(authRepository: AuthRepository()),
        ),
        BlocProvider(
          create: (context) => PhoneAuthBloc(repository: PhoneAuthRepository()),
        ),
      ],
      // Actual UI is in separate widget below
      child: const _UnifiedLoginContent(),
    );
  }
}

/// Content widget with proper BLoC access
/// This widget is BELOW the providers, so context.read<T>() works!
class _UnifiedLoginContent extends StatefulWidget {
  const _UnifiedLoginContent();

  @override
  State<_UnifiedLoginContent> createState() => _UnifiedLoginContentState();
}

class _UnifiedLoginContentState extends State<_UnifiedLoginContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oauthService = OAuthService();
  bool _obscurePassword = true;
  bool _isEmailMethod = true; // true = email, false = phone
  String _countryCode = '+91';
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() {
    print('ðŸ” [DEBUG] Email login button clicked');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    print('ðŸ“§ Email: $email');
    print('ðŸ”‘ Password length: ${password.length}');

    if (email.isEmpty || password.isEmpty) {
      print('âŒ Validation failed: Empty fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    // âœ… NOW THIS WORKS! Context is below MultiBlocProvider
    print('âœ… Dispatching LoginEmailChanged event');
    context.read<LoginBloc>().add(LoginEmailChanged(email));
    print('âœ… Dispatching LoginPasswordChanged event');
    context.read<LoginBloc>().add(LoginPasswordChanged(password));

    // Submit login
    print('âœ… Dispatching LoginSubmitted event');
    context.read<LoginBloc>().add(const LoginSubmitted());
    print('ðŸ”„ Waiting for BLoC response...');
  }

  void _handlePhoneLogin() {
    print('ðŸ“± [DEBUG] Send OTP button clicked');
    final phoneNumber = _phoneController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    print('ðŸ“ž Phone number (cleaned): $phoneNumber');
    print('ðŸŒ Country code: $_countryCode');

    if (phoneNumber.isEmpty) {
      print('âŒ Validation failed: Empty phone number');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    if (phoneNumber.length < 10 || phoneNumber.length > 15) {
      print('âŒ Validation failed: Invalid length (${phoneNumber.length})');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    print('âœ… Validation passed! Dispatching PhoneOTPSendRequested');
    print('ðŸ“² Sending OTP to: $_countryCode$phoneNumber');

    // âœ… NOW THIS WORKS! Context is below MultiBlocProvider
    context.read<PhoneAuthBloc>().add(
      PhoneOTPSendRequested(
        phoneNumber: phoneNumber,
        countryCode: _countryCode,
      ),
    );
    print('ðŸ”„ Waiting for phone auth BLoC response...');
  }

  Future<void> _handleGoogleSignIn() async {
    print('ðŸ” [DEBUG] Google Sign-In button clicked');
    setState(() => _isGoogleLoading = true);

    try {
      print('ðŸ“² Calling OAuthService.signInWithGoogle()');
      print('â³ Waiting for Google account picker...');
      await _oauthService.signInWithGoogle();
      print('âœ… Google Sign-In successful!');

      if (!mounted) {
        print('âš ï¸ Widget unmounted, aborting navigation');
        return;
      }

      print('ðŸš€ Navigating to ChatListScreen...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) =>
                ProfileBloc(repository: ProfileRepository())
                  ..add(const ProfilesLoadAllRequested()),
            child: const ChatListScreen(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('âŒ Google Sign-In ERROR: $e');
      print('ðŸ“ Stack trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        print('ðŸ”„ Resetting loading state');
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // âœ… This context is NOW a child of MultiBlocProvider!
    return MultiBlocListener(
      listeners: [
        // Email Login Listener
        BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) =>
                        ProfileBloc(repository: ProfileRepository())
                          ..add(const ProfilesLoadAllRequested()),
                    child: const ChatListScreen(),
                  ),
                ),
              );
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Login failed')),
              );
            }
          },
        ),
        // Phone Auth Listener
        BlocListener<PhoneAuthBloc, PhoneAuthState>(
          listener: (context, state) {
            if (state is PhoneAuthOTPSent) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<PhoneAuthBloc>(),
                    child: PhoneOTPScreen(
                      phoneNumber:
                          '$_countryCode${_phoneController.text.trim()}',
                      verificationId: '', // Not needed for Supabase
                    ),
                  ),
                ),
              );
            } else if (state is PhoneAuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),

                  // App Name
                  const Text(
                    'ProCohat',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Secure messaging with real-time features',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),

                  // Method Toggle
                  _buildMethodToggle(),
                  const SizedBox(height: 24),

                  // Login Form (Email or Phone)
                  if (_isEmailMethod) _buildEmailForm() else _buildPhoneForm(),

                  const SizedBox(height: 32),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Google Sign-In Button
                  _buildGoogleSignInButton(),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildMethodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isEmailMethod = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isEmailMethod
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: _isEmailMethod ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: TextStyle(
                        color: _isEmailMethod ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isEmailMethod = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isEmailMethod
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: !_isEmailMethod ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Phone',
                      style: TextStyle(
                        color: !_isEmailMethod
                            ? Colors.white
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isLoading = state is LoginInProgress;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            ElevatedButton(
              onPressed: isLoading ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneForm() {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, state) {
        final isLoading = state is PhoneAuthSendingOTP;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Text
            Text(
              'Enter your phone number without country code',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Phone Number Field
            Row(
              children: [
                // Country Code Picker
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CountryCodePicker(
                    onChanged: (code) {
                      setState(() => _countryCode = code.dialCode!);
                    },
                    initialSelection: 'IN',
                    favorite: const ['+91', 'IN', '+1', 'US'],
                    showFlag: true,
                    showFlagDialog: true,
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 12),

                // Phone Number Input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '7666086414',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Send OTP Button
            ElevatedButton(
              onPressed: isLoading ? null : _handlePhoneLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      icon: _isGoogleLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.red),
      label: const Text(
        'Sign in with Google',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
