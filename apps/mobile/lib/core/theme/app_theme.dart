import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import 'text_styles.dart';

/// Notun Din [ThemeData], assembled entirely from the shared design tokens
/// ([KhatirColors], [KhatirRadius], [KhatirSpacing]) — no inline hex/px.
class AppTheme {
  AppTheme._();

  /// Soft elevation used by cards / bottom nav across the app.
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x142C3530), // ink @ 8% — derived from KhatirColors.ink
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static ThemeData light() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: KhatirColors.sage,
      onPrimary: KhatirColors.cream,
      primaryContainer: KhatirColors.sageBg,
      secondary: KhatirColors.rose,
      onSecondary: KhatirColors.cream,
      secondaryContainer: KhatirColors.roseBg,
      tertiary: KhatirColors.butter,
      tertiaryContainer: KhatirColors.butterBg,
      surface: KhatirColors.card,
      onSurface: KhatirColors.ink,
      error: KhatirColors.danger,
      errorContainer: KhatirColors.dangerBg,
      outline: KhatirColors.line,
      outlineVariant: KhatirColors.lineDk,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KhatirColors.cream,
      fontFamily: KhatirFonts.body,
      textTheme: AppTextStyles.textTheme,
      cardTheme: CardThemeData(
        color: KhatirColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.card),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KhatirColors.sageBg,
        labelStyle: AppTextStyles.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.chip),
        ),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KhatirColors.sage,
          foregroundColor: KhatirColors.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s6,
            vertical: KhatirSpacing.s4,
          ),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.button),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KhatirColors.card,
        selectedItemColor: KhatirColors.sageDk,
        unselectedItemColor: KhatirColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
