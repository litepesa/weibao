import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class to handle system UI appearance consistently across the app
class SystemUIHandler {
  /// Make the system UI transparent and edge-to-edge
  static void makeTransparent() {
    // Set system UI mode to edge-to-edge (full immersive)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Make status bar and navigation bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Status bar
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        
        // Navigation bar
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        
        // Prevent Android from overriding our settings
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }
  
  /// A widget that ensures system UI stays transparent
  static Widget wrapForSustainedTransparency(BuildContext context, Widget child) {
    // Apply transparency when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      makeTransparent();
    });
    
    return NotificationListener<ScrollNotification>(
      // Reapply transparency when scrolling ends (some devices reset on scroll)
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          makeTransparent();
        }
        return false;
      },
      child: child,
    );
  }
  
  /// Set portrait orientation only
  static void setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

/// A widget that ensures system UI stays transparent
class TransparentSystemUI extends StatefulWidget {
  final Widget child;
  
  const TransparentSystemUI({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<TransparentSystemUI> createState() => _TransparentSystemUIState();
}

class _TransparentSystemUIState extends State<TransparentSystemUI> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemUIHandler.makeTransparent();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-apply system UI styling when app is resumed
    if (state == AppLifecycleState.resumed) {
      SystemUIHandler.makeTransparent();
    }
    super.didChangeAppLifecycleState(state);
  }
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      // Reapply transparency when scrolling ends (some devices reset on scroll)
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          SystemUIHandler.makeTransparent();
        }
        return false;
      },
      child: widget.child,
    );
  }
}