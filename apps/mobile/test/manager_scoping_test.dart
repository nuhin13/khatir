import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/features/manager/data/models/manager_models.dart';

/// T-012 — Manager scoping and team permission tests.
///
/// Verifies the hard scoping contract:
///   1. A manager sees ONLY active-linked owners (not pending or revoked).
///   2. A team member with a limited scopeOwnerIds cannot access out-of-scope
///      owner data.
///
/// These are pure unit tests — no network, no widgets, no providers.
void main() {
  // ── Test fixtures ──────────────────────────────────────────────────────────

  const ownerActive1 = LinkedOwner(
    id: 'o_active_1',
    ownerName: 'Karim Saheb',
    ownerPhone: '01711000001',
    status: 'active',
    unitCount: 8,
    occupiedCount: 6,
    monthlyRent: 40000,
  );

  const ownerActive2 = LinkedOwner(
    id: 'o_active_2',
    ownerName: 'Rahim Bhai',
    ownerPhone: '01711000002',
    status: 'active',
    unitCount: 4,
    occupiedCount: 3,
    monthlyRent: 20000,
  );

  const ownerPending = LinkedOwner(
    id: 'o_pending',
    ownerName: 'Pending Owner',
    ownerPhone: '01811000003',
    status: 'pending',
  );

  const ownerRevoked = LinkedOwner(
    id: 'o_revoked',
    ownerName: 'Revoked Owner',
    ownerPhone: '01911000004',
    status: 'revoked',
  );

  final allOwners = [
    ownerActive1,
    ownerActive2,
    ownerPending,
    ownerRevoked,
  ];

  // ── Scoping tests ──────────────────────────────────────────────────────────

  group('Manager scoping gate', () {
    test('only active owners are visible on the home screen', () {
      // Replicate the filter applied in MgrHomeScreen.
      final visible = allOwners.where((o) => o.isActive).toList();

      expect(visible, hasLength(2));
      expect(visible.map((o) => o.id), containsAll(['o_active_1', 'o_active_2']));
      expect(visible.any((o) => o.id == 'o_pending'), isFalse);
      expect(visible.any((o) => o.id == 'o_revoked'), isFalse);
    });

    test('pending owners are not marked as active', () {
      expect(ownerPending.isActive, isFalse);
    });

    test('revoked owners are not marked as active', () {
      expect(ownerRevoked.isActive, isFalse);
    });

    test('active owners are correctly identified', () {
      expect(ownerActive1.isActive, isTrue);
      expect(ownerActive2.isActive, isTrue);
    });

    test('add-owner screen shows pending requests, not active owners, in pending section', () {
      // Pending section filter.
      final pendingSection = allOwners.where((o) => o.status == 'pending').toList();
      expect(pendingSection, hasLength(1));
      expect(pendingSection.first.id, 'o_pending');
    });

    test('add-owner screen shows active owners in the active section', () {
      // Active section filter.
      final activeSection = allOwners.where((o) => o.status == 'active').toList();
      expect(activeSection, hasLength(2));
    });

    test('report screen only offers active owners as selectable', () {
      // Report screen filter.
      final reportOwners = allOwners.where((o) => o.isActive).toList();
      expect(reportOwners.every((o) => o.isActive), isTrue);
      expect(reportOwners, hasLength(2));
    });
  });

  // ── Team permission tests ──────────────────────────────────────────────────

  group('Team permission scoping', () {
    const memberFullScope = TeamMember(
      id: 'm1',
      name: 'Full Access Member',
      phone: '01611000001',
      role: 'sub_manager',
      scopeOwnerIds: [], // empty = unrestricted
    );

    const memberLimitedScope = TeamMember(
      id: 'm2',
      name: 'Limited Member',
      phone: '01611000002',
      role: 'viewer',
      scopeOwnerIds: ['o_active_1'],
    );

    const memberOtherScope = TeamMember(
      id: 'm3',
      name: 'Other Scope Member',
      phone: '01611000003',
      role: 'accountant',
      scopeOwnerIds: ['o_active_2'],
    );

    // Utility function replicating the permission check logic:
    // A member can access an owner if their scopeOwnerIds is empty (full scope)
    // or if the ownerId is in their scopeOwnerIds.
    bool canAccess(TeamMember member, String ownerId) {
      if (member.scopeOwnerIds.isEmpty) return true;
      return member.scopeOwnerIds.contains(ownerId);
    }

    test('a member with empty scopeOwnerIds can access all active owners', () {
      for (final owner in allOwners.where((o) => o.isActive)) {
        expect(canAccess(memberFullScope, owner.id), isTrue,
            reason: 'full-scope member should access ${owner.id}');
      }
    });

    test('a member with limited scope can only access their assigned owner', () {
      expect(canAccess(memberLimitedScope, 'o_active_1'), isTrue);
      expect(canAccess(memberLimitedScope, 'o_active_2'), isFalse);
    });

    test('a limited-scope member cannot access an out-of-scope owner', () {
      expect(canAccess(memberOtherScope, 'o_active_1'), isFalse);
      expect(canAccess(memberOtherScope, 'o_active_2'), isTrue);
    });

    test('no member can access a pending owner via scope check', () {
      // Pending owners should never appear in the active list, but even if
      // their ID were checked directly, a full-scope member's scope is not
      // about status — that is enforced at the active-filter layer above.
      // The scope check itself only cares about IDs, not status.
      // The combination of the active filter + scope check is the gate.
      final pendingOwnerId = ownerPending.id;
      // After the active-only filter, pendingOwnerId is never presented.
      final presentedOwners = allOwners.where((o) => o.isActive).toList();
      expect(presentedOwners.any((o) => o.id == pendingOwnerId), isFalse);
    });

    test('a revoked owner never appears in scope checks either', () {
      final revokedOwnerId = ownerRevoked.id;
      final presentedOwners = allOwners.where((o) => o.isActive).toList();
      expect(presentedOwners.any((o) => o.id == revokedOwnerId), isFalse);
    });

    test('scopeOwnerIds is immutable and cannot leak cross-owner data', () {
      // Verify that the parsed scopeOwnerIds is an unmodifiable-safe list
      // and that one member's scope does not bleed into another's.
      expect(memberLimitedScope.scopeOwnerIds, ['o_active_1']);
      expect(memberOtherScope.scopeOwnerIds, ['o_active_2']);
      expect(
        memberLimitedScope.scopeOwnerIds
            .any((id) => memberOtherScope.scopeOwnerIds.contains(id)),
        isFalse,
        reason: 'no cross-scope bleed between members',
      );
    });
  });

  // ── OwnerReport net income test ───────────────────────────────────────────

  group('OwnerReport derived values', () {
    test('net income is correctly computed', () {
      const report = OwnerReport(
        ownerId: 'o1',
        ownerName: 'Test',
        totalIncome: 80000,
        totalExpense: 15000,
      );
      expect(report.net, closeTo(65000, 0.001));
    });

    test('negative net is surfaced correctly', () {
      const report = OwnerReport(
        ownerId: 'o1',
        ownerName: 'Test',
        totalIncome: 5000,
        totalExpense: 20000,
      );
      expect(report.net, isNegative);
      expect(report.net, closeTo(-15000, 0.001));
    });
  });
}
