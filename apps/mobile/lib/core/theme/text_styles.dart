import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// Notun Din text styles.
///
/// Font families come from the shared tokens ([KhatirFonts]):
/// - Plus Jakarta Sans → titles / headings
/// - Hind Siliguri      → body (renders Bangla well)
/// - Caveat             → handwritten accents
///
/// Colors are sourced from [KhatirColors]; no inline hex.
class AppTextStyles {
  AppTextStyles._();

  static const String _title = KhatirFonts.title;
  static const String _body = KhatirFonts.body;
  static const String _hand = KhatirFonts.hand;

  // Display / headings — Plus Jakarta Sans.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _title,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: KhatirColors.ink,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _title,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: KhatirColors.ink,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _title,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: KhatirColors.ink,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _title,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: KhatirColors.ink,
  );

  // Body — Hind Siliguri.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: KhatirColors.ink,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: KhatirColors.ink2,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: KhatirColors.muted,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: KhatirColors.ink,
  );

  // Handwritten accent — Caveat.
  static const TextStyle accent = TextStyle(
    fontFamily: _hand,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: KhatirColors.sageDk,
  );

  /// Maps the Notun Din styles onto a Material [TextTheme].
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    headlineMedium: headlineMedium,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
  );
}
