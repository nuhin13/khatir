import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A BD mobile number is valid when it is 11 local digits starting with `01`
/// and a valid operator prefix digit (3–9), i.e. `01[3-9]XXXXXXXX`.
final RegExp _bdLocalPattern = RegExp(r'^01[3-9]\d{8}$');

/// Holds the raw phone-input text. Riverpod-managed form state so the submit
/// button enablement and inline validation stay declarative.
class PhoneFormController extends AutoDisposeNotifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final phoneFormControllerProvider =
    AutoDisposeNotifierProvider<PhoneFormController, String>(
  PhoneFormController.new,
);

/// Strips separators and returns the local digit string (e.g. `01711000111`).
String localDigits(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  // Tolerate a pasted +880 / 880 prefix by reducing to the local 0-form.
  if (digits.startsWith('880')) {
    digits = '0${digits.substring(3)}';
  }
  return digits;
}

/// Whether [raw] is a valid BD mobile number.
bool isValidBdPhone(String raw) => _bdLocalPattern.hasMatch(localDigits(raw));

/// Derived: is the current form value a submittable BD number?
final phoneValidProvider = AutoDisposeProvider<bool>((ref) {
  final value = ref.watch(phoneFormControllerProvider);
  return isValidBdPhone(value);
});
