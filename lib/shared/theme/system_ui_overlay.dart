import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A widget that automatically updates system UI colors to match the app theme
class SystemUIOverlay extends ConsumerStatefulWidget {
  final Widget child;
  
  const SystemUIOverlay({super.key, required this.child});
  
  @override
  ConsumerState<SystemUIOverlay> createState() => _SystemUIOverlayState();
}

class _SystemUIOverlayState extends ConsumerState<SystemUIOverlay> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUI();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateUI();
  }
  
  @override
  void didChangePlatformBrightness() {
    _updateUI();
    super.didChangePlatformBrightness();
  }
  
  void _updateUI() {
    // Force edge-to-edge mode for better control of system bars
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Set the system UI colors for dark theme - ensuring full transparency
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false, // Prevent Android from overriding colors
        systemNavigationBarIconBrightness: Brightness.light, // White icons for dark theme
        statusBarIconBrightness: Brightness.light, // White status bar icons for dark theme
      ),
    );
    
    // Apply a second time after a short delay to override any system defaults
    // This is especially important for some Android versions that might reset navigation bar colors
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
    
    // Apply a third time with a longer delay to ensure persistence
    // This can help with devices that have system software that tries to restore default navigation bar colors
    Future.delayed(const Duration(milliseconds: 500), () {
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
  Widget build(BuildContext context) {
    // Update the UI whenever the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUI();
    });
    
    return widget.child;
  }
}