import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/firebase_options.dart';
import 'package:weibao/routes/app_router.dart';
import 'package:weibao/shared/theme/chat_theme_extension.dart';
import 'package:weibao/shared/theme/theme_constants.dart';
import 'dart:async';

// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Force edge-to-edge mode for better control of system bars
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Get the platform brightness to set initial theme
  final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  
  // Initial setup of system UI based on platform brightness
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false, // Prevent Android from overriding colors
      systemNavigationBarIconBrightness: Brightness.light, // Always light for dark theme
      statusBarIconBrightness: Brightness.light, // Always light for dark theme
    ),
  );
  
  // Initialize Firebase BEFORE running the app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // Start the app after Firebase is initialized
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _uiUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Apply direct system navigation bar fix with a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceUpdateSystemUI();
    });
    
    // Schedule periodic updates to ensure the navigation bar stays the correct color
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _forceUpdateSystemUI();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _forceUpdateSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.light, // White icons for dark theme
        statusBarIconBrightness: Brightness.light, // White status bar icons for dark theme
      ),
    );
    
    // Apply a second time after a short delay to override any system defaults
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      }
    });
  }
  
  @override
  void didChangePlatformBrightness() {
    _forceUpdateSystemUI();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Update the UI whenever the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceUpdateSystemUI();
    });
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeiBao',
      theme: _buildTheme(),
      initialRoute: Constants.landingScreen,
      onGenerateRoute: AppRouter.generateRoute,
      navigatorObservers: [routeObserver],
    );
  }
  
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, 
            vertical: AppSpacing.m
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.m)),
        ),
        clipBehavior: Clip.antiAlias, // Added clipping for better aesthetics
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        titleLarge: TextStyle(color: AppColors.textPrimary),
        titleMedium: TextStyle(color: AppColors.textPrimary),
        titleSmall: TextStyle(color: AppColors.textSecondary),
        labelLarge: TextStyle(color: AppColors.textPrimary),
        labelMedium: TextStyle(color: AppColors.textPrimary),
        labelSmall: TextStyle(color: AppColors.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.all(AppSpacing.m),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        // Added better focus state
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
      // Added better transition animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme(
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentBlue,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: Colors.white,
        brightness: Brightness.dark, // Always dark theme
      ),
      extensions: [
        ChatThemeExtension.defaultTheme,
      ],
    );
  }
}