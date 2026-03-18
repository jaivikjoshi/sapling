import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'leko_colors.dart';

abstract final class LekoTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: LekoColors.primary,
      onPrimary: LekoColors.textOnPrimary,
      secondary: LekoColors.secondary,
      onSecondary: Colors.white,
      tertiary: LekoColors.accent,
      onTertiary: LekoColors.textOnAccent,
      error: LekoColors.error,
      onError: Colors.white,
      surface: LekoColors.surface,
      onSurface: LekoColors.textPrimary,
      surfaceContainerHighest: LekoColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LekoColors.background,
      fontFamily: '.SF Pro Display', // Use system default
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.0,
          color: LekoColors.textPrimary,
        ),
        headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            color: LekoColors.textPrimary),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: LekoColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: LekoColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: LekoColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: LekoColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: LekoColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LekoColors.background,
        foregroundColor: LekoColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: LekoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LekoColors.surfaceNav,
        selectedItemColor: LekoColors.support, // Blush pink when selected
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LekoColors.primary,
        foregroundColor: LekoColors.textOnPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LekoColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LekoColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LekoColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: LekoColors.secondary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LekoColors.primary,
          foregroundColor: LekoColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LekoColors.secondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LekoColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
