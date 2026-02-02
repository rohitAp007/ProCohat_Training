import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_bloc.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_event.dart';
import 'package:supabase_flutter_app/features/auth/login/bloc/login_state.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/bloc/phone_auth_bloc.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/bloc/phone_auth_event.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/bloc/phone_auth_state.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/ui/phone_otp_screen.dart';
import 'package:supabase_flutter_app/features/auth/signup/ui/signup_screen.dart';
import 'package:supabase_flutter_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/phone_auth/data/phone_auth_repository.dart';
import 'package:supabase_flutter_app/features/auth/services/oauth_service.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_list_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_event.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter_app/core/utils/app_logger.dart';
import 'package:country_code_picker/country_code_picker.dart';

class UnifiedLoginScreen extends StatelessWidget {
  const UnifiedLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LoginBloc(authRepository: AuthRepository()),
        ),
        BlocProvider(
          create: (context) => PhoneAuthBloc(repository: PhoneAuthRepository()),
        ),
      ],
      child: const _UnifiedLoginContent(),
    );
  }
}

class _UnifiedLoginContent extends StatefulWidget {
  const _UnifiedLoginContent({Key? key}) : super(key: key);

  @override
  State<_UnifiedLoginContent> createState() => _UnifiedLoginContentState();
}

class _UnifiedLoginContentState extends State<_UnifiedLoginContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = '+91';
  bool _isEmailMethod = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() {
    AppLogger.debug('Email login attempted', tag: 'AUTH');
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppLogger.warning('Login validation failed: empty credentials', tag: 'AUTH');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    AppLogger.info('Dispatching login event', tag: 'AUTH');
    context.read<LoginBloc>().add(
      const LoginSubmitted(),
    );
  }

  void _handlePhoneLogin() {
    AppLogger.debug('Phone login attempted with country code: $_countryCode', tag: 'AUTH');
    
    final phoneNumber = _phoneController.text.trim();
    // Remove any spaces, dashes, or special characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.isEmpty) {
      AppLogger.warning('Phone validation failed: empty number', tag: 'AUTH');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    // Accept 10-15 digits (flexible for international numbers and test numbers)
    if (cleanNumber.length < 10 || cleanNumber.length > 15) {
      AppLogger.warning('Phone validation failed: Invalid length (${cleanNumber.length} digits)', tag: 'AUTH');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number (10-15 digits)\nYou entered: $cleanNumber'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    AppLogger.info('Dispatching phone OTP send event for: $_countryCode$cleanNumber', tag: 'AUTH');
    
    // Send ONLY the clean number (without country code)
    // The PhoneOTPSendRequested event automatically combines countryCode + phoneNumber
    context.read<PhoneAuthBloc>().add(
      PhoneOTPSendRequested(
        phoneNumber: cleanNumber, // Just the digits, no country code
        countryCode: _countryCode,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    AppLogger.info('Google Sign-In initiated', tag: 'AUTH');
    
    setState(() => _isGoogleLoading = true);
    
    try {
      final oauthService = OAuthService();
      final authResponse = await oauthService.signInWithGoogle();
      
      if (authResponse == null || authResponse.user == null) {
        throw Exception('Google Sign-In failed - null response');
      }

      AppLogger.info('Google Sign-In successful for user: ${authResponse.user!.email}', tag: 'AUTH');
      
      if (!mounted) {
        AppLogger.warning('Widget unmounted after Google Sign-In, skipping navigation', tag: 'AUTH');
        return;
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => ProfileBloc(
              repository: ProfileRepository(),
            )..add(const ProfilesLoadAllRequested()),
            child: const ChatListScreen(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Google Sign-In failed', error: e, stackTrace: stackTrace, tag: 'AUTH');
      
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
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => ProfileBloc(
                      repository: ProfileRepository(),
                    )..add(const ProfilesLoadAllRequested()),
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
        BlocListener<PhoneAuthBloc, PhoneAuthState>(
          listener: (context, state) {
            if (state is PhoneAuthOTPSent) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<PhoneAuthBloc>(),
                    child: PhoneOTPScreen(
                      phoneNumber: '$_countryCode${_phoneController.text.trim()}',
                      verificationId: '',
                    ),
                  ),
                ),
              );
            } else if (state is PhoneAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
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
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ProCohat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure messaging with real-time features',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildMethodToggle(),
                  const SizedBox(height: 24),
                  if (_isEmailMethod) _buildEmailForm() else _buildPhoneForm(),
                  const SizedBox(height: 32),
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
                  _buildGoogleSignInButton(),
                  const SizedBox(height: 32),
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
                  color: _isEmailMethod ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isEmailMethod ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
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
                  color: !_isEmailMethod ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isEmailMethod ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            // Update LoginBloc state when email changes
            context.read<LoginBloc>().add(LoginEmailChanged(value));
          },
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          onChanged: (value) {
            // Update LoginBloc state when password changes
            context.read<LoginBloc>().add(LoginPasswordChanged(value));
          },
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state is LoginInProgress ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
              ),
              child: state is LoginInProgress
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CountryCodePicker(
              onChanged: (country) {
                setState(() {
                  _countryCode = country.dialCode!;
                });
              },
              initialSelection: 'IN',
              favorite: const ['+91', 'IN'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: (state is PhoneAuthSendingOTP || state is PhoneAuthVerifying) ? null : _handlePhoneLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
              ),
              child: (state is PhoneAuthSendingOTP || state is PhoneAuthVerifying)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
      icon: _isGoogleLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Image.asset(
              'assets/images/google_logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.login, color: Colors.red);
              },
            ),
      label: Text(
        _isGoogleLoading ? 'Signing in...' : 'Sign in with Google',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }
}
