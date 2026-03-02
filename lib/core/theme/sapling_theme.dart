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
      fontFamily: 'SF Pro Display',
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
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SaplingColors.surface,
        selectedItemColor: SaplingColors.primary,
        unselectedItemColor: SaplingColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SaplingColors.accent,
        foregroundColor: SaplingColors.textOnAccent,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SaplingColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaplingColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaplingColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: SaplingColors.secondary,
            width: 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SaplingColors.primary,
          foregroundColor: SaplingColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
