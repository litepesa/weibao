import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/controller/auth_controller.dart';
import 'package:weibao/routes/app_router.dart';
import 'package:weibao/shared/utils/global_methods.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> arguments;
  
  const OtpScreen({
    super.key,
    required this.arguments,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _otpCode;
  
  late String _verificationId;
  late String _phoneNumber;
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _resendEnabled = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initializeData();
    _startResendTimer();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _initializeData() {
    _verificationId = widget.arguments[Constants.verificationId] as String? ?? '';
    _phoneNumber = widget.arguments[Constants.phoneNumber] as String? ?? '';
    
    if (_verificationId.isEmpty || _phoneNumber.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showSnackBar(context, "Missing verification data. Please try again.");
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) AppRouter.pop(context);
          });
        }
      });
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _resendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyOtp(String otp) {
    if (_verificationId.isEmpty || _phoneNumber.isEmpty) {
      showSnackBar(context, "Missing verification data. Please try again.");
      return;
    }
    
    FocusScope.of(context).unfocus();
    
    setState(() => _isVerifying = true);
    
    ref.read(authControllerProvider.notifier).verifyOTP(
      verificationId: _verificationId,
      otp: otp,
      onComplete: (userExists) {
        if (!mounted) return;
        
        setState(() {
          _isVerifying = false;
          _isVerified = true;
        });
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            AppRouter.navigateAndRemoveUntil(
              context,
              userExists ? Constants.homeScreen : Constants.userInformationScreen,
            );
          }
        });
      },
    );
  }

  void _resendOtp() {
    if (!_resendEnabled || _phoneNumber.isEmpty) return;
    
    setState(() {
      _resendEnabled = false;
      _resendTimer = 60;
    });
    
    _startResendTimer();
    showSnackBar(context, 'OTP code is being resent');
    
    ref.read(authControllerProvider.notifier).signInWithPhone(
      phoneNumber: _phoneNumber,
      onError: (error) {
        if (mounted) showSnackBar(context, error);
      },
      onCodeSent: (newVerificationId, _) {
        if (mounted) {
          setState(() => _verificationId = newVerificationId);
          showSnackBar(context, 'New OTP code has been sent');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => AppRouter.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildVerificationIcon(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 12),
                _buildSubtitle(),
                const SizedBox(height: 8),
                _buildPhoneNumberDisplay(),
                const SizedBox(height: 36),
                _buildPinput(defaultPinTheme),
                const SizedBox(height: 36),
                _buildVerificationStatus(),
                const SizedBox(height: 32),
                _buildResendOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF07C160).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.lock_outline, size: 50, color: Color(0xFF07C160)),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Verification',
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Enter the 6-digit code sent to your phone',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildPhoneNumberDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _phoneNumber,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF07C160)),
          onPressed: () => AppRouter.pop(context),
          tooltip: 'Edit phone number',
        ),
      ],
    );
  }

  Widget _buildPinput(PinTheme defaultPinTheme) {
    return Pinput(
      length: 6,
      controller: _controller,
      focusNode: _focusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        height: 68,
        width: 64,
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: const Color(0xFF07C160), width: 2.0),
        ),
      ),
      submittedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
      ),
      errorPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: Colors.red, width: 2.0),
        ),
      ),
      pinAnimationType: PinAnimationType.fade,
      closeKeyboardWhenCompleted: true,
      onCompleted: _verifyOtp,
      enabled: !_isVerifying && !_isVerified,
    );
  }

  Widget _buildVerificationStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isVerifying
          ? const CircularProgressIndicator(color: Color(0xFF07C160))
          : _isVerified
              ? Container(
                  key: const ValueKey('success'),
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 30),
                )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildResendOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        _resendEnabled
            ? TextButton(
                onPressed: _resendOtp,
                child: Text(
                  'Resend Code',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF07C160),
                  ),
                ),
              )
            : Text(
                'Resend in ${_resendTimer}s',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
      ],
    );
  }
}