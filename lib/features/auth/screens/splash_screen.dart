import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/provider/auth_provider.dart';
import 'package:weibao/shared/theme/theme_constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _authCheckComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
    
    // Check authentication status after animation is complete
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Check if user is already authenticated
  void _checkAuthStatus() async {
    if (_authCheckComplete) return; // Prevent multiple checks
    
    _authCheckComplete = true; // Mark as complete to prevent multiple navigations
    
    try {
      final authNotifier = ref.read(authProvider.notifier);
      
      // Make sure to print detailed debug info
      debugPrint('Starting authentication check...');
      
      bool isAuthenticated = await authNotifier.checkAuthenticationState();
      
      debugPrint('Authentication check result: $isAuthenticated');
      debugPrint('User model: ${authNotifier.state.userModel != null ? 'exists' : 'null'}');
      
      if (mounted) {
        if (isAuthenticated && authNotifier.state.userModel != null) {
          debugPrint('User is authenticated with valid user data, navigating to home screen');
          
          // Navigate to home screen if authenticated and has user data
          context.go(Constants.homeScreen);
        } else {
          debugPrint('User is NOT authenticated or missing user data, navigating to landing screen');
          
          // Navigate to landing screen if not authenticated or missing user data
          context.go(Constants.landingScreen);
        }
      } else {
        debugPrint('Widget no longer mounted, skipping navigation');
      }
    } catch (e) {
      // Handle any errors during authentication check
      debugPrint('Error during authentication check: $e');
      
      if (mounted) {
        // Navigate to landing screen if there was an error
        context.go(Constants.landingScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_rounded,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                
                // App name
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Wei',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'Bao',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                    strokeWidth: 2.5,
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