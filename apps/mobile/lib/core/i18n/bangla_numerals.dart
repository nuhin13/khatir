import 'package:intl/intl.dart';

/// Locale-aware numeral formatting helper.
///
/// Bangla (`bn`) uses Bengali digits (০১২৩...) via [NumberFormat]; English
/// (`en`) uses Western Arabic digits. Used for counts, amounts, etc. so the
/// whole UI reads naturally in the active locale.
class BanglaNumerals {
  BanglaNumerals._();

  /// Formats [value] using the digits of [localeCode] ('bn' or 'en').
  ///
  /// By default the locale's grouping separators are applied (e.g. `1,200`).
  /// Pass `grouped: false` to drop them — useful for date parts (year/month/day)
  /// where a thousands separator on the year would be wrong.
  static String format(num value, String localeCode, {bool grouped = true}) {
    final fmt = NumberFormat.decimalPattern(localeCode);
    if (!grouped) {
      fmt.turnOffGrouping();
    }
    return fmt.format(value);
  }

  /// Converts the Western digits in [input] to Bengali digits.
  static String toBangla(String input) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var out = input;
    for (var i = 0; i < western.length; i++) {
      out = out.replaceAll(western[i], bengali[i]);
    }
    return out;
  }
}
