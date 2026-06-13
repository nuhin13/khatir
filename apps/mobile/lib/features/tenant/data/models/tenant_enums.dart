/// Wire enums for the tenant data layer (EPIC-19 T-011).
///
/// All enums degrade unknown / null wire values to their default so the app
/// never crashes on a new backend value.

/// Rent status for the current month.
enum RentStatus {
  paid,
  due,
  overdue;

  /// Parses the wire string from `GET /me/rent`. Degrades to [due] on unknown.
  static RentStatus fromWire(String? wire) => switch (wire) {
        'paid' => RentStatus.paid,
        'due' => RentStatus.due,
        'overdue' => RentStatus.overdue,
        _ => RentStatus.due,
      };

  String get wire => name;
}

/// Status of a maintenance report submitted by the tenant.
enum TenantMaintenanceStatus {
  open,
  inProgress,
  resolved;

  static TenantMaintenanceStatus fromWire(String? wire) => switch (wire) {
        'open' => TenantMaintenanceStatus.open,
        'in_progress' => TenantMaintenanceStatus.inProgress,
        'resolved' => TenantMaintenanceStatus.resolved,
        _ => TenantMaintenanceStatus.open,
      };

  String get wire => switch (this) {
        TenantMaintenanceStatus.inProgress => 'in_progress',
        _ => name,
      };
}

/// Category for a maintenance report.
enum TenantMaintenanceCategory {
  plumbing,
  electrical,
  paint,
  other;

  static TenantMaintenanceCategory fromWire(String? wire) => switch (wire) {
        'plumbing' => TenantMaintenanceCategory.plumbing,
        'electrical' => TenantMaintenanceCategory.electrical,
        'paint' => TenantMaintenanceCategory.paint,
        _ => TenantMaintenanceCategory.other,
      };

  String get wire => name;
}

/// Whether a tenant record / rating has been consented to share with landlords.
enum RecordConsent {
  private,
  shared;

  static RecordConsent fromWire(String? wire) => switch (wire) {
        'private' => RecordConsent.private,
        'shared' => RecordConsent.shared,
        _ => RecordConsent.private,
      };

  String get wire => name;
}

/// Proof type submitted with a rent payment.
enum PayProofType {
  screenshot,
  txnId,
  note;

  static PayProofType fromWire(String? wire) => switch (wire) {
        'screenshot' => PayProofType.screenshot,
        'txn_id' => PayProofType.txnId,
        'note' => PayProofType.note,
        _ => PayProofType.note,
      };

  String get wire => switch (this) {
        PayProofType.txnId => 'txn_id',
        _ => name,
      };
}
