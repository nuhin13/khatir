/// Maintenance-domain enums. Wire values are lowercase snake_case strings and
/// MUST match `docs/architecture/enums.md` (MaintenanceCategory /
/// MaintenanceStatus / ExpenseCategory / ExpenseSource) and the backend
/// `maintenance/enums.py`. Domain-specific (used only by [MaintenanceRequest] /
/// [Expense]), so they live in the owning feature rather than `core/enums`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// Category of a maintenance request. Mirrors backend `MaintenanceCategory`.
@JsonEnum(valueField: 'wire')
enum MaintenanceCategory {
  plumbing('plumbing'),
  electrical('electrical'),
  paint('paint'),
  structural('structural'),
  appliance('appliance'),
  utility('utility'),
  other('other');

  const MaintenanceCategory(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [MaintenanceCategory]. Unknown/absent values
  /// degrade to [MaintenanceCategory.other] (the backend default) so a partial
  /// read never throws.
  static MaintenanceCategory fromWire(String? value) {
    if (value == null) return MaintenanceCategory.other;
    for (final category in MaintenanceCategory.values) {
      if (category.wire == value) return category;
    }
    return MaintenanceCategory.other;
  }
}

/// Lifecycle status of a maintenance request. Mirrors backend
/// `MaintenanceStatus`.
///
/// A request is created [open]; resolving it (recording the cost, which
/// auto-creates an [Expense]) moves it to [resolved].
@JsonEnum(valueField: 'wire')
enum MaintenanceStatus {
  open('open'),
  resolved('resolved');

  const MaintenanceStatus(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into a [MaintenanceStatus]. Unknown/absent values
  /// degrade to [MaintenanceStatus.open] (the backend default for a new
  /// request) so a partial read never throws.
  static MaintenanceStatus fromWire(String? value) {
    if (value == null) return MaintenanceStatus.open;
    for (final status in MaintenanceStatus.values) {
      if (status.wire == value) return status;
    }
    return MaintenanceStatus.open;
  }
}

/// Category of an expense on a unit. Mirrors backend `ExpenseCategory`.
@JsonEnum(valueField: 'wire')
enum ExpenseCategory {
  plumbing('plumbing'),
  paint('paint'),
  electrical('electrical'),
  structural('structural'),
  appliance('appliance'),
  utility('utility'),
  other('other');

  const ExpenseCategory(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into an [ExpenseCategory]. Unknown/absent values
  /// degrade to [ExpenseCategory.other] (the backend default) so a partial read
  /// never throws.
  static ExpenseCategory fromWire(String? value) {
    if (value == null) return ExpenseCategory.other;
    for (final category in ExpenseCategory.values) {
      if (category.wire == value) return category;
    }
    return ExpenseCategory.other;
  }
}

/// How an expense originated. Mirrors backend `ExpenseSource`.
///
/// [request] expenses are auto-created when a maintenance request is resolved;
/// [manual] expenses are logged directly by the landlord.
@JsonEnum(valueField: 'wire')
enum ExpenseSource {
  request('request'),
  manual('manual');

  const ExpenseSource(this.wire);

  /// The lowercase snake_case value sent over the wire.
  final String wire;

  /// Parses a wire value into an [ExpenseSource]. Unknown/absent values degrade
  /// to [ExpenseSource.manual] (the backend default for a directly-logged
  /// expense) so a partial read never throws.
  static ExpenseSource fromWire(String? value) {
    if (value == null) return ExpenseSource.manual;
    for (final source in ExpenseSource.values) {
      if (source.wire == value) return source;
    }
    return ExpenseSource.manual;
  }
}
