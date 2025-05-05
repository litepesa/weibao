import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/features/auth/screens/landing_screen.dart';
import 'package:weibao/firebase_options.dart';
import 'package:weibao/main_screens/home_screen.dart';
import 'package:weibao/providers/app_theme.dart';
import 'package:weibao/shared/theme/system_ui_overlay.dart';

// Provider for Firebase initialization status
final firebaseInitProvider = FutureProvider<bool>((ref) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    print('Firebase initialization failed: $e');
    return false;
  }
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wrap the entire app with ProviderScope for Riverpod and SystemUIOverlay for transparent system bars
  runApp(
    const ProviderScope(
      child: SystemUIOverlay(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Firebase initialization status
    final firebaseInit = ref.watch(firebaseInitProvider);
    
    // Get the app theme from the theme provider
    final appTheme = ref.watch(themeProvider);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'weibao',
      theme: appTheme.themeData,
      home: firebaseInit.when(
        data: (initialized) {
          // If Firebase is initialized successfully, show the HomeScreen
          return const HomeScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text(
              'Error initializing app: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}