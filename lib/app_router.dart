import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weibao/features/auth/provider/auth_provider.dart';
import 'package:weibao/features/auth/screens/landing_screen.dart';
import 'package:weibao/features/auth/screens/login_screen.dart';
import 'package:weibao/features/auth/screens/otp_screen.dart';
import 'package:weibao/features/auth/screens/splash_screen.dart';
import 'package:weibao/features/auth/screens/user_information_screen.dart';
import 'package:weibao/main_screens/home_screen.dart';

// Router provider using Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  // Redirect logic based on authentication state
  String? redirectLogic(BuildContext context, GoRouterState state) {
    // Don't redirect if we're already at splash screen (to avoid redirect loops)
    if (state.uri.path == '/splash') {
      return null;
    }

    // Check if user is logged in (has valid UID)
    // We're not doing the full auth check here as that's handled in the splash screen
    final isLoggedIn = authState.uid != null;
    
    // Auth specific routes that should be accessible even when not logged in
    final areWeInAuthFlow = state.uri.path == '/landing' || 
                            state.uri.path == '/login' || 
                            state.uri.path.startsWith('/otp') ||
                            state.uri.path == '/user-information';
    
    // If not in auth flow and not logged in, redirect to landing
    if (!isLoggedIn && !areWeInAuthFlow) {
      return '/landing';
    }
    
    // If logged in and in auth flow, redirect to home
    if (isLoggedIn && areWeInAuthFlow) {
      return '/home';
    }
    
    // No redirection needed
    return null;
  }

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,  // Useful during development
    redirect: redirectLogic,
    routes: [
      // Splash screen (initial route)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Landing screen
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      
      // Login screen
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // OTP verification screen
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          // Extract parameters from state
          final verificationId = state.extra as Map<String, dynamic>?;
          
          // If no parameters, or missing required params, redirect to login
          if (verificationId == null) {
            return const LoginScreen();
          }
          
          return const OTPScreen();
        },
      ),
      
      // User information screen
      GoRoute(
        path: '/user-information',
        name: 'userInformation',
        builder: (context, state) => const UserInformationScreen(),
      ),
      
      // Home screen
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
});