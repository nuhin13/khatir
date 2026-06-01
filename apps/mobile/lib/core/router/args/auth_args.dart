/// Typed arguments passed between auth screens via go_router `extra`.
///
/// Avoids loose `Map`s for navigation payloads (self-review §14). T-010 reads
/// [phone] (E.164-normalised) to verify the OTP.
class AuthArgs {
  const AuthArgs({required this.phone});

  /// E.164-normalised phone number, e.g. `+8801711000111`.
  final String phone;
}
