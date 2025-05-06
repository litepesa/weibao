import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/firebase_options.dart';
import 'package:weibao/main_screens/home_screen.dart';
import 'package:weibao/shared/theme/chat_theme_extension.dart';
import 'package:weibao/shared/theme/system_ui_overlay.dart';
import 'package:weibao/shared/theme/theme_constants.dart';

// Provider for Firebase initialization status
final firebaseInitializedProvider = StateProvider<bool>((ref) => false);

// Provider for app initialization status
final appInitializedProvider = StateProvider<bool>((ref) => false);

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Basic system UI configuration
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Initialize Firebase with error handling
  final firebaseInitialized = await _initializeFirebase();
  
  runApp(
    ProviderScope(
      overrides: [
        // Use correct syntax for Riverpod 2.x
        firebaseInitializedProvider.overrideWith((ref) => firebaseInitialized),
      ],
      child: const WeiBaoApp(),
    ),
  );
}

// Removed the _configureSystemUI function as it's handled by SystemUIOverlay widget

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    return true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // In production, you might want to show a dialog here
    return false;
  }
}

class WeiBaoApp extends ConsumerStatefulWidget {
  const WeiBaoApp({super.key});

  @override
  ConsumerState<WeiBaoApp> createState() => _WeiBaoAppState();
}

class _WeiBaoAppState extends ConsumerState<WeiBaoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize app state asynchronously
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Initialize any app services, load preferences, etc.
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mark app as initialized
    if (mounted) {
      ref.read(appInitializedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangePlatformBrightness() {
    // The SystemUIOverlay widget handles this now
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeiBao',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentBlue,
          background: AppColors.background,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: AppColors.inputBackground,
          filled: true,
        ),
        extensions: [
          ChatThemeExtension.defaultTheme,
        ],
      ),
      home: const SystemUIOverlay(
        child: HomeScreen(),
      ), // Wrap HomeScreen with SystemUIOverlay
      
      // Add error handling for Flutter framework errors
      builder: (context, child) {
        // Add error boundary widget
        if (child == null) return const SizedBox.shrink();
        
        // Initialize responsive text scaling
        return MediaQuery(
          // Prevent text scaling beyond reasonable limits for better accessibility
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3),
          ),
          child: child,
        );
      },
    );
  }
}

// Error boundary widget to gracefully handle UI errors
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  
  const ErrorBoundaryWidget({super.key, required this.child});
  
  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  bool hasError = false;
  FlutterErrorDetails? errorDetails;
  
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        hasError = true;
        errorDetails = details;
      });
      
      // Log the error
      debugPrint('UI Error Caught by Boundary: ${details.exception}');
      
      // Forward to Flutter's error handler
      FlutterError.presentError(details);
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (hasError) {
      // Return fallback UI for errors
      return Material(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  errorDetails?.exception.toString() ?? 'Unknown error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hasError = false;
                      errorDetails = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}