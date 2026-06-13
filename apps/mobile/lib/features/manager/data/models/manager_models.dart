/// Plain immutable Dart models for the manager (EPIC-22) feature.
///
/// These deliberately avoid `@freezed` / `build_runner` so no code-gen step is
/// required.  The API contract mirrors the backend manager serialisers.
/// Money/rate fields that arrive as DRF `DecimalField` **strings** are parsed
/// via the private [_toDouble] / [_toInt] helpers (same pattern as
/// `dashboard_model.dart`).

// ---------------------------------------------------------------------------
// Helpers (file-private, same pattern as dashboard_model.dart)
// ---------------------------------------------------------------------------

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

List<T> _parseList<T>(
  Object? value,
  T Function(Map<String, dynamic>) parse,
) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}

// ---------------------------------------------------------------------------
// LinkedOwner
// ---------------------------------------------------------------------------

/// An owner whose property portfolio is accessible to this manager.
///
/// [status] is one of `'active'` | `'pending'` | `'revoked'`.
/// [unitCount] / [occupiedCount] / [monthlyRent] give a quick portfolio
/// summary inline with the list response to avoid extra calls.
class LinkedOwner {
  const LinkedOwner({
    required this.id,
    required this.ownerName,
    required this.ownerPhone,
    required this.status,
    this.unitCount = 0,
    this.occupiedCount = 0,
    this.monthlyRent = 0.0,
    this.avatarColor = '',
  });

  final String id;
  final String ownerName;
  final String ownerPhone;

  /// `'active'` | `'pending'` | `'revoked'`
  final String status;
  final int unitCount;
  final int occupiedCount;
  final double monthlyRent;

  /// Optional hex-color string for avatar placeholder rendering.
  final String avatarColor;

  bool get isActive => status == 'active';

  static LinkedOwner fromJson(Map<String, dynamic> json) => LinkedOwner(
        id: json['id']?.toString() ?? '',
        ownerName: json['owner_name']?.toString() ?? '',
        ownerPhone: json['owner_phone']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        unitCount: _toInt(json['unit_count']),
        occupiedCount: _toInt(json['occupied_count']),
        monthlyRent: _toDouble(json['monthly_rent']),
        avatarColor: json['avatar_color']?.toString() ?? '',
      );

  LinkedOwner copyWith({
    String? id,
    String? ownerName,
    String? ownerPhone,
    String? status,
    int? unitCount,
    int? occupiedCount,
    double? monthlyRent,
    String? avatarColor,
  }) =>
      LinkedOwner(
        id: id ?? this.id,
        ownerName: ownerName ?? this.ownerName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
        status: status ?? this.status,
        unitCount: unitCount ?? this.unitCount,
        occupiedCount: occupiedCount ?? this.occupiedCount,
        monthlyRent: monthlyRent ?? this.monthlyRent,
        avatarColor: avatarColor ?? this.avatarColor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedOwner &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerName == other.ownerName &&
          ownerPhone == other.ownerPhone &&
          status == other.status &&
          unitCount == other.unitCount &&
          occupiedCount == other.occupiedCount &&
          monthlyRent == other.monthlyRent &&
          avatarColor == other.avatarColor;

  @override
  int get hashCode => Object.hash(
        id,
        ownerName,
        ownerPhone,
        status,
        unitCount,
        occupiedCount,
        monthlyRent,
        avatarColor,
      );

  @override
  String toString() =>
      'LinkedOwner(id: $id, ownerName: $ownerName, status: $status, '
      'unitCount: $unitCount, occupiedCount: $occupiedCount, '
      'monthlyRent: $monthlyRent)';
}

// ---------------------------------------------------------------------------
// ManagerDashboard
// ---------------------------------------------------------------------------

/// Portfolio-wide aggregates returned by `GET /manager/dashboard`.
///
/// [owners] is the same [LinkedOwner] list embedded in the dashboard payload
/// for a single-request overview; [collectionRate] is a 0..1 fraction.
class ManagerDashboard {
  const ManagerDashboard({
    this.totalMonthlyRent = 0.0,
    this.occupiedUnits = 0,
    this.totalUnits = 0,
    this.collectionRate = 0.0,
    this.ownerCount = 0,
    this.owners = const [],
  });

  final double totalMonthlyRent;
  final int occupiedUnits;
  final int totalUnits;

  /// 0..1 fraction of rent collected this cycle.
  final double collectionRate;
  final int ownerCount;
  final List<LinkedOwner> owners;

  /// 0..1 fraction of units currently occupied; 0 when [totalUnits] is 0.
  double get occupancyRate =>
      totalUnits == 0 ? 0 : occupiedUnits / totalUnits;

  static ManagerDashboard fromJson(Map<String, dynamic> json) =>
      ManagerDashboard(
        totalMonthlyRent: _toDouble(json['total_monthly_rent']),
        occupiedUnits: _toInt(json['occupied_units']),
        totalUnits: _toInt(json['total_units']),
        collectionRate: _toDouble(json['collection_rate']),
        ownerCount: _toInt(json['owner_count']),
        owners: _parseList(json['owners'], LinkedOwner.fromJson),
      );

  ManagerDashboard copyWith({
    double? totalMonthlyRent,
    int? occupiedUnits,
    int? totalUnits,
    double? collectionRate,
    int? ownerCount,
    List<LinkedOwner>? owners,
  }) =>
      ManagerDashboard(
        totalMonthlyRent: totalMonthlyRent ?? this.totalMonthlyRent,
        occupiedUnits: occupiedUnits ?? this.occupiedUnits,
        totalUnits: totalUnits ?? this.totalUnits,
        collectionRate: collectionRate ?? this.collectionRate,
        ownerCount: ownerCount ?? this.ownerCount,
        owners: owners ?? this.owners,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagerDashboard &&
          runtimeType == other.runtimeType &&
          totalMonthlyRent == other.totalMonthlyRent &&
          occupiedUnits == other.occupiedUnits &&
          totalUnits == other.totalUnits &&
          collectionRate == other.collectionRate &&
          ownerCount == other.ownerCount &&
          owners == other.owners;

  @override
  int get hashCode => Object.hash(
        totalMonthlyRent,
        occupiedUnits,
        totalUnits,
        collectionRate,
        ownerCount,
        owners,
      );

  @override
  String toString() =>
      'ManagerDashboard(ownerCount: $ownerCount, totalUnits: $totalUnits, '
      'occupiedUnits: $occupiedUnits, collectionRate: $collectionRate)';
}

// ---------------------------------------------------------------------------
// TeamMember
// ---------------------------------------------------------------------------

/// A staff member added to the manager's team.
///
/// [role] is one of `'accountant'` | `'assistant'` | `'viewer'` |
/// `'sub_manager'`. [scopeOwnerIds] limits the member to a subset of linked
/// owners; empty means full scope.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.scopeOwnerIds = const [],
  });

  final String id;
  final String name;
  final String phone;

  /// `'accountant'` | `'assistant'` | `'viewer'` | `'sub_manager'`
  final String role;

  /// Owner IDs this member can access; empty = unrestricted.
  final List<String> scopeOwnerIds;

  static TeamMember fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        role: json['role']?.toString() ?? 'viewer',
        scopeOwnerIds: (json['scope_owner_ids'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
      );

  TeamMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    List<String>? scopeOwnerIds,
  }) =>
      TeamMember(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        scopeOwnerIds: scopeOwnerIds ?? this.scopeOwnerIds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          role == other.role &&
          scopeOwnerIds == other.scopeOwnerIds;

  @override
  int get hashCode =>
      Object.hash(id, name, phone, role, Object.hashAll(scopeOwnerIds));

  @override
  String toString() =>
      'TeamMember(id: $id, name: $name, role: $role, '
      'scopeOwnerIds: $scopeOwnerIds)';
}

// ---------------------------------------------------------------------------
// OwnerReport
// ---------------------------------------------------------------------------

/// Per-owner financial report, optionally backed by a generated PDF.
///
/// [net] is derived: [totalIncome] − [totalExpense]. [collectionRate] is 0..1.
/// [pdfUrl] is null until [ManagerRepository.generateOwnerReport] is called.
class OwnerReport {
  const OwnerReport({
    required this.ownerId,
    required this.ownerName,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.collectionRate = 0.0,
    this.occupiedUnits = 0,
    this.totalUnits = 0,
    this.pdfUrl,
  });

  final String ownerId;
  final String ownerName;
  final double totalIncome;
  final double totalExpense;

  /// 0..1 fraction of rent collected this cycle.
  final double collectionRate;
  final int occupiedUnits;
  final int totalUnits;

  /// Signed download URL; null when the PDF has not been generated yet.
  final String? pdfUrl;

  /// Net income: [totalIncome] − [totalExpense].
  double get net => totalIncome - totalExpense;

  static OwnerReport fromJson(Map<String, dynamic> json) => OwnerReport(
        ownerId: json['owner_id']?.toString() ?? '',
        ownerName: json['owner_name']?.toString() ?? '',
        totalIncome: _toDouble(json['total_income']),
        totalExpense: _toDouble(json['total_expense']),
        collectionRate: _toDouble(json['collection_rate']),
        occupiedUnits: _toInt(json['occupied_units']),
        totalUnits: _toInt(json['total_units']),
        pdfUrl: json['pdf_url'] as String?,
      );

  OwnerReport copyWith({
    String? ownerId,
    String? ownerName,
    double? totalIncome,
    double? totalExpense,
    double? collectionRate,
    int? occupiedUnits,
    int? totalUnits,
    String? pdfUrl,
  }) =>
      OwnerReport(
        ownerId: ownerId ?? this.ownerId,
        ownerName: ownerName ?? this.ownerName,
        totalIncome: totalIncome ?? this.totalIncome,
        totalExpense: totalExpense ?? this.totalExpense,
        collectionRate: collectionRate ?? this.collectionRate,
        occupiedUnits: occupiedUnits ?? this.occupiedUnits,
        totalUnits: totalUnits ?? this.totalUnits,
        pdfUrl: pdfUrl ?? this.pdfUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerReport &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          ownerName == other.ownerName &&
          totalIncome == other.totalIncome &&
          totalExpense == other.totalExpense &&
          collectionRate == other.collectionRate &&
          occupiedUnits == other.occupiedUnits &&
          totalUnits == other.totalUnits &&
          pdfUrl == other.pdfUrl;

  @override
  int get hashCode => Object.hash(
        ownerId,
        ownerName,
        totalIncome,
        totalExpense,
        collectionRate,
        occupiedUnits,
        totalUnits,
        pdfUrl,
      );

  @override
  String toString() =>
      'OwnerReport(ownerId: $ownerId, ownerName: $ownerName, '
      'totalIncome: $totalIncome, totalExpense: $totalExpense, '
      'collectionRate: $collectionRate, pdfUrl: $pdfUrl)';
}
