import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/presentation/screens/phone_entry_placeholder_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/placeholder/presentation/screens/placeholder_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

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
        // Placeholder destination for onboarding; T-009 builds the real screen.
        path: PhoneEntryPlaceholderScreen.routePath,
        name: PhoneEntryPlaceholderScreen.routeName,
        builder: (context, state) => const PhoneEntryPlaceholderScreen(),
      ),
      GoRoute(
        path: PlaceholderScreen.routePath,
        name: PlaceholderScreen.routeName,
        builder: (context, state) => const PlaceholderScreen(),
      ),
    ],
  );
});
