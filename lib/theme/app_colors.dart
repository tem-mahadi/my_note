import 'package:flutter/material.dart';

/// Centralized palette for the dark, cosmic UI used by the auth flow.
class AppColors {
  // === Background Gradients ===
  static const Color bgDark = Color(0xFF0A0E21);
  static const Color bgMid = Color(0xFF111638);
  static const Color bgLight = Color(0xFF1A1A4E);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDark, bgMid, bgLight],
  );

  // === Primary & Accent ===
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color accent = Color(0xFFFF6B9D);
  static const Color accentLight = Color(0xFFFF8FB6);

  // === Neon Highlights ===
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonYellow = Color(0xFFFFD600);
  static const Color neonRed = Color(0xFFFF1744);

  // === Glass ===
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBorderLight = Color(0x1AFFFFFF);

  // === Text ===
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textMuted = Color(0xFF6E6E8A);

  // === Status ===
  static const Color correct = Color(0xFF00E676);
  static const Color incorrect = Color(0xFFFF1744);

  // === Gradient for Buttons ===
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFE040FB)],
  );
}
