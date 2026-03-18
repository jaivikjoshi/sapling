import 'package:flutter/material.dart';

abstract final class LekoColors {
  // Editorial luxury palette
  static const Color primary = Color(0xFF1B3B42); // Deep Teal
  static const Color secondary = Color(0xFF3B9797); // Jade / Seafoam
  static const Color accent = Color(0xFFE28B78); // Muted Coral
  static const Color support = Color(0xFFDFAC9D); // Blush Pink / Soft Peach
  static const Color surfaceNav = Color(0xFF131D28); // Soft Navy

  static const Color background = Color(0xFFFBF9F6); // Warm Cream
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);

  static const Color textPrimary = Color(0xFF1A1A1A); // Almost black for high legibility
  static const Color textSecondary = Color(0xFF7D8C94); // Soft grey-blue
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent = Colors.white;

  static const Color labelGreen = Color(0xFF55896E); // Muted forest green
  static const Color labelOrange = Color(0xFFD98A5B); // Muted earthy orange
  static const Color labelRed = Color(0xFFC75D53); // Muted burnt red

  static const Color divider = Color(0xFFECEAE5);
  static const Color shimmer = Color(0xFFEEEEEE);

  // Premium Onboarding Flow (Dark Immerse)
  static const Color onboardingBackground = Color(0xFF0F1A1B); // Deep midnight forest green
  static const Color onboardingSurface = Color(0xFF19292A);
  static const Color onboardingTextPrimary = Color(0xFFF7F5F0); // Off-white/cream
  static const Color onboardingTextSecondary = Color(0xFFA1B3B0); // Soft glowing sage/grey
  static const Color onboardingButton = Color(0xFF3B9797); // Seafoam jade as CTA
  static const Color onboardingButtonText = Colors.white;
  static const Color onboardingTrack = Color(0xFF1A2D2E);
  static const Color onboardingFill = Color(0xFF5CBBA7);
}
