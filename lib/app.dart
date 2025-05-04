import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weibao/config/theme.dart';
import 'package:weibao/screens/auth/phone_auth_screen.dart';
import 'package:weibao/screens/home/home_screen.dart';
import 'package:weibao/services/auth_service.dart';

class WeibaoApp extends ConsumerWidget {
  const WeibaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weibao',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respect system theme
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    
    // Show loading screen while determining auth state
    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const PhoneAuthScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const Scaffold(
        body: Center(
          child: Text('Authentication error. Please restart the app.'),
        ),
      ),
    );
  }
}