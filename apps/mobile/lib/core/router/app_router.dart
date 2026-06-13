import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show GlobalKey, NavigatorState;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/presentation/screens/otp_entry_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/billing/presentation/screens/plan_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dmpform/presentation/screens/dmp_pdf_screen.dart';
import '../../features/dmpform/presentation/screens/dmp_preview_screen.dart';
import '../../features/leases/presentation/screens/lease_clause_screen.dart';
import '../../features/leases/presentation/screens/lease_detail_screen.dart';
import '../../features/leases/presentation/screens/lease_document_screen.dart';
import '../../features/leases/presentation/screens/lease_form_screen.dart';
import '../../features/leases/presentation/screens/lease_list_screen.dart';
import '../../features/leases/presentation/screens/lease_pdf_screen.dart';
import '../../features/maintenance/presentation/screens/add_expense_screen.dart';
import '../../features/maintenance/presentation/screens/expenses_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_queue_screen.dart';
import '../../features/manager/presentation/screens/mgr_add_owner_screen.dart';
import '../../features/manager/presentation/screens/mgr_home_screen.dart';
import '../../features/manager/presentation/screens/mgr_report_screen.dart';
import '../../features/manager/presentation/screens/mgr_team_screen.dart';
import '../../features/onboarding/data/onboarding_prefs.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/more_screen.dart';
import '../../features/properties/presentation/screens/landlord_home_screen.dart';
import '../../features/properties/presentation/screens/portfolio_screen.dart';
import '../../features/properties/presentation/screens/unit_detail_screen.dart';
import '../../features/properties/presentation/wizard/wizard_host.dart';
import '../../features/rent/presentation/screens/receipt_screen.dart';
import '../../features/rent/presentation/screens/rent_request_screen.dart';
import '../../features/rent/presentation/screens/verify_payment_screen.dart';
import '../../features/verification/presentation/screens/verify_screen.dart';
import '../../features/role/presentation/screens/role_chooser_screen.dart';
import '../../features/shell/landlord_shell.dart';
import '../../features/shell/manager_shell.dart';
import '../../features/shell/tenant_shell.dart';
import '../../features/shell/widgets/shell_placeholder.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tenant/presentation/screens/ten_home_screen.dart';
import '../../features/tenant/presentation/screens/ten_lease_screen.dart';
import '../../features/tenant/presentation/screens/ten_maint_screen.dart';
import '../../features/tenant/presentation/screens/ten_pay_screen.dart';
import '../../features/tenant/presentation/screens/ten_receipts_screen.dart';
import '../../features/tenant/presentation/screens/ten_record_screen.dart';
import '../../features/tenants/presentation/screens/add_tenant_screen.dart';
import '../../features/tenants/presentation/screens/manual_tenant_screen.dart';
import '../../features/tenants/presentation/screens/ocr_capture_screen.dart';
import '../../features/tenants/presentation/screens/ocr_review_args.dart';
import '../../features/tenants/presentation/screens/ocr_review_screen.dart';
import '../../features/tenants/presentation/screens/voice_fill_screen.dart';
import '../../features/warnings/presentation/screens/warning_notice_screen.dart';
import '../../features/warnings/presentation/screens/warning_screen.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../enums/role.dart';
import 'args/auth_args.dart';

/// Root navigator key so full-screen routes (pushed above the shells, e.g. the
/// add-tenant flow) sit on the root navigator rather than inside a branch.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The shell-home path each self-selectable role lands on. The redirect (T-008)
/// uses this both as the destination for an authenticated user with a role and
/// as the "own shell" a user is bounced back to when they wander into another
/// role's shell. `caretaker`/`admin` are not phone-app self-roles, so they map
/// to the landlord shell as a safe default.
String _shellHomeFor(Role role) => switch (role) {
      Role.landlord => '/landlord/home',
      Role.manager => '/manager/home',
      Role.tenant => '/tenant/home',
      Role.caretaker => '/landlord/home',
      Role.admin => '/landlord/home',
    };

/// The shell-path prefix that a given role is allowed to be inside. Used to
/// detect wrong-role shell access and bounce the user to their own shell.
String _shellPrefixFor(Role role) => switch (role) {
      Role.landlord => '/landlord',
      Role.manager => '/manager',
      Role.tenant => '/tenant',
      Role.caretaker => '/landlord',
      Role.admin => '/landlord',
    };

/// All role-shell prefixes, used to tell "is this location inside *some* shell?"
const List<String> _allShellPrefixes = ['/landlord', '/manager', '/tenant'];

/// Builds a single shell branch: a [StatefulShellBranch] with one [GoRoute]
/// whose body is a [KShellPlaceholder] until its feature epic fills it in.
/// [label] resolves the tab name from localizations at build time.
StatefulShellBranch _placeholderBranch({
  required String path,
  required String name,
  required String Function(AppLocalizations) label,
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        name: name,
        builder: (context, state) =>
            KShellPlaceholder(tabLabel: label(AppLocalizations.of(context))),
      ),
    ],
  );
}

/// Builds the More-tab branch for a shell: a single [GoRoute] rendering the
/// shared [MoreScreen] adapted to [role] (tenants get the simpler list). The
/// More menu (T-007) is real now, so this branch is not a placeholder.
StatefulShellBranch _moreBranch({
  required String path,
  required String name,
  required Role role,
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        name: name,
        builder: (context, state) => MoreScreen.forRole(role),
      ),
    ],
  );
}

/// Resolves the "has the user seen onboarding?" flag once and exposes it as an
/// [AsyncValue] the router redirect reads. Kept separate from the auth state so
/// the splash → onboarding decision has a single source of truth.
final onboardingSeenProvider = FutureProvider<bool>(
  (ref) => ref.watch(onboardingPrefsProvider).hasSeenOnboarding(),
);

/// Bridges Riverpod providers to a [Listenable] so go_router re-evaluates its
/// `redirect` whenever auth state or the onboarding flag changes (login,
/// logout, bootstrap completion). This is the `refreshListenable` the router
/// uses instead of scattering navigation across screens.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _subs = [
      _ref.listen(authControllerProvider, (_, _) => notifyListeners()),
      _ref.listen(onboardingSeenProvider, (_, _) => notifyListeners()),
    ];
  }

  final Ref _ref;
  late final List<ProviderSubscription<Object?>> _subs;

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    super.dispose();
  }
}

/// ALL go_router routes live here. The redirect implements the EPIC-02 role
/// decision table (T-008), extending the EPIC-01 seam (T-012):
///   - auth/onboarding still resolving (unknown) → stay on splash
///   - onboarding not seen → /onboarding
///   - seen + unauthenticated → /auth/phone
///   - authenticated, no role → /role
///   - authenticated, role set → that role's shell home
///   - authenticated, inside another role's shell → bounce to own shell home
///   - /role is always reachable when authenticated (switch-role from More), so
///     a user with a role is never force-redirected away from it.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.routePath,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authAsync = ref.read(authControllerProvider);
      final seenAsync = ref.read(onboardingSeenProvider);

      // Still bootstrapping the session or reading the onboarding flag: hold on
      // the splash so there is no flicker/loop while state resolves.
      if (authAsync.isLoading || seenAsync.isLoading) {
        return state.matchedLocation == SplashScreen.routePath
            ? null
            : SplashScreen.routePath;
      }

      final status =
          authAsync.value?.status ?? AuthStatus.unauthenticated;
      final seen = seenAsync.value ?? false;
      final loc = state.matchedLocation;

      // First launch: route to onboarding until it has been seen.
      if (!seen) {
        return loc == OnboardingScreen.routePath
            ? null
            : OnboardingScreen.routePath;
      }

      final atAuth = loc == PhoneEntryScreen.routePath ||
          loc == OtpEntryScreen.routePath;

      if (status == AuthStatus.authenticated) {
        final role = authAsync.value?.role;

        // Authenticated but no role yet → the role chooser is the only valid
        // place to be.
        if (role == null) {
          return loc == RoleChooserScreen.routePath
              ? null
              : RoleChooserScreen.routePath;
        }

        final home = _shellHomeFor(role);

        // Leaving the pre-shell flows (splash/onboarding/auth) → role home.
        if (loc == SplashScreen.routePath ||
            loc == OnboardingScreen.routePath ||
            atAuth) {
          return home;
        }

        // The role chooser stays reachable for an authenticated user so they
        // can switch role from More; never bounce them off it.
        if (loc == RoleChooserScreen.routePath) {
          return null;
        }

        // Inside a role shell that is not this user's → bounce to own shell.
        final ownPrefix = _shellPrefixFor(role);
        final inAnotherShell = _allShellPrefixes.any(
          (prefix) =>
              prefix != ownPrefix &&
              (loc == prefix || loc.startsWith('$prefix/')),
        );
        if (inAnotherShell) {
          return home;
        }

        // Own shell or any other top-level route (e.g. /tenants/add) is fine.
        return null;
      }

      // Seen + unauthenticated: must be in the auth flow.
      return atAuth ? null : PhoneEntryScreen.routePath;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        // Real phone-entry screen (T-009).
        path: PhoneEntryScreen.routePath,
        name: PhoneEntryScreen.routeName,
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        // OTP-entry screen (T-010). Reads the typed AuthArgs passed via
        // `extra` from phone-entry.
        path: OtpEntryScreen.routePath,
        name: OtpEntryScreen.routeName,
        builder: (context, state) =>
            OtpEntryScreen(args: state.extra as AuthArgs?),
      ),
      GoRoute(
        // Role chooser (T-005): a verified user with no role declares one here.
        // The redirect that *sends* users here is wired in T-008; this task
        // only registers the route + screen.
        path: RoleChooserScreen.routePath,
        name: RoleChooserScreen.routeName,
        builder: (context, state) => const RoleChooserScreen(),
      ),

      // ── Landlord shell (T-004) ─────────────────────────────────────────
      // Four indexed-stack branches; the center "Add" nav action pushes
      // `/tenants/add` and is NOT a branch (see LandlordShell).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            LandlordShell(navigationShell: navigationShell),
        branches: [
          // Landlord home (T-009): greeting + DMP CTA + portfolio summary.
          // Charts/late-payers land in EPIC-09/07.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/landlord/home',
                name: 'landlordHome',
                builder: (context, state) => const LandlordHomeScreen(),
              ),
            ],
          ),
          // Landlord dashboard / charts (EPIC-09 T-006): collection bar chart,
          // occupancy donut, income-vs-expense trend, top expenses, late payers.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DashboardScreen.routePath,
                name: DashboardScreen.routeName,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          _placeholderBranch(
            // TODO(EPIC-07) replace with rent collection.
            path: '/landlord/rent',
            name: 'landlordRent',
            label: (l) => l.nav_rent,
          ),
          _moreBranch(
            // More menu (T-007).
            path: '/landlord/more',
            name: 'landlordMore',
            role: Role.landlord,
          ),
        ],
      ),

      // ── Manager shell (EPIC-22) — real screens wired by T-011 ─────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ManagerShell(navigationShell: navigationShell),
        branches: [
          // Manager home (T-006): consolidated multi-owner portfolio.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/manager/home',
                name: 'managerHome',
                builder: (context, state) => const MgrHomeScreen(),
                routes: [
                  // Add-owner (T-007): link a new owner / view pending.
                  GoRoute(
                    path: MgrAddOwnerScreen.routePath,
                    name: MgrAddOwnerScreen.routeName,
                    builder: (context, state) => const MgrAddOwnerScreen(),
                  ),
                  // Team (T-008): manage team members.
                  GoRoute(
                    path: MgrTeamScreen.routePath,
                    name: MgrTeamScreen.routeName,
                    builder: (context, state) => const MgrTeamScreen(),
                  ),
                  // Report (T-009): generate + share per-owner PDF report.
                  GoRoute(
                    path: MgrReportScreen.routePath,
                    name: MgrReportScreen.routeName,
                    builder: (context, state) => const MgrReportScreen(),
                  ),
                ],
              ),
            ],
          ),
          _placeholderBranch(
            // Manager dashboard — future EPIC.
            path: '/manager/dashboard',
            name: 'managerDashboard',
            label: (l) => l.nav_charts,
          ),
          _placeholderBranch(
            // Manager rent across owners — future EPIC.
            path: '/manager/rent',
            name: 'managerRent',
            label: (l) => l.nav_rent,
          ),
          _moreBranch(
            // More menu (T-007) — manager sees the full landlord-like list.
            path: '/manager/more',
            name: 'managerMore',
            role: Role.manager,
          ),
        ],
      ),

      // ── Tenant shell (EPIC-19 T-012) — real screens wired ───────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TenantShell(navigationShell: navigationShell),
        branches: [
          // Tenant home (T-005): rent status, quick actions, lease summary,
          // recent receipts, star record promo.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TenHomeScreen.routePath,
                name: TenHomeScreen.routeName,
                builder: (context, state) => const TenHomeScreen(),
                routes: [
                  // Lease view (T-006): read-only lease details + optional
                  // AI lease PDF link. Nested under home so back returns home.
                  GoRoute(
                    path: 'lease',
                    name: TenLeaseScreen.routeName,
                    builder: (context, state) => const TenLeaseScreen(),
                  ),
                  // Pay screen (T-007): amount due, bKash/Nagad instructions,
                  // submit proof (screenshot / txn id / note).
                  GoRoute(
                    path: 'pay',
                    name: TenPayScreen.routeName,
                    builder: (context, state) => const TenPayScreen(),
                  ),
                  // Record / rating (T-010): private star rating + notes +
                  // consent toggle. STRICTLY PRIVATE.
                  GoRoute(
                    path: 'record',
                    name: TenRecordScreen.routeName,
                    builder: (context, state) => const TenRecordScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Maintenance report (T-008): category, description, optional photo.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TenMaintScreen.routePath,
                name: TenMaintScreen.routeName,
                builder: (context, state) => const TenMaintScreen(),
              ),
            ],
          ),
          // Receipts list (T-009): paginated paid-period receipts.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TenReceiptsScreen.routePath,
                name: TenReceiptsScreen.routeName,
                builder: (context, state) => const TenReceiptsScreen(),
              ),
            ],
          ),
          _moreBranch(
            // More menu (T-007) — tenant gets the simpler list (no lease /
            // warnings rows).
            path: '/tenant/more',
            name: 'tenantMore',
            role: Role.tenant,
          ),
        ],
      ),

      // ── Add-tenant flow (EPIC-04) ───────────────────────────────────────
      // Center "Add" action target for the landlord/manager nav, and the
      // unit-detail "Add tenant" CTA. The method chooser (T-009) routes to the
      // OCR / voice / manual sub-flows, carrying the optional target unit id as
      // a `?unit=` query parameter. The three method screens themselves land in
      // later EPIC-04 tasks (OCR T-010/T-011, voice T-012, manual T-013); they
      // are registered as placeholders here so the chooser routes resolve.
      GoRoute(
        path: AddTenantScreen.routePath,
        name: AddTenantScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AddTenantScreen(unitId: state.uri.queryParameters['unit']),
        routes: [
          GoRoute(
            // NID OCR capture (T-010): camera/gallery → upload → review.
            path: OcrCaptureScreen.routePath,
            name: AddTenantScreen.ocrRouteName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => OcrCaptureScreen(
              unitId: state.uri.queryParameters['unit'],
            ),
            routes: [
              GoRoute(
                // OCR review/edit (T-011): the capture screen (T-010)
                // navigates here with typed [OcrReviewArgs] via `extra` on a
                // successful extraction. A direct/deep visit without args is
                // not a valid state, so fall back to the capture screen.
                //
                // The screen runs the shared save+route action (T-016) on
                // proceed: leaving `onProceed` null makes it persist the
                // reviewed tenant and route to the DMP form. This is also the
                // voice path's convergence point (T-012 reuses this screen).
                path: OcrReviewArgs.routePath,
                name: OcrReviewArgs.routeName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final args = state.extra;
                  if (args is! OcrReviewArgs) {
                    return OcrCaptureScreen(
                      unitId: state.uri.queryParameters['unit'],
                    );
                  }
                  return OcrReviewScreen(args: args);
                },
              ),
            ],
          ),
          GoRoute(
            // Voice tenant entry (T-012): record → upload → reuse OCR review.
            // Flag-gated at the chooser (T-009); the screen also defends the
            // `voice_tenant_entry` flag against a direct deep link.
            path: VoiceFillScreen.routePath,
            name: AddTenantScreen.voiceRouteName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => VoiceFillScreen(
              unitId: state.uri.queryParameters['unit'],
            ),
          ),
          GoRoute(
            // Manual tenant entry (T-013): the fallback hand-entry form that
            // fills every DMP field by hand, carrying the optional unit context.
            // Leaving `onProceed` null makes the screen run the shared save+route
            // action (T-016): persist the tenant and route to the DMP form.
            path: ManualTenantScreen.routePath,
            name: AddTenantScreen.manualRouteName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ManualTenantScreen(
              unitId: state.uri.queryParameters['unit'],
            ),
          ),
        ],
      ),

      // ── DMP form preview (EPIC-05 T-007) ────────────────────────────────
      // The convergent success destination of the add-tenant flow: all three
      // intake paths (OCR / voice / manual) save the tenant then route here at
      // `/dmpform/{tenantId}`. This is the real preview screen (replacing the
      // EPIC-04 placeholder): it loads the assembled, masked-NID form data and
      // offers "Generate PDF" → the PDF screen (T-008, nested `/pdf` below) and
      // "Edit" → back to the tenant flow. Sits on the root navigator so it
      // covers the shell. The route name is unchanged (`dmpForm`) so the save
      // action (T-016) keeps routing here.
      GoRoute(
        path: '/dmpform/:tenantId',
        name: DmpPreviewScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => DmpPreviewScreen(
          tenantId: state.pathParameters['tenantId'] ?? '',
        ),
        routes: [
          GoRoute(
            // DMP PDF preview + share (T-008): the "Generate PDF" action lands
            // here at `/dmpform/{tenantId}/pdf`. Generates the police-form PDF,
            // renders it, and offers Download + WhatsApp/system share. This is
            // the real screen (replacing the EPIC-05 T-007 placeholder).
            path: 'pdf',
            name: DmpPdfScreen.routeName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => DmpPdfScreen(
              tenantId: state.pathParameters['tenantId'] ?? '',
            ),
          ),
        ],
      ),

      // ── Lease create / edit (EPIC-06 T-008) ─────────────────────────────
      // Launched from unit detail in unit context: the target unit id is
      // carried as a `?unit=` query parameter (same convention as the
      // add-tenant flow). `/lease/new` creates a draft (optionally activating
      // it); `/lease/:id/edit` edits an existing draft's terms. Both sit on the
      // root navigator so they cover the shell, and pop back to the unit on
      // save so its lease section re-renders (T-009).
      GoRoute(
        path: LeaseFormScreen.routePath,
        name: LeaseFormScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeaseFormScreen(
          unitId: state.uri.queryParameters['unit'] ?? '',
        ),
      ),
      GoRoute(
        path: LeaseFormScreen.editRoutePath,
        name: LeaseFormScreen.editRouteName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeaseFormScreen(
          unitId: state.uri.queryParameters['unit'] ?? '',
          leaseId: state.pathParameters['id'],
        ),
      ),

      // ── Rent request (EPIC-07 T-011) ────────────────────────────────────
      // The "Ask for rent" screen, launched from unit detail (active lease) and
      // the home late-payers list (T-014). The target lease is carried as a
      // `?lease=` query parameter (same convention as the `?unit=` flows), with
      // optional `?amount=`/`?period=` prefills. Sits on the root navigator so
      // it covers the landlord shell when pushed.
      GoRoute(
        path: RentRequestScreen.routePath,
        name: RentRequestScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return RentRequestScreen(
            leaseId: q['lease'] ?? '',
            initialAmount: double.tryParse(q['amount'] ?? ''),
            initialPeriod: q['period'],
          );
        },
      ),

      // ── Verify payment (EPIC-07 T-012) ──────────────────────────────────
      // The proof-review screen, launched from a rent-collection queue row at
      // `/rent/:id/verify`. The optional tenant name + submitted [PaymentProof]
      // ride along via `extra` (the rent detail endpoint does not yet surface
      // the proof); the screen verifies (→ receipt) or rejects with a reason.
      // Sits on the root navigator so it covers the landlord shell when pushed.
      GoRoute(
        path: VerifyPaymentScreen.routePath,
        name: VerifyPaymentScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is VerifyPaymentArgs ? extra : null;
          return VerifyPaymentScreen(
            requestId: state.pathParameters['id'] ?? '',
            tenantName: args?.tenantName,
            proof: args?.proof,
          );
        },
      ),

      // ── Receipt (EPIC-07 T-013) ─────────────────────────────────────────
      // The generated rent receipt, reached at `/rent/:id/receipt` after a
      // verify settles the request. The contextual receipt fields (tenant /
      // unit / method / receipt no / signed PDF url) ride along via `extra`
      // (the detail endpoint does not surface them yet); the screen shows the
      // receipt summary and shares/saves it. Sits on the root navigator so it
      // covers the landlord shell when pushed.
      GoRoute(
        path: ReceiptScreen.routePath,
        name: ReceiptScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is ReceiptArgs ? extra : null;
          return ReceiptScreen(
            requestId: state.pathParameters['id'] ?? '',
            args: args,
          );
        },
      ),

      // ── Lease list / detail (EPIC-06 T-010) ─────────────────────────────
      // The caller's leases (`/leases`) and a single lease's detail
      // (`/lease/:id`), reachable from More / portfolio. Both sit on the root
      // navigator so they cover the landlord shell when pushed. The detail
      // route is registered after the literal `/lease/new` and `/lease/:id/edit`
      // routes above so those are not captured by the `:id` parameter.
      GoRoute(
        path: LeaseListScreen.routePath,
        name: LeaseListScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LeaseListScreen(),
      ),
      GoRoute(
        path: LeaseDetailScreen.routePath,
        name: LeaseDetailScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeaseDetailScreen(
          leaseId: state.pathParameters['id'] ?? '',
        ),
      ),

      // ── AI lease document (EPIC-18 T-006/T-007/T-008) ──────────────────
      // The AI lease document screen (`/lease/:id/document`): generates and
      // displays the AI-generated DNCC-compliant draft with a disclaimer banner,
      // clause preview, and CTAs to review/edit clauses or view the PDF.
      // Sits on the root navigator so it covers the shell when pushed.
      GoRoute(
        path: LeaseDocumentScreen.pathFor(':id'),
        name: LeaseDocumentScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeaseDocumentScreen(
          leaseId: state.pathParameters['id'] ?? '',
        ),
      ),
      // Clause review/edit screen (`/lease/:id/clauses`, EPIC-18 T-007):
      // displays all AI-generated clauses as editable text fields; required
      // clauses show a lock icon and cannot be deleted. Pushes a PATCH on save.
      GoRoute(
        path: LeaseClauseScreen.pathFor(':id'),
        name: LeaseClauseScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeaseClauseScreen(
          leaseId: state.pathParameters['id'] ?? '',
        ),
      ),
      // Lease PDF preview + share (`/lease/:id/pdf`, EPIC-18 T-008): renders
      // the finalized lease PDF and offers Download + Share. Displays a
      // non-dismissible disclaimer banner. Reuses the DMP PDF screen pattern.
      GoRoute(
        path: LeasePdfScreen.pathFor(':id'),
        name: LeasePdfScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeasePdfScreen(
          leaseId: state.pathParameters['id'] ?? '',
        ),
      ),

      // ── Maintenance & expenses (EPIC-08 T-008) ──────────────────────────
      // The maintenance & expenses list (`/expenses`): the butter total hero, a
      // building filter, and the manual + maintenance-sourced expense rows. The
      // app-bar Add action pushes `/expenses/add` (EPIC-08 T-009) and Export
      // shares the scoped + filtered CSV. Sits on the root navigator so it
      // covers the landlord shell when pushed from home / portfolio / More.
      GoRoute(
        path: ExpensesScreen.routePath,
        name: ExpensesScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesScreen(),
      ),
      // The add-expense form (`/expenses/add`, EPIC-08 T-009): amount, category
      // chips, building→unit, date, optional note + receipt, Save. Pushed from
      // the expenses list Add action; saves and routes back to the list.
      GoRoute(
        path: AddExpenseScreen.routePath,
        name: AddExpenseScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddExpenseScreen(),
      ),
      // The landlord maintenance queue (`/maintenance`, EPIC-08 T-010): the open
      // maintenance requests, each with a Resolve + cost action that records the
      // cost (auto-creating one expense server-side) and flips the request to
      // resolved. Sits on the root navigator so it covers the landlord shell when
      // pushed from home / portfolio / More.
      GoRoute(
        path: MaintenanceQueueScreen.routePath,
        name: MaintenanceQueueScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaintenanceQueueScreen(),
      ),

      // ── NID verify screen (EPIC-17 T-006) ──────────────────────────────────
      // The NID EC-verification screen for a specific tenant, reached via the
      // unit-detail "Verify" CTA or a verification badge tap at
      // `/tenants/:id/verify`. Flag-gated and tier-gated inside the screen.
      // Sits on the root navigator so it covers the landlord shell when pushed.
      GoRoute(
        path: '/tenants/:id/verify',
        name: VerifyScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => VerifyScreen(
          tenantId: state.pathParameters['id'] ?? '',
        ),
      ),

      // ── Warnings (EPIC-20 T-005 / T-006) ────────────────────────────────
      // Issue-warning screen (`/lease/:id/warning`, T-005): type picker +
      // reason form + disclaimer; kill-switch (`warnings_feature`) is read at
      // call-site and passed as [warningsEnabled] so the route compiles cleanly
      // without a config dependency inside the router. The route sits on the
      // root navigator so it covers the landlord shell.
      GoRoute(
        path: WarningScreen.routePath,
        name: WarningScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WarningScreen(
          leaseId: state.pathParameters['id'] ?? '',
        ),
      ),
      // Warning notice PDF preview + share (`/warning/:warningId/notice`,
      // T-006): generates the server-side notice PDF and offers Download +
      // Share. Sits on the root navigator so it covers the shell.
      GoRoute(
        path: WarningNoticeScreen.routePath,
        name: WarningNoticeScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WarningNoticeScreen(
          warningId: state.pathParameters['warningId'] ?? '',
        ),
      ),

      // ── Properties / portfolio (T-012) ──────────────────────────────────
      // The portfolio list (buildings + unit counts + occupancy). Sits on the
      // root navigator so it covers the landlord shell when pushed from home.
      GoRoute(
        // Add-building wizard (T-010 steps 1–2; T-011 steps 3–4). Sits on the
        // root navigator so it covers the landlord shell when pushed from home
        // / portfolio.
        path: WizardHost.routePath,
        name: WizardHost.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WizardHost(),
      ),
      // ── Plan & billing (EPIC-10 T-007) ──────────────────────────────────
      // The plan screen (`/settings/plan`): current tier + tenant usage and the
      // active tier catalogue as upgrade cards, reading the plan slice of
      // `/config/public`. Pushed from the More menu's Plan & billing row; sits
      // on the root navigator so it covers the shell.
      GoRoute(
        path: PlanScreen.routePath,
        name: PlanScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlanScreen(),
      ),
      GoRoute(
        path: PortfolioScreen.routePath,
        name: PortfolioScreen.routeName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PortfolioScreen(),
        routes: [
          GoRoute(
            // Unit detail (T-013): rent/status/type/amenities + editable PATCH,
            // an add-tenant CTA, and a tenant/lease region (empty until
            // EPIC-06). Sits on the root navigator so it covers the shell.
            path: 'unit/:id',
            name: UnitDetailScreen.routeName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => UnitDetailScreen(
              unitId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
});
