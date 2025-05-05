import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/controller/auth_controller.dart';
import 'package:weibao/routes/app_router.dart';
import 'package:weibao/shared/utils/assets_manager.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authController = ref.read(authControllerProvider.notifier);
    final isAuthenticated = await authController.checkAuth();

    if (isAuthenticated) {
      if (mounted) {
        AppRouter.navigateToReplacement(context, Constants.homeScreen);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    AppRouter.navigateToReplacement(context, Constants.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Color scheme
    const weibaoPrimaryColor = Color(0xFF07C160);
    const weibaoBackgroundDark = Color(0xFF0F0F0F);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: weibaoBackgroundDark,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(weibaoPrimaryColor),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: weibaoBackgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // App logo
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Green accent line
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: weibaoPrimaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // WeiBao logo text
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Wei',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        TextSpan(
                          text: 'Bao',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w700,
                            color: weibaoPrimaryColor,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tagline
            const Text(
              "Private messaging, reimagined",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            
            const Spacer(flex: 1),
            
            // Animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: size.height * 0.4,
                width: size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Lottie.asset(
                  AssetsManager.chatBubble,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => _navigateToLogin(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: weibaoPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(size.width, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Legal text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'By continuing, you accept our Terms & Privacy Policy',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}