import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  // Color scheme
  static const Color primaryColor = Color(0xFFFF0050);
  static const Color secondaryColor = Color(0xFF00F2EA);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color lightBackgroundColor = Color(0xFFFAFAFA);
  static const Color darkTextColor = Color(0xFF121212);
  static const Color lightTextColor = Color(0xFFFAFAFA);
  
  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackgroundColor,
      foregroundColor: darkTextColor,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightBackgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextColor,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightBackgroundColor,
      background: lightBackgroundColor,
      onPrimary: lightTextColor,
      onSecondary: darkTextColor,
      onSurface: darkTextColor,
      onBackground: darkTextColor,
    ),
  );
  
  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackgroundColor,
      foregroundColor: lightTextColor,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: lightTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: lightTextColor,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkBackgroundColor,
      background: darkBackgroundColor,
      onPrimary: lightTextColor,
      onSecondary: darkTextColor,
      onSurface: lightTextColor,
      onBackground: lightTextColor,
    ),
  );
}