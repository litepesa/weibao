import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/provider/auth_provider.dart';
import 'package:weibao/shared/theme/theme_constants.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Resend timer
  bool _resendEnabled = false;
  int _resendTimer = 60;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
    _startResendTimer();
  }
  
  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Start timer for OTP resend
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startResendTimer();
          } else {
            _resendEnabled = true;
          }
        });
      }
    });
  }
  
  // Resend OTP code
  void _resendOTP(String phoneNumber) {
    // Reset the timer
    setState(() {
      _resendEnabled = false;
      _resendTimer = 60;
      _otpController.clear();
    });
    
    _startResendTimer();
    
    final authNotifier = ref.read(authProvider.notifier);
    
    // Resend verification code
    authNotifier.signInWithPhoneNumber(
      phoneNumber: phoneNumber,
      context: context,
      onCodeSent: (String verificationId) {
        // Update the verification ID in the arguments
        if (mounted) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          args[Constants.verificationId] = verificationId;
        }
        
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
  
  // Verify OTP
  void _verifyOTP(String verificationId, String otp) {
    final authNotifier = ref.read(authProvider.notifier);
    
    authNotifier.verifyOTPCode(
      verificationId: verificationId,
      otpCode: otp,
      context: context,
      onSuccess: () async {
        // Check if user exists in Firestore
        bool userExists = await authNotifier.checkUserExists();
        
        if (userExists) {
          // User exists, get user data and navigate to home
          await authNotifier.getUserDataFromFireStore();
          
          // Double check we actually got user data
          if (authNotifier.state.userModel == null) {
            debugPrint('User exists in Firestore but failed to fetch user data');
            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to load your profile. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          await authNotifier.saveUserDataToSharedPreferences();
          
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Constants.homeScreen,
              (route) => false,
            );
          }
        } else {
          // User doesn't exist, navigate to user info screen
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              Constants.userInformationScreen,
            );
          }
        }
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Get arguments from route
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final verificationId = args[Constants.verificationId] as String;
    final phoneNumber = args[Constants.phoneNumber] as String;
    
    final authState = ref.watch(authProvider);
    
    // Define the pin theme
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 64,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
    );
    
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primaryGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
    
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.surfaceVariant.withOpacity(0.8),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1),
      ),
    );
    
    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.error, width: 2),
      ),
    );
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Lock icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Title
                    const Text(
                      'Verification',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Enter the 6-digit code sent to your phone number',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Phone number display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          phoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // PIN input
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      focusNode: _focusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorPinTheme,
                      pinAnimationType: PinAnimationType.scale,
                      closeKeyboardWhenCompleted: true,
                      onCompleted: (pin) {
                        _verifyOTP(verificationId, pin);
                      },
                    ),
                    const SizedBox(height: 40),
                    
                    // Loading or success indicator
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: authState.isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            )
                          : authState.isSuccessful
                              ? Container(
                                  key: const ValueKey('success'),
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    shape: BoxShape.circle
                                    ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 36,
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 40),
                    
                    // Resend code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code?",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Resend button or timer
                        _resendEnabled
                            ? TextButton(
                                onPressed: () => _resendOTP(phoneNumber),
                                child: Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              )
                            : Text(
                                'Resend in ${_resendTimer}s',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}