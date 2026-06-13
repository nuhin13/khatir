// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

// ── TenantLease ────────────────────────────────────────────────────────────

/// @nodoc
mixin _$TenantLease {
  String get id;
  String get unitId;
  String get unitLabel;
  String get buildingLabel;
  String get landlordName;
  String get landlordPhone;
  double get monthlyRent;
  double get advanceAmount;
  DateTime? get startDate;
  DateTime? get endDate;
  String get noticePeriod;
  String get terms;
  String? get leaseDocumentRef;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  TenantLease copyWith({
    String? id,
    String? unitId,
    String? unitLabel,
    String? buildingLabel,
    String? landlordName,
    String? landlordPhone,
    double? monthlyRent,
    double? advanceAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? noticePeriod,
    String? terms,
    String? leaseDocumentRef,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantLease &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel) &&
            (identical(other.buildingLabel, buildingLabel) || other.buildingLabel == buildingLabel) &&
            (identical(other.landlordName, landlordName) || other.landlordName == landlordName) &&
            (identical(other.landlordPhone, landlordPhone) || other.landlordPhone == landlordPhone) &&
            (identical(other.monthlyRent, monthlyRent) || other.monthlyRent == monthlyRent) &&
            (identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount) &&
            (identical(other.startDate, startDate) || other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.noticePeriod, noticePeriod) || other.noticePeriod == noticePeriod) &&
            (identical(other.terms, terms) || other.terms == terms) &&
            (identical(other.leaseDocumentRef, leaseDocumentRef) || other.leaseDocumentRef == leaseDocumentRef) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, unitId, unitLabel, buildingLabel, landlordName,
        landlordPhone, monthlyRent, advanceAmount, startDate, endDate,
        noticePeriod, terms, leaseDocumentRef, createdAt, updatedAt);
}

class _TenantLease implements TenantLease {
  const _TenantLease({
    required this.id,
    this.unitId = '',
    this.unitLabel = '',
    this.buildingLabel = '',
    this.landlordName = '',
    this.landlordPhone = '',
    this.monthlyRent = 0,
    this.advanceAmount = 0,
    this.startDate,
    this.endDate,
    this.noticePeriod = '',
    this.terms = '',
    this.leaseDocumentRef,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String unitId;
  @override
  final String unitLabel;
  @override
  final String buildingLabel;
  @override
  final String landlordName;
  @override
  final String landlordPhone;
  @override
  final double monthlyRent;
  @override
  final double advanceAmount;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final String noticePeriod;
  @override
  final String terms;
  @override
  final String? leaseDocumentRef;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenantLease &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel) &&
            (identical(other.buildingLabel, buildingLabel) || other.buildingLabel == buildingLabel) &&
            (identical(other.landlordName, landlordName) || other.landlordName == landlordName) &&
            (identical(other.landlordPhone, landlordPhone) || other.landlordPhone == landlordPhone) &&
            (identical(other.monthlyRent, monthlyRent) || other.monthlyRent == monthlyRent) &&
            (identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount) &&
            (identical(other.startDate, startDate) || other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.noticePeriod, noticePeriod) || other.noticePeriod == noticePeriod) &&
            (identical(other.terms, terms) || other.terms == terms) &&
            (identical(other.leaseDocumentRef, leaseDocumentRef) || other.leaseDocumentRef == leaseDocumentRef) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, unitId, unitLabel, buildingLabel, landlordName,
        landlordPhone, monthlyRent, advanceAmount, startDate, endDate,
        noticePeriod, terms, leaseDocumentRef, createdAt, updatedAt);

  @override
  TenantLease copyWith({
    Object? id = _$sentinel,
    Object? unitId = _$sentinel,
    Object? unitLabel = _$sentinel,
    Object? buildingLabel = _$sentinel,
    Object? landlordName = _$sentinel,
    Object? landlordPhone = _$sentinel,
    Object? monthlyRent = _$sentinel,
    Object? advanceAmount = _$sentinel,
    Object? startDate = _$sentinel,
    Object? endDate = _$sentinel,
    Object? noticePeriod = _$sentinel,
    Object? terms = _$sentinel,
    Object? leaseDocumentRef = _$sentinel,
    Object? createdAt = _$sentinel,
    Object? updatedAt = _$sentinel,
  }) {
    return _TenantLease(
      id: id == _$sentinel ? this.id : id as String,
      unitId: unitId == _$sentinel ? this.unitId : unitId as String,
      unitLabel: unitLabel == _$sentinel ? this.unitLabel : unitLabel as String,
      buildingLabel: buildingLabel == _$sentinel ? this.buildingLabel : buildingLabel as String,
      landlordName: landlordName == _$sentinel ? this.landlordName : landlordName as String,
      landlordPhone: landlordPhone == _$sentinel ? this.landlordPhone : landlordPhone as String,
      monthlyRent: monthlyRent == _$sentinel ? this.monthlyRent : monthlyRent as double,
      advanceAmount: advanceAmount == _$sentinel ? this.advanceAmount : advanceAmount as double,
      startDate: startDate == _$sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _$sentinel ? this.endDate : endDate as DateTime?,
      noticePeriod: noticePeriod == _$sentinel ? this.noticePeriod : noticePeriod as String,
      terms: terms == _$sentinel ? this.terms : terms as String,
      leaseDocumentRef: leaseDocumentRef == _$sentinel ? this.leaseDocumentRef : leaseDocumentRef as String?,
      createdAt: createdAt == _$sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _$sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}

// ── TenantRent ─────────────────────────────────────────────────────────────

/// @nodoc
mixin _$TenantRent {
  String get id;
  String get period;
  RentStatus get status;
  double get amountDue;
  double get amountPaid;
  DateTime? get dueDate;
  DateTime? get paidAt;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  TenantRent copyWith({
    String? id,
    String? period,
    RentStatus? status,
    double? amountDue,
    double? amountPaid,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantRent &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.amountDue, amountDue) || other.amountDue == amountDue) &&
            (identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, period, status, amountDue, amountPaid,
        dueDate, paidAt, createdAt, updatedAt);
}

class _TenantRent implements TenantRent {
  const _TenantRent({
    required this.id,
    this.period = '',
    this.status = RentStatus.due,
    this.amountDue = 0,
    this.amountPaid = 0,
    this.dueDate,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String period;
  @override
  final RentStatus status;
  @override
  final double amountDue;
  @override
  final double amountPaid;
  @override
  final DateTime? dueDate;
  @override
  final DateTime? paidAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenantRent &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.amountDue, amountDue) || other.amountDue == amountDue) &&
            (identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, period, status, amountDue, amountPaid,
        dueDate, paidAt, createdAt, updatedAt);

  @override
  TenantRent copyWith({
    Object? id = _$sentinel,
    Object? period = _$sentinel,
    Object? status = _$sentinel,
    Object? amountDue = _$sentinel,
    Object? amountPaid = _$sentinel,
    Object? dueDate = _$sentinel,
    Object? paidAt = _$sentinel,
    Object? createdAt = _$sentinel,
    Object? updatedAt = _$sentinel,
  }) {
    return _TenantRent(
      id: id == _$sentinel ? this.id : id as String,
      period: period == _$sentinel ? this.period : period as String,
      status: status == _$sentinel ? this.status : status as RentStatus,
      amountDue: amountDue == _$sentinel ? this.amountDue : amountDue as double,
      amountPaid: amountPaid == _$sentinel ? this.amountPaid : amountPaid as double,
      dueDate: dueDate == _$sentinel ? this.dueDate : dueDate as DateTime?,
      paidAt: paidAt == _$sentinel ? this.paidAt : paidAt as DateTime?,
      createdAt: createdAt == _$sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _$sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}

// ── TenantReceipt ──────────────────────────────────────────────────────────

/// @nodoc
mixin _$TenantReceipt {
  String get id;
  String get period;
  double get amount;
  String get receiptRef;
  DateTime? get verifiedAt;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  TenantReceipt copyWith({
    String? id,
    String? period,
    double? amount,
    String? receiptRef,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantReceipt &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.receiptRef, receiptRef) || other.receiptRef == receiptRef) &&
            (identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, period, amount, receiptRef, verifiedAt, createdAt, updatedAt);
}

class _TenantReceipt implements TenantReceipt {
  const _TenantReceipt({
    required this.id,
    this.period = '',
    this.amount = 0,
    this.receiptRef = '',
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String period;
  @override
  final double amount;
  @override
  final String receiptRef;
  @override
  final DateTime? verifiedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenantReceipt &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.receiptRef, receiptRef) || other.receiptRef == receiptRef) &&
            (identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, period, amount, receiptRef, verifiedAt, createdAt, updatedAt);

  @override
  TenantReceipt copyWith({
    Object? id = _$sentinel,
    Object? period = _$sentinel,
    Object? amount = _$sentinel,
    Object? receiptRef = _$sentinel,
    Object? verifiedAt = _$sentinel,
    Object? createdAt = _$sentinel,
    Object? updatedAt = _$sentinel,
  }) {
    return _TenantReceipt(
      id: id == _$sentinel ? this.id : id as String,
      period: period == _$sentinel ? this.period : period as String,
      amount: amount == _$sentinel ? this.amount : amount as double,
      receiptRef: receiptRef == _$sentinel ? this.receiptRef : receiptRef as String,
      verifiedAt: verifiedAt == _$sentinel ? this.verifiedAt : verifiedAt as DateTime?,
      createdAt: createdAt == _$sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _$sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}

// ── TenantRecord ───────────────────────────────────────────────────────────

/// @nodoc
mixin _$TenantRecord {
  String get id;
  int get rating;
  String get notes;
  RecordConsent get consent;
  int get onTimeMonths;
  int get completedLeases;
  double get averageRating;
  int get disputes;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  TenantRecord copyWith({
    String? id,
    int? rating,
    String? notes,
    RecordConsent? consent,
    int? onTimeMonths,
    int? completedLeases,
    double? averageRating,
    int? disputes,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantRecord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.consent, consent) || other.consent == consent) &&
            (identical(other.onTimeMonths, onTimeMonths) || other.onTimeMonths == onTimeMonths) &&
            (identical(other.completedLeases, completedLeases) || other.completedLeases == completedLeases) &&
            (identical(other.averageRating, averageRating) || other.averageRating == averageRating) &&
            (identical(other.disputes, disputes) || other.disputes == disputes) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, rating, notes, consent, onTimeMonths,
        completedLeases, averageRating, disputes, createdAt, updatedAt);
}

class _TenantRecord implements TenantRecord {
  const _TenantRecord({
    required this.id,
    this.rating = 0,
    this.notes = '',
    this.consent = RecordConsent.private,
    this.onTimeMonths = 0,
    this.completedLeases = 0,
    this.averageRating = 0.0,
    this.disputes = 0,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final int rating;
  @override
  final String notes;
  @override
  final RecordConsent consent;
  @override
  final int onTimeMonths;
  @override
  final int completedLeases;
  @override
  final double averageRating;
  @override
  final int disputes;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenantRecord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.consent, consent) || other.consent == consent) &&
            (identical(other.onTimeMonths, onTimeMonths) || other.onTimeMonths == onTimeMonths) &&
            (identical(other.completedLeases, completedLeases) || other.completedLeases == completedLeases) &&
            (identical(other.averageRating, averageRating) || other.averageRating == averageRating) &&
            (identical(other.disputes, disputes) || other.disputes == disputes) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, rating, notes, consent, onTimeMonths,
        completedLeases, averageRating, disputes, createdAt, updatedAt);

  @override
  TenantRecord copyWith({
    Object? id = _$sentinel,
    Object? rating = _$sentinel,
    Object? notes = _$sentinel,
    Object? consent = _$sentinel,
    Object? onTimeMonths = _$sentinel,
    Object? completedLeases = _$sentinel,
    Object? averageRating = _$sentinel,
    Object? disputes = _$sentinel,
    Object? createdAt = _$sentinel,
    Object? updatedAt = _$sentinel,
  }) {
    return _TenantRecord(
      id: id == _$sentinel ? this.id : id as String,
      rating: rating == _$sentinel ? this.rating : rating as int,
      notes: notes == _$sentinel ? this.notes : notes as String,
      consent: consent == _$sentinel ? this.consent : consent as RecordConsent,
      onTimeMonths: onTimeMonths == _$sentinel ? this.onTimeMonths : onTimeMonths as int,
      completedLeases: completedLeases == _$sentinel ? this.completedLeases : completedLeases as int,
      averageRating: averageRating == _$sentinel ? this.averageRating : averageRating as double,
      disputes: disputes == _$sentinel ? this.disputes : disputes as int,
      createdAt: createdAt == _$sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _$sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}

// ── TenantMaintenanceReport ────────────────────────────────────────────────

/// @nodoc
mixin _$TenantMaintenanceReport {
  String get id;
  String get description;
  TenantMaintenanceCategory get category;
  String get photoRef;
  TenantMaintenanceStatus get status;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  TenantMaintenanceReport copyWith({
    String? id,
    String? description,
    TenantMaintenanceCategory? category,
    String? photoRef,
    TenantMaintenanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantMaintenanceReport &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) || other.description == description) &&
            (identical(other.category, category) || other.category == category) &&
            (identical(other.photoRef, photoRef) || other.photoRef == photoRef) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, description, category, photoRef,
        status, createdAt, updatedAt);
}

class _TenantMaintenanceReport implements TenantMaintenanceReport {
  const _TenantMaintenanceReport({
    required this.id,
    this.description = '',
    this.category = TenantMaintenanceCategory.other,
    this.photoRef = '',
    this.status = TenantMaintenanceStatus.open,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String description;
  @override
  final TenantMaintenanceCategory category;
  @override
  final String photoRef;
  @override
  final TenantMaintenanceStatus status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TenantMaintenanceReport &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) || other.description == description) &&
            (identical(other.category, category) || other.category == category) &&
            (identical(other.photoRef, photoRef) || other.photoRef == photoRef) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType, id, description, category, photoRef,
        status, createdAt, updatedAt);

  @override
  TenantMaintenanceReport copyWith({
    Object? id = _$sentinel,
    Object? description = _$sentinel,
    Object? category = _$sentinel,
    Object? photoRef = _$sentinel,
    Object? status = _$sentinel,
    Object? createdAt = _$sentinel,
    Object? updatedAt = _$sentinel,
  }) {
    return _TenantMaintenanceReport(
      id: id == _$sentinel ? this.id : id as String,
      description: description == _$sentinel ? this.description : description as String,
      category: category == _$sentinel ? this.category : category as TenantMaintenanceCategory,
      photoRef: photoRef == _$sentinel ? this.photoRef : photoRef as String,
      status: status == _$sentinel ? this.status : status as TenantMaintenanceStatus,
      createdAt: createdAt == _$sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _$sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}

// ── sentinel ───────────────────────────────────────────────────────────────
const _$sentinel = Object();
