import 'package:khatir_tokens/khatir_tokens.dart';

/// Notun Din palette re-exported from the shared design-tokens package.
///
/// All colors are sourced from `packages/design-tokens` (T-010) via
/// [KhatirColors]; nothing here is a hardcoded hex value. This alias keeps
/// app-side imports short (`AppColors.sage`) while the single source of truth
/// remains the tokens package shared across all three apps.
typedef AppColors = KhatirColors;
