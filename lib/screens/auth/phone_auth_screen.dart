import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/screens/auth/profile_setup_screen.dart';
import 'package:weibao/config/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

final phoneAuthStateProvider = StateProvider<PhoneAuthState>((ref) {
  return PhoneAuthState.phoneInput;
});

final phoneNumberProvider = StateProvider<String>((ref) {
  return '';
});

final verificationIdProvider = StateProvider<String>((ref) {
  return '';
});

enum PhoneAuthState {
  phoneInput,
  otpInput,
  loading,
}

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _completePhoneNumber = '';
  String _errorMessage = '';
  bool _agreeToTerms = false;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'You must agree to the Terms & Privacy Policy to continue';
      });
      return;
    }
    
    setState(() {
      _errorMessage = '';
    });
    
    ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.loading;
    
    final authService = ref.read(authServiceProvider);
    
    try {
      await authService.sendPhoneVerification(
        phoneNumber: _completePhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await authService.verifyPhoneCode(
              verificationId: ref.read(verificationIdProvider),
              smsCode: credential.smsCode ?? '',
            );
          } catch (e) {
            setState(() {
              _errorMessage = e.toString();
              ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.phoneInput;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = authService.getAuthErrorMessage(e.code);
            ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.phoneInput;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          ref.read(verificationIdProvider.notifier).state = verificationId;
          ref.read(phoneNumberProvider.notifier).state = _completePhoneNumber;
          ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.otpInput;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout, usually after 60 seconds
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.phoneInput;
      });
    }
  }
  
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }
    
    setState(() {
      _errorMessage = '';
    });
    
    ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.loading;
    
    final authService = ref.read(authServiceProvider);
    
    try {
      await authService.verifyPhoneCode(
        verificationId: ref.read(verificationIdProvider),
        smsCode: _otpController.text,
      );
      
      // Navigate to profile setup screen after successful verification
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfileSetupScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.otpInput;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(phoneAuthStateProvider);
    
    return Scaffold(
      appBar: authState == PhoneAuthState.phoneInput
          ? AppBar(
              title: const Text('Sign in'),
              centerTitle: true,
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.phoneInput;
                },
              ),
              title: const Text('Verification'),
              centerTitle: true,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or brand image
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Text(
                      'Weibao',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                if (authState == PhoneAuthState.phoneInput) ...[
                  const Text(
                    'Enter your phone number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'ll send you a verification code to confirm your identity',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Phone number input
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    initialCountryCode: 'KE', // Kenya as default
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                    },
                  ),
                  
                  // Terms and conditions checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(
                                text: 'I agree to the ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigate to Terms of Service
                                  },
                              ),
                              const TextSpan(
                                text: ' and ',
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigate to Privacy Policy
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (authState == PhoneAuthState.otpInput) ...[
                  const Text(
                    'Enter verification code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ve sent a 6-digit code to ${ref.watch(phoneNumberProvider)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // OTP input
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  
                  // Resend code option
                  TextButton(
                    onPressed: () {
                      // Reset state and resend code
                      ref.read(phoneAuthStateProvider.notifier).state = PhoneAuthState.phoneInput;
                    },
                    child: const Text('Didn\'t receive a code? Resend'),
                  ),
                ],
                
                // Error message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Action button
                if (authState == PhoneAuthState.loading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  ElevatedButton(
                    onPressed: authState == PhoneAuthState.phoneInput
                        ? _verifyPhoneNumber
                        : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      authState == PhoneAuthState.phoneInput
                          ? 'Continue'
                          : 'Verify',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}