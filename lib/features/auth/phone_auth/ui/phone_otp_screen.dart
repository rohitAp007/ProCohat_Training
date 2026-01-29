/// ============================================================================
/// PHONE OTP VERIFICATION SCREEN - WhatsApp-Style
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter_app/features/chat/ui/chat_list_screen.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_repository.dart';
import '../bloc/phone_auth_bloc.dart';
import '../bloc/phone_auth_event.dart';
import '../bloc/phone_auth_state.dart';

class PhoneOTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneOTPScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<PhoneOTPScreen> createState() => _PhoneOTPScreenState();
}

class _PhoneOTPScreenState extends State<PhoneOTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify phone number'),
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
      ),
      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (context, state) {
          if (state is PhoneAuthSuccess) {
            // Navigate to chat list
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => ProfileBloc(repository: ProfileRepository()),
                  child: const ChatListScreen(),
                ),
              ),
              (route) => false,
            );
          } else if (state is PhoneAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PhoneAuthOTPSent && _isResending) {
            setState(() => _isResending = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New code sent!'),
                backgroundColor: Color(0xFF25D366),
              ),
            );
          }
        },
        child: BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
          builder: (context, state) {
            final isVerifying = state is PhoneAuthVerifying;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Info text
                  Text(
                    'We have sent an SMS with a code to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Phone number
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP input
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 45,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      activeColor: const Color(0xFF25D366),
                      inactiveColor: Colors.grey.shade300,
                      selectedColor: const Color(0xFF075E54),
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    onCompleted: (code) {
                      _verifyOTP(code);
                    },
                    onChanged: (value) {},
                  ),

                  const SizedBox(height: 24),

                  // Resend button
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: Text(
                      _isResending ? 'Resending...' : 'Didn\'t receive code? Resend',
                      style: TextStyle(
                        color: _isResending ? Colors.grey : const Color(0xFF075E54),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isVerifying ? null : () => _verifyOTP(_otpController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'VERIFY',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _verifyOTP(String code) {
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    context.read<PhoneAuthBloc>().add(
          PhoneOTPVerifyRequested(otpCode: code),
        );
  }

  void _resendOTP() {
    setState(() => _isResending = true);
    context.read<PhoneAuthBloc>().add(const PhoneOTPResendRequested());
  }
}
