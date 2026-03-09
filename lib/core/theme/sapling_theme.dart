import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sapling_colors.dart';

abstract final class SaplingTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: SaplingColors.primary,
      onPrimary: SaplingColors.textOnPrimary,
      secondary: SaplingColors.secondary,
      onSecondary: Colors.white,
      tertiary: SaplingColors.accent,
      onTertiary: SaplingColors.textOnAccent,
      error: SaplingColors.error,
      onError: Colors.white,
      surface: SaplingColors.surface,
      onSurface: SaplingColors.textPrimary,
      surfaceContainerHighest: SaplingColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SaplingColors.background,
      fontFamily: '.SF Pro Display', // Use system default
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.0,
          color: SaplingColors.textPrimary,
        ),
        headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            color: SaplingColors.textPrimary),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: SaplingColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: SaplingColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: SaplingColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: SaplingColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: SaplingColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SaplingColors.background,
        foregroundColor: SaplingColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: SaplingColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SaplingColors.surfaceNav,
        selectedItemColor: SaplingColors.support, // Blush pink when selected
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SaplingColors.primary,
        foregroundColor: SaplingColors.textOnPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SaplingColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SaplingColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SaplingColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SaplingColors.secondary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SaplingColors.primary,
          foregroundColor: SaplingColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SaplingColors.secondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SaplingColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
