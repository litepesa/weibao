import 'package:flutter/material.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/screens/landing_screen.dart';
import 'package:weibao/features/auth/screens/login_screen.dart';
import 'package:weibao/features/auth/screens/otp_screen.dart';
import 'package:weibao/features/auth/screens/user_information_screen.dart';
import 'package:weibao/main_screens/home_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case Constants.landingScreen:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
        
      case Constants.loginScreen:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        
      case Constants.otpScreen:
        if (args is Map) {
          return MaterialPageRoute(builder: (_) => OtpScreen(arguments: args));
        }
        return _errorRoute('OTP Screen requires verification ID and phone number');
        
      case Constants.userInformationScreen:
        return MaterialPageRoute(builder: (_) => const UserInformationScreen());
        
      case Constants.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      default:
        return _errorRoute('Route not found');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $message')),
      ),
    );
  }

  // Navigation helper methods
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateToReplacement(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      routeName, 
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}