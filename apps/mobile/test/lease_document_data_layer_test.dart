import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/leases/data/lease_document_providers.dart';
import 'package:khatir_mobile/features/leases/data/lease_document_repository.dart';
import 'package:khatir_mobile/features/leases/data/models/lease_document.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

/// Builds a [Dio] that intercepts all requests and returns [responseData] with
/// [statusCode]. The interceptor never touches the network.
Dio _mockDio({
  required Object responseData,
  int statusCode = 200,
  bool throwError = false,
  int errorStatusCode = 500,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (throwError) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: errorStatusCode,
                data: <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': errorStatusCode == 402
                        ? 'feature_requires_upgrade'
                        : 'server_error',
                    'detail': 'error',
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
            callFollowups: true,
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: statusCode,
            data: responseData,
          ),
        );
      },
    ),
  );
  return dio;
}

/// Canonical generate response: a draft document with the mandatory disclaimer.
const _generateResponse = <String, dynamic>{
  'id': 'doc-1',
  'lease_id': 'lease-1',
  'status': 'draft',
  'disclaimer': 'This is an AI-generated draft, not legal advice.',
  'pdf_url': '',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'clauses': <dynamic>[
    <String, dynamic>{
      'id': 'parties',
      'title': 'Parties',
      'content': 'Landlord and Tenant agree...',
      'is_required': true,
      'sort_order': 1,
    },
    <String, dynamic>{
      'id': 'disclaimer',
      'title': 'Disclaimer',
      'content': 'This is an AI-generated draft, not legal advice.',
      'is_required': true,
      'sort_order': 999,
    },
  ],
};

void main() {
  group('LeaseDocumentRepository', () {
    test('generateDocument returns LeaseDocument with disclaimer', () async {
      final repo = LeaseDocumentRepository(_mockDio(responseData: _generateResponse, statusCode: 201));
      final doc = await repo.generateDocument('lease-1');
      expect(doc.id, 'doc-1');
      expect(doc.leaseId, 'lease-1');
      expect(doc.status, LeaseDocumentStatus.draft);
      expect(doc.disclaimer, isNotEmpty);
      expect(
        doc.disclaimer,
        contains('not legal advice'),
      );
    });

    test('generateDocument disclaimer present in clauses', () async {
      final repo = LeaseDocumentRepository(_mockDio(responseData: _generateResponse, statusCode: 201));
      final doc = await repo.generateDocument('lease-1');
      final disclaimerClause = doc.clauses.where((c) => c.id == 'disclaimer').firstOrNull;
      expect(disclaimerClause, isNotNull);
      expect(disclaimerClause!.isRequired, isTrue);
    });

    test('updateDocument sends PATCH with clauses', () async {
      String? capturedMethod;
      String? capturedPath;
      Object? capturedBody;

      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedMethod = options.method;
            capturedPath = options.path;
            capturedBody = options.data;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  ..._generateResponse,
                  'id': 'doc-1',
                },
              ),
            );
          },
        ),
      );
      final repo = LeaseDocumentRepository(dio);
      final clauses = [
        const LeaseDocumentClause(
          id: 'parties',
          title: 'Parties',
          content: 'Updated content',
          isRequired: true,
          sortOrder: 1,
        ),
      ];
      await repo.updateDocument('lease-1', clauses);
      expect(capturedMethod, 'PATCH');
      expect(capturedPath, contains('document'));
      final body = capturedBody as Map<String, dynamic>;
      expect(body['clauses'], isA<List>());
      expect((body['clauses'] as List).first['id'], 'parties');
    });

    test('402 from generateDocument throws ApiException with upgrade code', () async {
      final repo = LeaseDocumentRepository(
        _mockDio(
          responseData: <String, dynamic>{},
          throwError: true,
          errorStatusCode: 402,
        ),
      );
      expect(
        () => repo.generateDocument('lease-1'),
        throwsA(
          predicate<ApiException>((e) =>
              e.statusCode == 402 &&
              e.errorCode == 'feature_requires_upgrade'),
        ),
      );
    });

    test('required clauses always present in returned model', () async {
      final repo = LeaseDocumentRepository(_mockDio(responseData: _generateResponse, statusCode: 201));
      final doc = await repo.generateDocument('lease-1');
      final requiredClauses = doc.clauses.where((c) => c.isRequired);
      expect(requiredClauses, isNotEmpty);
      // Disclaimer must always be there.
      expect(
        doc.clauses.any((c) => c.id == 'disclaimer'),
        isTrue,
      );
    });
  });

  group('LeaseDocumentController (provider)', () {
    test('generate() calls repository and updates state', () async {
      final container = ProviderContainer(
        overrides: [
          leaseDocumentRepositoryProvider.overrideWithValue(
            LeaseDocumentRepository(
              _mockDio(responseData: _generateResponse, statusCode: 201),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        leaseDocumentControllerProvider('lease-1').notifier,
      );
      final doc = await controller.generate();
      expect(doc.id, 'doc-1');
      expect(
        container
            .read(leaseDocumentControllerProvider('lease-1'))
            .value
            ?.id,
        'doc-1',
      );
    });

    test('updateClauses() patches clauses and updates state', () async {
      final container = ProviderContainer(
        overrides: [
          leaseDocumentRepositoryProvider.overrideWithValue(
            LeaseDocumentRepository(
              _mockDio(responseData: _generateResponse),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        leaseDocumentControllerProvider('lease-1').notifier,
      );
      final updatedDoc = await controller.updateClauses([
        const LeaseDocumentClause(
          id: 'parties',
          title: 'Parties',
          content: 'New content',
          isRequired: true,
          sortOrder: 1,
        ),
      ]);
      expect(updatedDoc, isA<LeaseDocument>());
    });
  });

  group('LeaseDocument.fromJson', () {
    test('parses list-shaped clauses', () {
      final doc = LeaseDocument.fromJson(_generateResponse);
      expect(doc.clauses.length, 2);
      expect(doc.clauses.first.id, 'parties');
    });

    test('disclaimer field extracted from top-level key', () {
      final doc = LeaseDocument.fromJson(_generateResponse);
      expect(doc.disclaimer, contains('not legal advice'));
    });

    test('status defaults to draft for unknown wire values', () {
      final doc = LeaseDocument.fromJson(<String, dynamic>{
        'id': 'x',
        'status': 'unknown_status',
        'clauses': <dynamic>[],
      });
      expect(doc.status, LeaseDocumentStatus.draft);
    });

    test('LeaseDocumentClause.isRequired parsed correctly', () {
      final clause = LeaseDocumentClause.fromJson(<String, dynamic>{
        'id': 'disclaimer',
        'title': 'Disclaimer',
        'content': 'Not legal advice.',
        'is_required': true,
        'sort_order': 999,
      });
      expect(clause.isRequired, isTrue);
    });

    test('LeaseDocumentClause.toJson round-trips', () {
      const clause = LeaseDocumentClause(
        id: 'rent',
        title: 'Rent',
        content: 'Monthly rent: 25000 BDT',
        isRequired: true,
        sortOrder: 3,
      );
      final json = clause.toJson();
      final restored = LeaseDocumentClause.fromJson(json);
      expect(restored.id, clause.id);
      expect(restored.content, clause.content);
      expect(restored.isRequired, clause.isRequired);
    });
  });
}
