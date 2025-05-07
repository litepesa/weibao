import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/app_router.dart';
import 'package:weibao/firebase_options.dart';
import 'package:weibao/providers/app_theme.dart';
import 'package:weibao/shared/utils/system_ui_handler.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set portrait orientation only
  SystemUIHandler.setPortraitOrientation();
  
  // Make system UI transparent
  SystemUIHandler.makeTransparent();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Run app
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get router from provider
    final router = ref.watch(routerProvider);
    
    // Get theme from provider
    final appTheme = ref.watch(themeProvider);
    
    return TransparentSystemUI(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'WeiBao',
        theme: appTheme.themeData,
        routerConfig: router,
      ),
    );
  }
}