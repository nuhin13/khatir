// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not allowed to use it.');

/// @nodoc
mixin _$VerificationResult {
  String get tenantId => throw _privateConstructorUsedError;
  VerificationResultStatus get status => throw _privateConstructorUsedError;
  String get providerRef => throw _privateConstructorUsedError;
  DateTime? get verifiedAt => throw _privateConstructorUsedError;

  /// Create a copy of VerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VerificationResultCopyWith<VerificationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationResultCopyWith<$Res> {
  factory $VerificationResultCopyWith(
          VerificationResult value, $Res Function(VerificationResult) then) =
      _$VerificationResultCopyWithImpl<$Res, VerificationResult>;
  @useResult
  $Res call(
      {String tenantId,
      VerificationResultStatus status,
      String providerRef,
      DateTime? verifiedAt});
}

/// @nodoc
class _$VerificationResultCopyWithImpl<$Res, $Val extends VerificationResult>
    implements $VerificationResultCopyWith<$Res> {
  _$VerificationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? status = null,
    Object? providerRef = null,
    Object? verifiedAt = freezed,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as VerificationResultStatus,
      providerRef: null == providerRef
          ? _value.providerRef
          : providerRef // ignore: cast_nullable_to_non_nullable
              as String,
      verifiedAt: freezed == verifiedAt
          ? _value.verifiedAt
          : verifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VerificationResultImplCopyWith<$Res>
    implements $VerificationResultCopyWith<$Res> {
  factory _$$VerificationResultImplCopyWith(_$VerificationResultImpl value,
          $Res Function(_$VerificationResultImpl) then) =
      __$$VerificationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      VerificationResultStatus status,
      String providerRef,
      DateTime? verifiedAt});
}

/// @nodoc
class __$$VerificationResultImplCopyWithImpl<$Res>
    extends _$VerificationResultCopyWithImpl<$Res, _$VerificationResultImpl>
    implements _$$VerificationResultImplCopyWith<$Res> {
  __$$VerificationResultImplCopyWithImpl(_$VerificationResultImpl _value,
      $Res Function(_$VerificationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of VerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? status = null,
    Object? providerRef = null,
    Object? verifiedAt = freezed,
  }) {
    return _then(_$VerificationResultImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as VerificationResultStatus,
      providerRef: null == providerRef
          ? _value.providerRef
          : providerRef // ignore: cast_nullable_to_non_nullable
              as String,
      verifiedAt: freezed == verifiedAt
          ? _value.verifiedAt
          : verifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$VerificationResultImpl implements _VerificationResult {
  const _$VerificationResultImpl(
      {required this.tenantId,
      required this.status,
      this.providerRef = '',
      this.verifiedAt});

  @override
  final String tenantId;
  @override
  final VerificationResultStatus status;
  @override
  @JsonKey()
  final String providerRef;
  @override
  final DateTime? verifiedAt;

  @override
  String toString() {
    return 'VerificationResult(tenantId: $tenantId, status: $status, providerRef: $providerRef, verifiedAt: $verifiedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationResultImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.providerRef, providerRef) ||
                other.providerRef == providerRef) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, tenantId, status, providerRef, verifiedAt);

  /// Create a copy of VerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationResultImplCopyWith<_$VerificationResultImpl> get copyWith =>
      __$$VerificationResultImplCopyWithImpl<_$VerificationResultImpl>(
          this, _$identity);
}

abstract class _VerificationResult implements VerificationResult {
  const factory _VerificationResult(
      {required final String tenantId,
      required final VerificationResultStatus status,
      final String providerRef,
      final DateTime? verifiedAt}) = _$VerificationResultImpl;

  @override
  String get tenantId;
  @override
  VerificationResultStatus get status;
  @override
  String get providerRef;
  @override
  DateTime? get verifiedAt;

  /// Create a copy of VerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerificationResultImplCopyWith<_$VerificationResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
