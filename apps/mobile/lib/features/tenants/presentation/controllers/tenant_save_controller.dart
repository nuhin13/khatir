import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../features/billing/presentation/widgets/upgrade_prompt.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/family_member.dart';
import '../../data/models/tenant_create_result.dart';
import '../../data/tenants_providers.dart';
import '../screens/dmp_placeholder_screen.dart';
import '../screens/ocr_review_args.dart';

/// The reviewed/entered tenant fields, normalised from any of the three intake
/// drafts (OCR review, voice review, manual). This is the single shape the
/// convergent save action consumes — each review screen maps its own draft to
/// it, so the create + route + toast + error logic lives in exactly one place
/// (T-016 self-review: no per-path duplication).
class TenantSaveDraft {
  const TenantSaveDraft({
    required this.name,
    required this.nidNumber,
    required this.dob,
    required this.address,
    required this.family,
    this.photoRef = '',
    this.unitId,
  });

  /// Builds the normalised draft from the OCR/voice review screen's emission.
  factory TenantSaveDraft.fromReview(TenantReviewDraft d) => TenantSaveDraft(
        name: d.name,
        nidNumber: d.nidNumber,
        dob: d.dob,
        address: d.address,
        family: d.family,
        photoRef: d.photoRef,
        unitId: d.unitId,
      );

  final String name;
  final String nidNumber;
  final String dob;
  final String address;
  final List<FamilyMemberDraft> family;

  /// Opaque OCR image handle; empty for voice/manual (no stored artefact).
  final String photoRef;

  /// Optional target unit id threaded from the chooser.
  final String? unitId;
}

/// The single save+route action shared by all three add-tenant review screens
/// (OCR T-011, voice T-012, manual T-013). It persists the tenant via the
/// tenants data layer (T-014), surfaces the free-tier status as a toast when
/// the server reports it (T-008), routes to the DMP form on success
/// (`/dmpform/{tenantId}`, placeholder until EPIC-05), and shows an error
/// snackbar on failure — never partially navigating.
///
/// Construct it from a screen's [WidgetRef]; call [saveAndContinue] from the
/// proceed handler. It returns `true` on success (after navigating) and `false`
/// on failure (after showing the error), so the caller can clear its loading
/// state.
class TenantSaveController {
  const TenantSaveController(this._ref);

  /// The backend error-envelope code (see `core/enums.py` → `ErrorCode`) raised
  /// when a free-tier owner is already at their tenant allowance.
  static const String _kTierLimitExceeded = 'tier_limit_exceeded';

  final WidgetRef _ref;

  /// Creates the tenant from [draft] and, on success, navigates to the DMP form
  /// for the new tenant. Surfaces the free-tier toast (if the server reported
  /// usage) and an error snackbar on failure. [context] is used for navigation
  /// and the snackbars; the call short-circuits if it is no longer mounted.
  Future<bool> saveAndContinue(
    BuildContext context,
    TenantSaveDraft draft,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await _create(draft);
      if (!context.mounted) return false;
      _showUsageToast(context, l10n, result.usage);
      // Replace the review screen so back does not return to a stale form.
      context.pushReplacementNamed(
        DmpPlaceholderScreen.routeName,
        pathParameters: {'tenantId': result.tenant.id},
      );
      return true;
    } on ApiException catch (e) {
      if (!context.mounted) return false;
      // Free-tier landlord at their tenant allowance: instead of a bare error,
      // surface the friendly upgrade prompt (T-008) which routes to the plan
      // screen. Treat as a non-fatal outcome — the caller just clears loading.
      if (e.errorCode == _kTierLimitExceeded) {
        await UpgradePrompt.show(context);
        return false;
      }
      _showError(context, l10n.tenant_save_error);
      return false;
    } catch (_) {
      if (!context.mounted) return false;
      _showError(context, l10n.tenant_save_error);
      return false;
    }
  }

  /// Routes the create through the unit-scoped controller when a [unitId] is
  /// known (so the unit's tenant list refreshes in place), otherwise straight
  /// through the repository. Both return the masked tenant + optional usage.
  Future<TenantCreateResult> _create(TenantSaveDraft draft) {
    final family = _toFamily(draft.family);
    final unitId = draft.unitId;
    if (unitId != null && unitId.isNotEmpty) {
      return _ref.read(unitTenantsProvider(unitId).notifier).createDetailed(
            name: draft.name,
            nidNumber: draft.nidNumber.isEmpty ? null : draft.nidNumber,
            dob: _parseDob(draft.dob),
            address: draft.address.isEmpty ? null : draft.address,
            photoRef: draft.photoRef.isEmpty ? null : draft.photoRef,
            familyMembers: family,
          );
    }
    return _ref.read(tenantRepositoryProvider).createTenantDetailed(
          name: draft.name,
          nidNumber: draft.nidNumber.isEmpty ? null : draft.nidNumber,
          dob: _parseDob(draft.dob),
          address: draft.address.isEmpty ? null : draft.address,
          photoRef: draft.photoRef.isEmpty ? null : draft.photoRef,
          familyMembers: family,
        );
  }

  /// Maps the inline family drafts to the create model, dropping blank rows so
  /// an empty/half-filled member never reaches the wire.
  static List<FamilyMember>? _toFamily(List<FamilyMemberDraft> drafts) {
    final members = drafts
        .where((d) => d.name.trim().isNotEmpty || d.relation.trim().isNotEmpty)
        .map((d) => FamilyMember(name: d.name.trim(), relation: d.relation.trim()))
        .toList(growable: false);
    return members.isEmpty ? null : members;
  }

  /// Parses a free-text `dob` to a [DateTime], or `null` when it is blank/
  /// unparseable (the field is optional and best-effort).
  static DateTime? _parseDob(String dob) {
    final trimmed = dob.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  void _showUsageToast(
    BuildContext context,
    AppLocalizations l10n,
    TenantUsage? usage,
  ) {
    if (usage == null) return;
    final text = l10n.tenant_free_tier_status(usage.tenantsUsed, usage.freeLimit);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showError(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
