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

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
  
  // Add local loading state that we control
  bool _isSigningIn = false;

  bool get isPhoneNumberValid {
    final phoneNumber = _phoneNumberController.text;
    return (phoneNumber.startsWith('0') && phoneNumber.length == 10) ||
        (!phoneNumber.startsWith('0') && phoneNumber.length == 9);
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '+${selectedCountry.phoneCode}${phoneNumber.substring(1)}';
    }
    return '+${selectedCountry.phoneCode}$phoneNumber';
  }

  void _signInWithPhoneNumber() {
    if (!isPhoneNumberValid) return;
    
    // Set our local loading state to true
    setState(() {
      _isSigningIn = true;
    });
    
    final formattedPhoneNumber = _formatPhoneNumber(_phoneNumberController.text);
    
    debugPrint("Attempting to sign in with: $formattedPhoneNumber");
    
    ref.read(authControllerProvider.notifier).signInWithPhone(
      phoneNumber: formattedPhoneNumber,
      onError: (error) {
        // Reset our local loading state on error
        setState(() {
          _isSigningIn = false;
        });
        debugPrint("Sign in error: $error");
        showSnackBar(context, error);
      },
      onCodeSent: (verificationId, phoneNumber) {
        // Reset our local loading state on success
        setState(() {
          _isSigningIn = false;
        });
        debugPrint("Code sent successfully, navigating to OTP screen");
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
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // We're not using the auth state's loading indicator anymore
    // final authState = ref.watch(authControllerProvider);
    // final isLoading = authState.isLoading;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.15),

                // App logo
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Wei',
                          style: GoogleFonts.poppins(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Bao',
                          style: GoogleFonts.poppins(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF07C160),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.12),

                Text(
                  'Enter your phone number',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181818),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone number input
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isPhoneNumberValid
                            ? const Color(0xFF07C160).withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isPhoneNumberValid
                          ? const Color(0xFF07C160).withOpacity(0.3)
                          : Colors.transparent,
                      width: 1,
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
                                prefixIcon:
                                    const Icon(Icons.search, color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              bottomSheetHeight:
                                  MediaQuery.of(context).size.height * 0.75,
                            ),
                            onSelect: (Country country) {
                              setState(() {
                                selectedCountry = country;
                                _phoneNumberController.clear();
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.grey.shade100, width: 1),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
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
                      
                      // Phone number text field
                      Expanded(
                        child: TextFormField(
                          controller: _phoneNumberController,
                          maxLength: 10,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181818),
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
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFFB2B2B2),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            suffixIcon: isPhoneNumberValid
                                ? const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF07C160),
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
                  padding: const EdgeInsets.only(top: 10.0, left: 4.0),
                  child: Text(
                    'Format: 0XXXXXXXXX or XXXXXXXXX',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFB2B2B2),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.08),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isPhoneNumberValid
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF07C160),
                                Color(0xFF07C160),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isPhoneNumberValid
                          ? null
                          : const Color(0xFF07C160).withOpacity(0.6),
                    ),
                    child: ElevatedButton(
                      // Only enable button if phone number is valid and we're not already signing in
                      onPressed: isPhoneNumberValid && !_isSigningIn
                          ? _signInWithPhoneNumber
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      // Use our local loading state instead of the auth state
                      child: _isSigningIn
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

                SizedBox(height: size.height * 0.06),

                // Terms and privacy
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}