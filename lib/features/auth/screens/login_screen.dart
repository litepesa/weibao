import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/controller/auth_controller.dart';
import 'package:weibao/routes/app_router.dart';
import 'package:weibao/shared/utils/global_methods.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  Country _selectedCountry = Country(
    phoneCode: '254',
    countryCode: 'KE',
    name: 'Kenya',
    e164Sc: 0,
    geographic: true,
    level: 1,
    example: 'Kenya',
    displayName: 'Kenya',
    displayNameNoCountryCode: 'KE',
    e164Key: '',
  );
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animation controller
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    
    // Start animation and focus phone field after layout completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _phoneFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _isValidPhone {
    final phone = _phoneController.text;
    return (phone.startsWith('0') && phone.length == 10) || 
           (!phone.startsWith('0') && phone.length == 9);
  }

  String _formatPhone() {
    final phone = _phoneController.text;
    return '+${_selectedCountry.phoneCode}${phone.startsWith('0') ? phone.substring(1) : phone}';
  }

  void _submitPhone() {
    if (!_isValidPhone) {
      // Provide haptic feedback when invalid
      HapticFeedback.lightImpact();
      return;
    }
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    setState(() => _isLoading = true);
    final formattedPhone = _formatPhone();
    
    ref.read(authControllerProvider.notifier).signInWithPhone(
      phoneNumber: formattedPhone,
      onError: (error) {
        setState(() => _isLoading = false);
        showSnackBar(context, error);
      },
      onCodeSent: (verificationId, phoneNumber) {
        setState(() => _isLoading = false);
        
        // Success feedback
        HapticFeedback.mediumImpact();
        
        AppRouter.navigateTo(
          context, 
          Constants.otpScreen,
          arguments: {
            Constants.verificationId: verificationId,
            Constants.phoneNumber: phoneNumber,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style to match the app's background color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF7F7F7),
      systemNavigationBarColor: Color(0xFFF7F7F7),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final isKeyboardOpen = viewInsets.bottom > 0;
    final isSmallScreen = size.width < 375 || size.height < 700;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Color(0xFFF7F7F7),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          // Extend body behind system UI
          extendBodyBehindAppBar: true,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isSmallScreen ? 20 : 32,
                    right: isSmallScreen ? 20 : 32,
                    // Add padding for status bar
                    top: viewPadding.top + (isSmallScreen ? 12 : 20),
                    // Add padding for navigation bar or keyboard
                    bottom: isKeyboardOpen 
                      ? viewInsets.bottom + (isSmallScreen ? 12 : 20)
                      : viewPadding.bottom + (isSmallScreen ? 12 : 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Section - smaller when keyboard is open
                      SizedBox(height: isKeyboardOpen ? size.height * 0.04 : size.height * 0.08),
                      Center(
                        child: Hero(
                          tag: 'logo',
                          child: Material(
                            color: Colors.transparent,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Wei',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 36 : 44,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bao',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 36 : 44,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF07C160),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isKeyboardOpen ? size.height * 0.05 : size.height * 0.1),

                      // Phone Input Section
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animController,
                          curve: const Interval(0.3, 1.0),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter your phone number',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF181818),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Phone input container with animation
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.96, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isValidPhone
                                              ? const Color(0xFF07C160).withOpacity(0.1)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: _isValidPhone 
                                            ? const Color(0xFF07C160).withOpacity(0.3)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Country Picker
                                        InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            showCountryPicker(
                                              context: context,
                                              showPhoneCode: true,
                                              countryListTheme: CountryListThemeData(
                                                backgroundColor: Colors.white,
                                                textStyle: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                                inputDecoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: const Color(0xFFF2F2F2),
                                                  hintText: 'Search country',
                                                  hintStyle: GoogleFonts.poppins(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                  ),
                                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    vertical: 12, 
                                                    horizontal: 16
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(24),
                                                  topRight: Radius.circular(24),
                                                ),
                                                bottomSheetHeight: size.height * 0.7,
                                              ),
                                              onSelect: (Country country) {
                                                setState(() => _selectedCountry = country);
                                                _phoneController.clear();
                                              },
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isSmallScreen ? 12 : 16,
                                              vertical: 18,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(13),
                                                bottomLeft: Radius.circular(13),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _selectedCountry.flagEmoji,
                                                  style: const TextStyle(fontSize: 20),
                                                ),
                                                SizedBox(width: isSmallScreen ? 4 : 8),
                                                Text(
                                                  '+${_selectedCountry.phoneCode}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF181818),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  size: 18,
                                                  color: Color(0xFF888888),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Phone Input
                                        Expanded(
                                          child: TextFormField(
                                            controller: _phoneController,
                                            focusNode: _phoneFocusNode,
                                            keyboardType: TextInputType.phone,
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) {
                                              if (_isValidPhone) _submitPhone();
                                            },
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            maxLength: 10,
                                            onChanged: (_) => setState(() {}),
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF181818),
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              hintText: '0XXXXXXXXX',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: const Color(0xFFB2B2B2),
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16, 
                                                vertical: 18
                                              ),
                                              suffixIcon: _isValidPhone
                                                ? TweenAnimationBuilder<double>(
                                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                                    duration: const Duration(milliseconds: 300),
                                                    builder: (context, value, child) {
                                                      return Opacity(
                                                        opacity: value,
                                                        child: const Padding(
                                                          padding: EdgeInsets.only(right: 12.0),
                                                          child: Icon(
                                                            Icons.check_circle,
                                                            color: Color(0xFF07C160),
                                                            size: 20,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                'Format: 0XXXXXXXXX or XXXXXXXXX',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFB2B2B2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Button & Terms
                      SizedBox(height: isKeyboardOpen ? size.height * 0.05 : size.height * 0.08),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animController,
                          curve: const Interval(0.5, 1.0),
                        )),
                        child: Column(
                          children: [
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _isValidPhone && !_isLoading
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF07C160).withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                                ),
                                child: ElevatedButton(
                                  onPressed: _isValidPhone && !_isLoading ? _submitPhone : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF07C160),
                                    disabledBackgroundColor: const Color(0xFF07C160).withOpacity(0.6),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 14 : 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Continue',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isKeyboardOpen ? 16 : size.height * 0.04),

                            // Terms Text
                            Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFFB2B2B2),
                                    height: 1.5,
                                  ),
                                  children: const [
                                    TextSpan(text: 'By continuing, you agree to our '),
                                    TextSpan(
                                      text: 'Terms',
                                      style: TextStyle(
                                        color: Color(0xFF07C160),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFF07C160),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isKeyboardOpen ? 16 : size.height * 0.04),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}