import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/features/manager/data/models/manager_models.dart';

/// Unit tests for the manager data layer (T-010).
///
/// Tests [LinkedOwner], [ManagerDashboard], [TeamMember], and [OwnerReport]
/// model parsing without any network calls.
void main() {
  group('LinkedOwner.fromJson', () {
    test('parses a fully-populated payload', () {
      final json = {
        'id': 'o1',
        'owner_name': 'Karim Saheb',
        'owner_phone': '01711000111',
        'status': 'active',
        'unit_count': 10,
        'occupied_count': 8,
        'monthly_rent': '45000.00',
        'avatar_color': '#3A7D44',
      };
      final owner = LinkedOwner.fromJson(json);
      expect(owner.id, 'o1');
      expect(owner.ownerName, 'Karim Saheb');
      expect(owner.ownerPhone, '01711000111');
      expect(owner.status, 'active');
      expect(owner.unitCount, 10);
      expect(owner.occupiedCount, 8);
      expect(owner.monthlyRent, 45000.0);
      expect(owner.avatarColor, '#3A7D44');
      expect(owner.isActive, isTrue);
    });

    test('defaults status to pending when missing', () {
      final json = {'id': 'o2', 'owner_name': 'Rahim', 'owner_phone': '01811000222'};
      final owner = LinkedOwner.fromJson(json);
      expect(owner.status, 'pending');
      expect(owner.isActive, isFalse);
    });

    test('parses numeric rent (int wire value)', () {
      final json = {
        'id': 'o3',
        'owner_name': 'Test',
        'owner_phone': '01911000333',
        'status': 'active',
        'monthly_rent': 30000,
      };
      final owner = LinkedOwner.fromJson(json);
      expect(owner.monthlyRent, 30000.0);
    });
  });

  group('ManagerDashboard.fromJson', () {
    test('parses totals and embedded owners list', () {
      final json = {
        'total_monthly_rent': '120000.00',
        'occupied_units': 15,
        'total_units': 20,
        'collection_rate': '0.90',
        'owner_count': 3,
        'owners': [
          {'id': 'o1', 'owner_name': 'A', 'owner_phone': '01711000001', 'status': 'active'},
          {'id': 'o2', 'owner_name': 'B', 'owner_phone': '01711000002', 'status': 'pending'},
        ],
      };
      final dash = ManagerDashboard.fromJson(json);
      expect(dash.totalMonthlyRent, 120000.0);
      expect(dash.occupiedUnits, 15);
      expect(dash.totalUnits, 20);
      expect(dash.collectionRate, 0.9);
      expect(dash.ownerCount, 3);
      expect(dash.owners, hasLength(2));
      expect(dash.occupancyRate, closeTo(0.75, 0.001));
    });

    test('occupancyRate is 0 when totalUnits is 0', () {
      const dash = ManagerDashboard();
      expect(dash.occupancyRate, 0.0);
    });
  });

  group('TeamMember.fromJson', () {
    test('parses a team member with scoped access', () {
      final json = {
        'id': 'm1',
        'name': 'Abir Hasan',
        'phone': '01611000444',
        'role': 'accountant',
        'scope_owner_ids': ['o1', 'o2'],
      };
      final member = TeamMember.fromJson(json);
      expect(member.id, 'm1');
      expect(member.name, 'Abir Hasan');
      expect(member.role, 'accountant');
      expect(member.scopeOwnerIds, ['o1', 'o2']);
    });

    test('defaults role to viewer and scopeOwnerIds to empty', () {
      final json = {'id': 'm2', 'name': 'Viewer', 'phone': '01511000555'};
      final member = TeamMember.fromJson(json);
      expect(member.role, 'viewer');
      expect(member.scopeOwnerIds, isEmpty);
    });
  });

  group('OwnerReport.fromJson', () {
    test('parses all fields including pdfUrl', () {
      final json = {
        'owner_id': 'o1',
        'owner_name': 'Karim Saheb',
        'total_income': '85000.00',
        'total_expense': '12000.00',
        'collection_rate': '0.92',
        'occupied_units': 8,
        'total_units': 10,
        'pdf_url': 'https://cdn.example.com/report.pdf',
      };
      final report = OwnerReport.fromJson(json);
      expect(report.ownerId, 'o1');
      expect(report.ownerName, 'Karim Saheb');
      expect(report.totalIncome, 85000.0);
      expect(report.totalExpense, 12000.0);
      expect(report.net, closeTo(73000.0, 0.001));
      expect(report.collectionRate, closeTo(0.92, 0.001));
      expect(report.pdfUrl, 'https://cdn.example.com/report.pdf');
    });

    test('pdfUrl defaults to null before generation', () {
      final json = {'owner_id': 'o2', 'owner_name': 'Test'};
      final report = OwnerReport.fromJson(json);
      expect(report.pdfUrl, isNull);
    });
  });
}
