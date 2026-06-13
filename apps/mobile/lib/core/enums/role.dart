/// Canonical user roles. Wire values are lowercase snake_case strings and
/// MUST match `docs/architecture/enums.md` (Role).
enum Role {
  landlord('landlord'),
  manager('manager'),
  tenant('tenant'),
  caretaker('caretaker'),
  admin('admin');

  const Role(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [Role]. Returns `null` for unknown values.
  static Role? fromWire(String? value) {
    if (value == null) return null;
    for (final role in Role.values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}
