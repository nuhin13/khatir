// Compliance tests for EPIC-18 AI lease (T-010).
//
// Asserts:
//  1. Disclaimer text is present in the document screen (draft state).
//  2. Disclaimer text is present in the PDF preview screen.
//  3. Free-tier users (402 on generate) see the blocked / tier-gated state.
//  4. Required clauses are always rendered as locked (no delete action).
//  5. Feature flag off → flag-off state shown after tapping generate.
//
// ignore_for_file: avoid_redundant_argument_values

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/leases/data/lease_document_providers.dart';
import 'package:khatir_mobile/features/leases/data/lease_document_repository.dart';
import 'package:khatir_mobile/features/leases/data/models/lease_document.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_clause_screen.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_document_screen.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_pdf_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Constants & shared data ───────────────────────────────────────────────────

const _kLeaseId = 'lease-1';

/// Canonical disclaimer substring that must always be visible.
const _kDisclaimerSubstring = 'not legal advice';

/// A lease document with the required disclaimer plus two clauses
/// (one required, one optional).
final _kDoc = LeaseDocument(
  id: 'doc-1',
  leaseId: _kLeaseId,
  status: LeaseDocumentStatus.draft,
  disclaimer: 'This is an AI-generated draft, $_kDisclaimerSubstring.',
  pdfUrl: '',
  clauses: [
    const LeaseDocumentClause(
      id: 'parties',
      title: 'Parties',
      content: 'Landlord and Tenant agree…',
      isRequired: true,
      sortOrder: 1,
    ),
    const LeaseDocumentClause(
      id: 'optional',
      title: 'Special terms',
      content: 'No pets allowed.',
      isRequired: false,
      sortOrder: 2,
    ),
  ],
);

// ── In-memory locale storage fake ────────────────────────────────────────────

class _FakeStorage extends FlutterSecureStorage {
  _FakeStorage() : super();
  final Map<String, String> _m = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _m[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) _m.remove(key); else _m[key] = value;
  }
}

// ── Minimal Dio factory (never hits network) ──────────────────────────────────

Dio _fakeDio() => Dio(BaseOptions(baseUrl: 'http://test'));

// ── Fake lease-document repository ───────────────────────────────────────────

/// Configurable stub repository used by all compliance tests.
class _FakeRepo extends LeaseDocumentRepository {
  _FakeRepo({
    this.docResult,
    this.getDocResult,
    this.pdfBytes,
  }) : super(_fakeDio());

  /// Result of [getDocument] — defaults to [_kDoc] if null.
  final LeaseDocument? getDocResult;

  /// Result of [generateDocument] — if null, returns [_kDoc].
  /// Set to an [ApiException] to simulate 402/403.
  final Object? docResult;

  /// Bytes returned by [getDocumentPdfBytes].
  final Uint8List? pdfBytes;

  @override
  Future<LeaseDocument> getDocument(String leaseId) async =>
      getDocResult ?? _kDoc;

  @override
  Future<LeaseDocument> generateDocument(String leaseId) async {
    final r = docResult;
    if (r is Exception) throw r;
    return r is LeaseDocument ? r : _kDoc;
  }

  @override
  Future<LeaseDocument> updateDocument(
    String leaseId,
    List<LeaseDocumentClause> clauses,
  ) async =>
      _kDoc.copyWith(clauses: clauses);

  @override
  Future<Uint8List> getDocumentPdfBytes(String leaseId) async =>
      pdfBytes ?? Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]);
}

// ── Controller fakes ──────────────────────────────────────────────────────────

/// A controller that immediately resolves to [doc].
class _DocController extends LeaseDocumentController {
  _DocController(this._doc);
  final LeaseDocument _doc;

  @override
  Future<LeaseDocument> build(String leaseId) async => _doc;
}

/// A controller whose [build] throws 404 — simulates no existing document so
/// the screen's [_tryLoadExisting] stays in intro state.
class _NotFoundController extends LeaseDocumentController {
  @override
  Future<LeaseDocument> build(String leaseId) async {
    throw const ApiException(
      message: 'Not found',
      statusCode: 404,
      errorCode: 'not_found',
    );
  }
}

// ── Harness builders ──────────────────────────────────────────────────────────

/// Wraps [child] with a [ProviderScope] + [MaterialApp] that supports
/// localisation and overrides the given providers.
Widget _wrap(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      localeStorageProvider.overrideWithValue(_FakeStorage()),
      ...overrides,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        return MaterialApp(
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        );
      },
    ),
  );
}

/// [LeaseDocumentScreen] harness, routed via [GoRouter] (screen needs a
/// [GoRouter] for canPop / go navigation calls).
Widget _docScreenHarness({
  _FakeRepo? repo,
  LeaseDocumentController Function()? controllerFactory,
  PublicConfig config = const PublicConfig(
    flags: {'ai_lease_enabled': true},
  ),
}) {
  final r = repo ?? _FakeRepo();

  final router = GoRouter(
    initialLocation: LeaseDocumentScreen.pathFor(_kLeaseId),
    routes: [
      GoRoute(
        path: LeaseDocumentScreen.pathFor(':id'),
        name: LeaseDocumentScreen.routeName,
        builder: (context, state) => LeaseDocumentScreen(
          leaseId: state.pathParameters['id'] ?? '',
        ),
      ),
      // Stub for push target so GoRouter can resolve the clause route.
      GoRoute(
        path: LeaseClauseScreen.pathFor(':id'),
        name: LeaseClauseScreen.routeName,
        builder: (context, state) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        path: LeasePdfScreen.pathFor(':id'),
        name: LeasePdfScreen.routeName,
        builder: (context, state) => const Scaffold(body: SizedBox()),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      localeStorageProvider.overrideWithValue(_FakeStorage()),
      leaseDocumentRepositoryProvider.overrideWithValue(r),
      if (controllerFactory != null)
        leaseDocumentControllerProvider.overrideWith(controllerFactory),
      publicConfigProvider.overrideWith((ref) async => config),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        return MaterialApp.router(
          routerConfig: router,
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  // ── 1. Disclaimer in document screen ─────────────────────────────────────

  group('T-010 — disclaimer in lease document screen', () {
    testWidgets('disclaimer banner widget is present in draft state',
        (tester) async {
      // The repo returns _kDoc on getDocument → screen goes to draft.
      await tester.pumpWidget(_docScreenHarness(
        repo: _FakeRepo(),
        controllerFactory: () => _DocController(_kDoc),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('leaseDisclaimer')),
        findsOneWidget,
        reason: 'Disclaimer banner must always be visible in draft state',
      );
    });

    testWidgets('disclaimer banner contains "not legal advice"', (tester) async {
      await tester.pumpWidget(_docScreenHarness(
        repo: _FakeRepo(),
        controllerFactory: () => _DocController(_kDoc),
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(_kDisclaimerSubstring, findRichText: true),
        findsAtLeast(1),
        reason: 'Disclaimer must mention "not legal advice"',
      );
    });
  });

  // ── 2. Disclaimer in PDF preview screen ──────────────────────────────────

  group('T-010 — disclaimer in PDF preview screen', () {
    setUp(() {
      // Override the static PDF renderer so headless tests never touch pdfium.
      LeasePdfScreen.pdfViewBuilder =
          (bytes) => SizedBox(key: const ValueKey('pdfStub'));
    });

    testWidgets('disclaimer banner widget present in PDF screen',
        (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _wrap(
          LeasePdfScreen(
            leaseId: _kLeaseId,
            pdfViewBuilder: (_) => const SizedBox(key: ValueKey('pdfStub')),
          ),
          overrides: [
            leaseDocumentRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('leasePdfDisclaimer')),
        findsOneWidget,
        reason: 'Disclaimer banner must be present on the PDF preview screen',
      );
    });

    testWidgets('PDF disclaimer contains "not legal advice"', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _wrap(
          LeasePdfScreen(
            leaseId: _kLeaseId,
            pdfViewBuilder: (_) => const SizedBox(key: ValueKey('pdfStub')),
          ),
          overrides: [
            leaseDocumentRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(_kDisclaimerSubstring, findRichText: true),
        findsAtLeast(1),
        reason: 'Disclaimer must mention "not legal advice" in PDF screen',
      );
    });
  });

  // ── 3. Required clauses locked ────────────────────────────────────────────

  group('T-010 — required clauses rendered as locked', () {
    testWidgets('required clause shows required badge (clause screen)',
        (tester) async {
      final router = GoRouter(
        initialLocation: LeaseClauseScreen.pathFor(_kLeaseId),
        routes: [
          GoRoute(
            path: LeaseClauseScreen.pathFor(':id'),
            name: LeaseClauseScreen.routeName,
            builder: (context, state) => LeaseClauseScreen(
              leaseId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeStorageProvider.overrideWithValue(_FakeStorage()),
            leaseDocumentRepositoryProvider.overrideWithValue(_FakeRepo()),
            leaseDocumentControllerProvider.overrideWith(
              () => _DocController(_kDoc),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return MaterialApp.router(
                routerConfig: router,
                locale: locale,
                supportedLocales: kSupportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Required clause tile must be present.
      expect(
        find.byKey(const ValueKey('leaseClause_parties')),
        findsOneWidget,
        reason: 'Required clause must be rendered',
      );
    });

    testWidgets('required clause has no delete button', (tester) async {
      final router = GoRouter(
        initialLocation: LeaseClauseScreen.pathFor(_kLeaseId),
        routes: [
          GoRoute(
            path: LeaseClauseScreen.pathFor(':id'),
            name: LeaseClauseScreen.routeName,
            builder: (context, state) => LeaseClauseScreen(
              leaseId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeStorageProvider.overrideWithValue(_FakeStorage()),
            leaseDocumentRepositoryProvider.overrideWithValue(_FakeRepo()),
            leaseDocumentControllerProvider.overrideWith(
              () => _DocController(_kDoc),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return MaterialApp.router(
                routerConfig: router,
                locale: locale,
                supportedLocales: kSupportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No delete button for the required clause.
      expect(
        find.byKey(const ValueKey('deleteClause_parties')),
        findsNothing,
        reason: 'Required clause must NOT have a delete button',
      );
    });

    testWidgets('optional clause has a delete button', (tester) async {
      final router = GoRouter(
        initialLocation: LeaseClauseScreen.pathFor(_kLeaseId),
        routes: [
          GoRoute(
            path: LeaseClauseScreen.pathFor(':id'),
            name: LeaseClauseScreen.routeName,
            builder: (context, state) => LeaseClauseScreen(
              leaseId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeStorageProvider.overrideWithValue(_FakeStorage()),
            leaseDocumentRepositoryProvider.overrideWithValue(_FakeRepo()),
            leaseDocumentControllerProvider.overrideWith(
              () => _DocController(_kDoc),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return MaterialApp.router(
                routerConfig: router,
                locale: locale,
                supportedLocales: kSupportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Optional clause MUST have a delete button.
      expect(
        find.byKey(const ValueKey('deleteClause_optional')),
        findsOneWidget,
        reason: 'Optional clause must have a delete button',
      );
    });

    testWidgets(
        'required clause badge visible in document screen draft preview',
        (tester) async {
      await tester.pumpWidget(_docScreenHarness(
        repo: _FakeRepo(),
        controllerFactory: () => _DocController(_kDoc),
      ));
      await tester.pumpAndSettle();

      // The draft state shows the first 3 clause preview tiles; the required
      // clause badge must be visible for the 'parties' clause.
      expect(
        find.text(l10n.lease_clause_required),
        findsAtLeast(1),
        reason: 'Required badge must appear in the draft clause preview',
      );
    });
  });

  // ── 4. Free-tier blocked state ────────────────────────────────────────────

  group('T-010 — free-tier users see tier-gated state on generate', () {
    testWidgets('tier-gated key visible when generate throws 402',
        (tester) async {
      // Repo: getDocument → 404 (no existing doc, stay in intro).
      //       generateDocument → 402 (free-tier blocked).
      final tierRepo = _FakeRepo(
        getDocResult: null, // will throw 404 override below
        docResult: const ApiException(
          message: 'feature_requires_upgrade',
          statusCode: 402,
          errorCode: 'feature_requires_upgrade',
        ),
      );

      // We need getDocument to throw 404 so screen starts in intro.
      // _FakeRepo returns _kDoc by default; use a subclass to override.
      final notFoundIntroRepo = _NotFoundGetRepo(
        generateError: const ApiException(
          message: 'feature_requires_upgrade',
          statusCode: 402,
          errorCode: 'feature_requires_upgrade',
        ),
      );

      await tester.pumpWidget(_docScreenHarness(
        repo: notFoundIntroRepo,
        controllerFactory: () => _NotFoundController(),
      ));
      await tester.pumpAndSettle();

      // Should be in intro state — find and tap generate.
      final generateBtn = find.byKey(const ValueKey('leaseDocGenerate'));
      expect(generateBtn, findsOneWidget,
          reason: 'Generate button must be present in intro state');
      await tester.tap(generateBtn);
      await tester.pump(); // start the async
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // After 402, the screen shows tier-gated state.
      expect(
        find.byKey(const ValueKey('leaseDocTierGated')),
        findsOneWidget,
        reason: 'Free-tier blocked state must be shown after 402',
      );
    });
  });

  // ── 5. Feature flag off ───────────────────────────────────────────────────

  group('T-010 — feature flag ai_lease_enabled=false', () {
    testWidgets('flag-off state shown after tapping generate when flag=false',
        (tester) async {
      final notFoundRepo = _NotFoundGetRepo(generateError: null);

      await tester.pumpWidget(_docScreenHarness(
        repo: notFoundRepo,
        controllerFactory: () => _NotFoundController(),
        config: const PublicConfig(flags: {'ai_lease_enabled': false}),
      ));
      await tester.pumpAndSettle();

      final generateBtn = find.byKey(const ValueKey('leaseDocGenerate'));
      expect(generateBtn, findsOneWidget);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('leaseDocFlagOff')),
        findsOneWidget,
        reason: 'Flag-off state must be shown when ai_lease_enabled=false',
      );
    });
  });
}

// ── Helper: repo where getDocument throws 404 ─────────────────────────────────

class _NotFoundGetRepo extends LeaseDocumentRepository {
  _NotFoundGetRepo({this.generateError}) : super(_fakeDio());

  final Exception? generateError;

  @override
  Future<LeaseDocument> getDocument(String leaseId) async {
    throw const ApiException(
      message: 'Not found',
      statusCode: 404,
      errorCode: 'not_found',
    );
  }

  @override
  Future<LeaseDocument> generateDocument(String leaseId) async {
    final e = generateError;
    if (e != null) throw e;
    return _kDoc;
  }

  @override
  Future<LeaseDocument> updateDocument(
    String leaseId,
    List<LeaseDocumentClause> clauses,
  ) async =>
      _kDoc;

  @override
  Future<Uint8List> getDocumentPdfBytes(String leaseId) async =>
      Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]);
}
