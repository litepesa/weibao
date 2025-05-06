import 'package:flutter/material.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/screens/landing_screen.dart';
import 'package:weibao/features/auth/screens/login_screen.dart';
import 'package:weibao/features/auth/screens/otp_screen.dart';
import 'package:weibao/features/auth/screens/splash_screen.dart';
import 'package:weibao/features/auth/screens/user_information_screen.dart';
import 'package:weibao/main_screens/home_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Constants.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case Constants.landingScreen:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
        
      case Constants.loginScreen:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        
      case Constants.otpScreen:
        final args = settings.arguments as Map;
        return MaterialPageRoute(
          builder: (_) => const OTPScreen(),
          settings: settings,
        );
        
      case Constants.userInformationScreen:
        return MaterialPageRoute(builder: (_) => const UserInformationScreen());
        
      case Constants.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}