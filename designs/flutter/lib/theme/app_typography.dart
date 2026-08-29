import 'package:flutter/material.dart';

/// Type scale — mirrors design-tokens/tokens.json → typography.
///
/// `fontFamilyUI` expects "Inter" to be bundled (see pubspec.yaml) or
/// swapped for GoogleFonts.inter(). `fontFamilyMono` ("JetBrainsMono") is
/// the kit's signature detail: reserve it for timestamps, unread counts,
/// and metadata only — never for message body text.
class AppTypography {
  AppTypography._();

  static const String fontFamilyUI = 'Inter';
  static const String fontFamilyMono = 'JetBrainsMono';

  static const List<String> fallbackUI = [
    '-apple-system',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle display(Color color) => TextStyle(
        fontFamily: fontFamilyUI,
        fontFamilyFallback: fallbackUI,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontFamily: fontFamilyUI,
        fontFamilyFallback: fallbackUI,
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle subtitle(Color color) => TextStyle(
        fontFamily: fontFamilyUI,
        fontFamilyFallback: fallbackUI,
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontFamily: fontFamilyUI,
        fontFamilyFallback: fallbackUI,
        fontSize: 15,
        height: 21 / 15,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyStrong(Color color) => TextStyle(
        fontFamily: fontFamilyUI,
        fontFamilyFallback: fallbackUI,
        fontSize: 15,
        height: 21 / 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: fontFamilyUI,
        fontFamilyFallback: fallbackUI,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle mono(Color color) => TextStyle(
        fontFamily: fontFamilyMono,
        fontFamilyFallback: const ['ui-monospace', 'monospace'],
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
