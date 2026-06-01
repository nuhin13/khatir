import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/placeholder/presentation/screens/placeholder_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

/// ALL go_router routes live here. Role shells and feature routes are added in
/// later epics; the scaffold only wires splash → placeholder.
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
        path: PlaceholderScreen.routePath,
        name: PlaceholderScreen.routeName,
        builder: (context, state) => const PlaceholderScreen(),
      ),
    ],
  );
});
