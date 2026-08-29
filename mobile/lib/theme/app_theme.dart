import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Semantic color roles, resolved per-theme. Access anywhere with:
/// `final c = Theme.of(context).extension<AppSemanticColors>()!;`
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color paper;
  final Color surface;
  final Color surfaceSunken;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color mist;
  final Color mistStrong;
  final Color cobalt;
  final Color cobaltHover;
  final Color cobaltTint;
  final Color onCobalt;
  final Color signalGreen;
  final Color coral;
  final Color coralTint;
  final Color amber;

  const AppSemanticColors({
    required this.paper,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.mist,
    required this.mistStrong,
    required this.cobalt,
    required this.cobaltHover,
    required this.cobaltTint,
    required this.onCobalt,
    required this.signalGreen,
    required this.coral,
    required this.coralTint,
    required this.amber,
  });

  static const light = AppSemanticColors(
    paper: AppColors.paperLight,
    surface: AppColors.surfaceLight,
    surfaceSunken: AppColors.surfaceSunkenLight,
    ink: AppColors.inkLight,
    inkSecondary: AppColors.inkSecondaryLight,
    inkTertiary: AppColors.inkTertiaryLight,
    mist: AppColors.mistLight,
    mistStrong: AppColors.mistStrongLight,
    cobalt: AppColors.cobaltLight,
    cobaltHover: AppColors.cobaltHoverLight,
    cobaltTint: AppColors.cobaltTintLight,
    onCobalt: AppColors.onCobalt,
    signalGreen: AppColors.signalGreenLight,
    coral: AppColors.coralLight,
    coralTint: AppColors.coralTintLight,
    amber: AppColors.amberLight,
  );

  static const dark = AppSemanticColors(
    paper: AppColors.paperDark,
    surface: AppColors.surfaceDark,
    surfaceSunken: AppColors.surfaceSunkenDark,
    ink: AppColors.inkDark,
    inkSecondary: AppColors.inkSecondaryDark,
    inkTertiary: AppColors.inkTertiaryDark,
    mist: AppColors.mistDark,
    mistStrong: AppColors.mistStrongDark,
    cobalt: AppColors.cobaltDark,
    cobaltHover: AppColors.cobaltHoverDark,
    cobaltTint: AppColors.cobaltTintDark,
    onCobalt: AppColors.onCobalt,
    signalGreen: AppColors.signalGreenDark,
    coral: AppColors.coralDark,
    coralTint: AppColors.coralTintDark,
    amber: AppColors.amberDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? paper,
    Color? surface,
    Color? surfaceSunken,
    Color? ink,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? mist,
    Color? mistStrong,
    Color? cobalt,
    Color? cobaltHover,
    Color? cobaltTint,
    Color? onCobalt,
    Color? signalGreen,
    Color? coral,
    Color? coralTint,
    Color? amber,
  }) {
    return AppSemanticColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      mist: mist ?? this.mist,
      mistStrong: mistStrong ?? this.mistStrong,
      cobalt: cobalt ?? this.cobalt,
      cobaltHover: cobaltHover ?? this.cobaltHover,
      cobaltTint: cobaltTint ?? this.cobaltTint,
      onCobalt: onCobalt ?? this.onCobalt,
      signalGreen: signalGreen ?? this.signalGreen,
      coral: coral ?? this.coral,
      coralTint: coralTint ?? this.coralTint,
      amber: amber ?? this.amber,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return this;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light = _build(AppSemanticColors.light, Brightness.light);
  static ThemeData dark = _build(AppSemanticColors.dark, Brightness.dark);

  static ThemeData _build(AppSemanticColors c, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.cobalt,
        onPrimary: c.onCobalt,
        secondary: c.signalGreen,
        onSecondary: c.onCobalt,
        error: c.coral,
        onError: c.onCobalt,
        surface: c.surface,
        onSurface: c.ink,
      ),
      extensions: [c],
      fontFamily: AppTypography.fontFamilyUI,
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.title(c.ink),
      ),
      dividerTheme: DividerThemeData(color: c.mist, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.mistStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.mistStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.cobalt, width: 1.5),
        ),
        hintStyle: AppTypography.body(c.inkTertiary),
        labelStyle: AppTypography.caption(c.inkSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.cobalt,
          foregroundColor: c.onCobalt,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.bodyStrong(c.onCobalt),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.cobalt,
        unselectedItemColor: c.inkTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
    );
  }
}
