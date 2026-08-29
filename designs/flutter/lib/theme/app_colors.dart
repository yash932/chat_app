import 'package:flutter/material.dart';

/// Color tokens — mirrors design-tokens/tokens.json.
/// Keep this in sync with web/css/tokens.css if you change a value.
class AppColors {
  AppColors._();

  // Light theme
  static const Color paperLight = Color(0xFFFBFBFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSunkenLight = Color(0xFFF4F4F6);
  static const Color inkLight = Color(0xFF1C1D21);
  static const Color inkSecondaryLight = Color(0xFF6B6D76);
  static const Color inkTertiaryLight = Color(0xFF9C9EA7);
  static const Color mistLight = Color(0xFFE7E7EA);
  static const Color mistStrongLight = Color(0xFFD6D7DC);

  // Dark theme
  static const Color paperDark = Color(0xFF111214);
  static const Color surfaceDark = Color(0xFF1A1B1E);
  static const Color surfaceSunkenDark = Color(0xFF0D0E10);
  static const Color inkDark = Color(0xFFF2F2F3);
  static const Color inkSecondaryDark = Color(0xFFA6A8B1);
  static const Color inkTertiaryDark = Color(0xFF71737C);
  static const Color mistDark = Color(0xFF2A2B2F);
  static const Color mistStrongDark = Color(0xFF3A3C42);

  // Accents — same role, different value per theme
  static const Color cobaltLight = Color(0xFF3049B5);
  static const Color cobaltHoverLight = Color(0xFF28409A);
  static const Color cobaltTintLight = Color(0xFFEAEDF9);
  static const Color cobaltDark = Color(0xFF5A72E0);
  static const Color cobaltHoverDark = Color(0xFF6C82E8);
  static const Color cobaltTintDark = Color(0xFF1E2440);

  static const Color signalGreenLight = Color(0xFF35A26A);
  static const Color signalGreenDark = Color(0xFF41C384);

  static const Color coralLight = Color(0xFFE5484D);
  static const Color coralTintLight = Color(0xFFFBEAEA);
  static const Color coralDark = Color(0xFFF27075);
  static const Color coralTintDark = Color(0xFF3A1F21);

  static const Color amberLight = Color(0xFFB7791F);
  static const Color amberDark = Color(0xFFD6A03D);

  static const Color onCobalt = Color(0xFFFFFFFF);
}
