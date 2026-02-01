/// ============================================================================
/// PHONE INPUT SCREEN - WhatsApp-Style Phone Authentication
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../bloc/phone_auth_bloc.dart';
import '../bloc/phone_auth_event.dart';
import '../bloc/phone_auth_state.dart';
import 'phone_otp_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+91'; // Default to India

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Enter your phone number'),
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
      ),
      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (context, state) {
          if (state is PhoneAuthOTPSent) {
            // Navigate to OTP screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PhoneAuthBloc>(),
                  child: PhoneOTPScreen(
                    phoneNumber: state.phoneNumber,
                    verificationId: state.verificationId,
                  ),
                ),
              ),
            );
          } else if (state is PhoneAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
          builder: (context, state) {
            final isLoading = state is PhoneAuthSendingOTP;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Info text
                  const Text(
                    'Enter your phone number without country code.\nExample: 9876543210',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Phone input with country code
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Country code picker
                        CountryCodePicker(
                          onChanged: (country) {
                            setState(() {
                              _countryCode = country.dialCode ?? '+91';
                            });
                          },
                          initialSelection: 'IN',
                          favorite: const ['+91', '+1'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                        ),
                        
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        
                        // Phone number input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '9876543210',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Helper text
                  Text(
                    'Carrier charges may apply',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Next button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'NEXT',
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

  void _sendOTP() {
    // Remove all non-digit characters
    final phoneNumber = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    // Validate phone number length (should be 10 digits for most countries)
    if (phoneNumber.length < 10 || phoneNumber.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number (10-15 digits)')),
      );
      return;
    }

    // Debug: Show formatted number
    final formattedNumber = '$_countryCode$phoneNumber';
    print('Sending OTP to: $formattedNumber');

    // Send OTP with properly formatted number
    context.read<PhoneAuthBloc>().add(
          PhoneOTPSendRequested(
            phoneNumber: phoneNumber,
            countryCode: _countryCode,
          ),
        );
  }
}
