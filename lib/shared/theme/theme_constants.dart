import 'package:flutter/material.dart';

/// App color constants for the chat app
class AppColors {
  // Primary brand colors
  static const primaryGreen = Color(0xFF25D366);    // Primary green color
  static const accentBlue = Color(0xFF53BDEB);      // Accent blue color
  
  // Background and surface colors
  static const background = Color(0xFF30302E);      // Main background
  static const surface = Color(0xFF262624);         // Surface color
  static const surfaceVariant = Color(0xFF3A3A38);  // Surface variant for inputs
  
  // Text colors
  static const textPrimary = Colors.white;          // Primary text color
  static const textSecondary = Color(0xFFBBBBBB);   // Secondary text color
  static const textTertiary = Color(0xFF999999);    // Tertiary text color
  
  // Border and divider colors
  static const border = Color(0xFF444442);          // Border color
  
  // Chat specific colors
  static const senderBubble = Color(0xFF066C38);    // Sender bubble color
  static const receiverBubble = Color(0xFF262624);  // Receiver bubble color
  static const inputBackground = Color(0xFF3A3A38); // Input background
  
  // Semantic colors
  static const success = Color(0xFF25D366);         // Success actions/states
  static const error = Color(0xFFE55252);           // Error actions/states
  static const warning = Color(0xFFFFA000);         // Warning actions/states
  static const info = Color(0xFF53BDEB);            // Information actions/states
  
  // Overlay and utility colors
  static const overlay = Color(0xB330302E);         // 70% background overlay
  static const ripple = Color(0x1FFFFFFF);          // 12% white ripple effect
}

/// UI spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Specific spacing for chat UI
  static const double bubblePadding = 12.0;
  static const double messageBetween = 4.0;
  static const double messageGroup = 16.0;
}

/// UI radius constants
class AppRadius {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double circular = 1000.0;  // For perfectly circular shapes
  
  // Chat UI specific radii
  static const senderBubbleRadius = BorderRadius.only(
    topLeft: Radius.circular(m),
    topRight: Radius.circular(m),
    bottomLeft: Radius.circular(m),
    bottomRight: Radius.circular(xs),
  );
  
  static const receiverBubbleRadius = BorderRadius.only(
    topLeft: Radius.circular(m),
    topRight: Radius.circular(m),
    bottomLeft: Radius.circular(xs),
    bottomRight: Radius.circular(m),
  );
}

/// Animation duration constants
class AppDurations {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);
  
  // Standard animation curves
  static const standard = Curves.easeInOut;
  static const emphasized = Curves.easeOutCubic;
}