import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/presentation/screens/otp_entry_placeholder_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/placeholder/presentation/screens/placeholder_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'args/auth_args.dart';

/// ALL go_router routes live here. Role shells and feature routes are added in
/// later epics; splash routing decisions land in T-012.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.routePath,
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
        // Real phone-entry screen (T-009), replacing the earlier placeholder.
        path: PhoneEntryScreen.routePath,
        name: PhoneEntryScreen.routeName,
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        // Placeholder OTP destination; T-010 builds the real screen. Reads the
        // typed AuthArgs passed via `extra` from phone-entry.
        path: OtpEntryPlaceholderScreen.routePath,
        name: OtpEntryPlaceholderScreen.routeName,
        builder: (context, state) =>
            OtpEntryPlaceholderScreen(args: state.extra as AuthArgs?),
      ),
      GoRoute(
        path: PlaceholderScreen.routePath,
        name: PlaceholderScreen.routeName,
        builder: (context, state) => const PlaceholderScreen(),
      ),
    ],
  );
});
