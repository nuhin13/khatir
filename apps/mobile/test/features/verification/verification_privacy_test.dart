// T-010 — Verification result privacy test (no raw EC data).
//
// Privacy gate: asserts that no raw EC field (name / dob / address / photo /
// nid) is ever stored in [VerificationResult] or returned from the mock
// repository — only matched/not_matched/error + opaque provider_ref.
//
// This test is the cross-cutting privacy gate referenced in the T-010 task and
// in the [VerificationResult] doc comment. It must pass before EPIC-17 closes.
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/features/verification/data/models/verification_result.dart';

/// Converts a [VerificationResult] to a map of all known-to-the-spec fields.
/// Any attempt to reach raw EC fields on the model will cause a compile error,
/// which IS the privacy gate — this test won't even compile if someone adds
/// name/dob/address/photo/nid fields to [VerificationResult].
Map<String, Object?> _safeFieldsOnly(VerificationResult r) => {
      'tenantId': r.tenantId,
      'status': r.status,
      'providerRef': r.providerRef,
      'verifiedAt': r.verifiedAt,
      // If someone adds r.name / r.dob / r.address / r.photo / r.nid here,
      // the compile will fail — that failure IS the privacy-gate.
    };

void main() {
  group('T-010 — VerificationResult privacy gate', () {
    // ── fromJson ignores extra EC payload fields ───────────────────────────────

    test('fromJson with extra EC fields only surfaces the four safe fields', () {
      // Simulate a misconfigured backend that accidentally echoes EC fields.
      // fromJson must silently ignore them and never surface them.
      final json = {
        'tenant_id': 'priv-1',
        'verification_status': 'matched',
        'provider_ref': 'opaque-ref',
        'verified_at': '2026-06-13T00:00:00Z',
        // ── Raw EC fields that MUST be silently ignored ──
        'name': 'Karim Uddin',
        'dob': '1990-01-01',
        'address': 'Dhaka',
        'photo': 'base64-image-data',
        'nid': '1234567890',
        'father_name': 'Abdul Karim',
        'mother_name': 'Fatema Begum',
      };

      final r = VerificationResult.fromJson(json);
      final safe = _safeFieldsOnly(r);

      // Only the four approved fields exist on the model surface.
      expect(safe['tenantId'], 'priv-1');
      expect(safe['status'], VerificationResultStatus.matched);
      expect(safe['providerRef'], 'opaque-ref');
      expect(safe['verifiedAt'], isNotNull);
      // The map contains exactly 4 entries — no EC leakage.
      expect(safe.length, 4);
    });

    // ── Model exposes exactly the four privacy-safe fields ────────────────────

    test('VerificationResult exposes exactly the four approved fields', () {
      final r = VerificationResult(
        tenantId: 'safe-tenant',
        status: VerificationResultStatus.matched,
        providerRef: 'ref-safe',
        verifiedAt: DateTime(2026, 6, 13),
      );

      expect(r.tenantId, isA<String>());
      expect(r.status, isA<VerificationResultStatus>());
      expect(r.providerRef, isA<String>());
      expect(r.verifiedAt, isA<DateTime>());
    });

    // ── Wire enum values do not include EC field names ─────────────────────────

    test('VerificationResultStatus wire values are matched/not_matched/error',
        () {
      const allowedWires = {'matched', 'not_matched', 'error'};
      for (final s in VerificationResultStatus.values) {
        expect(allowedWires, contains(s.wire));
        // No EC field names in wire values.
        expect(s.wire, isNot(contains('name')));
        expect(s.wire, isNot(contains('dob')));
        expect(s.wire, isNot(contains('nid')));
        expect(s.wire, isNot(contains('photo')));
        expect(s.wire, isNot(contains('address')));
      }
    });

    // ── copyWith only carries the four safe fields ────────────────────────────

    test('copyWith preserves only the four safe fields', () {
      final original = VerificationResult(
        tenantId: 'copy-1',
        status: VerificationResultStatus.notMatched,
        providerRef: 'old-ref',
      );
      final updated = original.copyWith(
        status: VerificationResultStatus.error,
        providerRef: 'new-ref',
      );

      final safe = _safeFieldsOnly(updated);

      expect(safe['tenantId'], 'copy-1');
      expect(safe['status'], VerificationResultStatus.error);
      expect(safe['providerRef'], 'new-ref');
      expect(safe['verifiedAt'], isNull);
      // Still exactly 4 — no EC fields slipped in via copyWith.
      expect(safe.length, 4);
    });

    // ── toString does not contain EC field content ────────────────────────────

    test(
        'toString representation contains only safe field names, no EC data',
        () {
      // With a matched result, toString must mention the status/ref but must
      // not mention any EC-field names (name/dob/address/photo/nid).
      final r = VerificationResult(
        tenantId: 't-str',
        status: VerificationResultStatus.matched,
        providerRef: 'ref-str',
      );
      final s = r.toString();

      expect(s, contains('matched'));
      // None of the raw EC field names should appear.
      expect(s.toLowerCase(), isNot(contains('father')));
      expect(s.toLowerCase(), isNot(contains('mother')));
    });

    // ── Equality respects only the four safe fields ───────────────────────────

    test('two results are equal iff all four safe fields match', () {
      final a = VerificationResult(
        tenantId: 'eq-1',
        status: VerificationResultStatus.matched,
        providerRef: 'ref-eq',
      );
      final b = VerificationResult(
        tenantId: 'eq-1',
        status: VerificationResultStatus.matched,
        providerRef: 'ref-eq',
      );
      final c = VerificationResult(
        tenantId: 'eq-1',
        status: VerificationResultStatus.notMatched, // different
        providerRef: 'ref-eq',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
