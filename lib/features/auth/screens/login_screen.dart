import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/provider/auth_provider.dart';
import 'package:weibao/shared/theme/theme_constants.dart';
import 'package:weibao/shared/utils/responsive_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneNumberController = TextEditingController();
  Country selectedCountry = Country(
    phoneCode: '254',
    countryCode: 'KE',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Kenya',
    example: 'Kenya',
    displayName: 'Kenya',
    displayNameNoCountryCode: 'KE',
    e164Key: '',
  );

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Form validation
  bool get isPhoneNumberValid => 
    _phoneNumberController.text.isNotEmpty && 
    (_phoneNumberController.text.startsWith('0') && _phoneNumberController.text.length == 10) ||
    (!_phoneNumberController.text.startsWith('0') && _phoneNumberController.text.length == 9);

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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Format phone number with country code
  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '+${selectedCountry.phoneCode}${phoneNumber.substring(1)}';
    }
    return '+${selectedCountry.phoneCode}$phoneNumber';
  }

  // Sign in with phone number
  void signInWithPhoneNumber() {
    final authNotifier = ref.read(authProvider.notifier);
    final formattedNumber = formatPhoneNumber(_phoneNumberController.text);
    
    authNotifier.signInWithPhoneNumber(
      phoneNumber: formattedNumber,
      context: context,
      onCodeSent: (verificationId) {
        // Navigate to OTP verification screen using GoRouter
        context.push(
          Constants.otpScreen,
          extra: {
            Constants.verificationId: verificationId,
            Constants.phoneNumber: formattedNumber,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.06),
                    
                    // App logo
                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Wei',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(44),
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Bao',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(44),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.1),
                    
                    // Phone input title
                    Text(
                      'Enter your phone number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'We\'ll send you a verification code',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Phone input field
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.surfaceVariant,
                        border: Border.all(
                          color: isPhoneNumberValid
                              ? AppColors.primaryGreen.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Country code selector
                          InkWell(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: AppColors.surface,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  searchTextStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  inputDecoration: InputDecoration(
                                    labelText: 'Search',
                                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  bottomSheetHeight: size.height * 0.75,
                                ),
                                onSelect: (Country country) {
                                  setState(() {
                                    selectedCountry = country;
                                  });
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    selectedCountry.flagEmoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${selectedCountry.phoneCode}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Phone number field
                          Expanded(
                            child: TextFormField(
                              controller: _phoneNumberController,
                              maxLength: 10,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '0XXXXXXXXX',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: isPhoneNumberValid
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: AppColors.primaryGreen,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        'Format: 0XXXXXXXXX or XXXXXXXXX',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.08),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isPhoneNumberValid
                            ? () => signInWithPhoneNumber()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.06),
                    
                    // Privacy text
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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